# test_levels.py
import argparse
import asyncio
import threading
import time
from collections import deque
from pathlib import Path

import cv2
import numpy as np

try:
    import mediapipe as mp
except ImportError:
    raise SystemExit(
        "[ERROR] mediapipe is required. Install with: pip install mediapipe"
    )

try:
    from bleak import BleakClient, BleakScanner
except ImportError:
    raise SystemExit(
        "[ERROR] bleak is required. Install with: pip install bleak"
    )


# ---------------------------------------------------------------------------
# BLE settings  (UNCHANGED)
# ---------------------------------------------------------------------------
BLE_DEVICE_NAME = "RiderShield-Helmet"
BLE_SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0"
BLE_CHAR_UUID    = "12345678-1234-5678-1234-56789abcdef1"

BLE_HEARTBEAT_SEC = 2.0

# ---------------------------------------------------------------------------
# Model / preprocessing constants  (UNCHANGED)
# ---------------------------------------------------------------------------
IMG_SIZE = 32
BRIGHTNESS_THR = 80
CONF_THRESH = 0.65
PERCLOS_WINDOW = 30
PERCLOS_THRESH = 0.35

OPEN_CLASS_INDEX = 0
CLOSED_CLASS_INDEX = 1

# ISSUE 5: reduced smoothing window for lower latency.
SMOOTH_WINDOW = 3

EYE_PAD_RATIO = 0.30

LEFT_EYE_IDX = [33, 133, 159, 145, 160, 144, 158, 153]
RIGHT_EYE_IDX = [362, 263, 386, 374, 385, 380, 387, 373]

LANDMARK_LOST_GRACE = 5

# ---------------------------------------------------------------------------
# EAR landmarks & threshold  (UNCHANGED)
# ---------------------------------------------------------------------------
LEFT_EAR_IDX  = [33, 160, 158, 133, 153, 144]
RIGHT_EAR_IDX = [362, 385, 387, 263, 373, 380]

EAR_CLOSED_THRESH = 0.20

# ---------------------------------------------------------------------------
# Timing constants
# ---------------------------------------------------------------------------
# ISSUE 4: reduced grace to only absorb single-frame noise (no blink merging).
OPEN_GRACE_SEC = 0.15

# ISSUE 3: short closures below this duration are treated as normal blinks.
BLINK_IGNORE_SEC = 0.5

# The 3-second BIG threshold is measured from the true start of closure.
BIG_THRESHOLD_SEC = 3.0

# ISSUE 2: reject frames older than this.
MAX_FRAME_AGE_SEC = 0.25

# ---------------------------------------------------------------------------
# Performance knobs  (UNCHANGED landmark interval)
# ---------------------------------------------------------------------------
LANDMARK_INTERVAL = 1
LANDMARK_INTERVAL_FAST = 3
EYE_PREVIEW_INTERVAL = 2


# ---------------------------------------------------------------------------
# ISSUE 1: Latest-frame reader
# ---------------------------------------------------------------------------
class LatestFrameReader:
    """
    Continuously reads frames from a cv2.VideoCapture in a background thread.
    Keeps ONLY the newest frame. Older frames are discarded automatically.

    The main inference loop calls read_latest() which returns a copy of the
    most recent frame along with the monotonic timestamp of when it was read.
    """

    def __init__(self, source):
        self.cap = cv2.VideoCapture(int(source) if isinstance(source, str) and source.isdecimal() else source)
        try:
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        except Exception:
            pass
        try:
            self.cap.set(cv2.CAP_PROP_FPS, 30)
        except Exception:
            pass

        if not self.cap.isOpened():
            self.cap.release()
            raise SystemExit("[ERROR] Cannot open camera/stream")

        self.lock = threading.Lock()
        self.latest_frame = None
        self.latest_timestamp = None
        self.running = True
        self._thread = threading.Thread(target=self._reader_loop, daemon=True)
        self._thread.start()

    def _reader_loop(self):
        while self.running:
            ret, frame = self.cap.read()
            if not ret:
                # Stream stopped; brief pause to avoid a tight spin.
                time.sleep(0.01)
                continue
            ts = time.monotonic()
            with self.lock:
                self.latest_frame = frame
                self.latest_timestamp = ts

    def read_latest(self):
        with self.lock:
            if self.latest_frame is None:
                return None, None
            return self.latest_frame.copy(), self.latest_timestamp

    def release(self):
        self.running = False
        try:
            self._thread.join(timeout=1.0)
        except Exception:
            pass
        try:
            self.cap.release()
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Eye Aspect Ratio helper  (UNCHANGED)
# ---------------------------------------------------------------------------
def eye_aspect_ratio(landmarks, indices, img_w, img_h):
    pts = [
        (landmarks[i].x * img_w, landmarks[i].y * img_h)
        for i in indices
    ]
    p1, p2, p3, p4, p5, p6 = pts

    def dist(a, b):
        return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5

    vertical_1 = dist(p2, p6)
    vertical_2 = dist(p3, p5)
    horizontal = dist(p1, p4)

    if horizontal < 1e-6:
        return 0.0
    return (vertical_1 + vertical_2) / (2.0 * horizontal)


# ---------------------------------------------------------------------------
# BLE client  (UNCHANGED)
# ---------------------------------------------------------------------------
from drowsiness_led_bridge import BleSender


# ---------------------------------------------------------------------------
# Preprocessing  (UNCHANGED)
# ---------------------------------------------------------------------------
def simple_enhance(gray_crop):
    mean_brightness = np.mean(gray_crop)
    if mean_brightness >= BRIGHTNESS_THR:
        return gray_crop
    min_val = np.min(gray_crop)
    max_val = np.max(gray_crop)
    if max_val == min_val:
        return gray_crop
    return (
        (gray_crop.astype(np.float32) - min_val)
        / (max_val - min_val) * 255
    ).astype(np.uint8)


def preprocess_esp32_style(eye_crop_gray, use_tflite=False):
    enhanced = simple_enhance(eye_crop_gray)
    resized = cv2.resize(
        enhanced, (IMG_SIZE, IMG_SIZE), interpolation=cv2.INTER_AREA
    )
    if use_tflite:
        inp = (resized.astype(np.int16) - 128).astype(np.int8)
    else:
        inp = resized.astype(np.float32) / 255.0
    return inp.reshape(1, IMG_SIZE, IMG_SIZE, 1)


# ---------------------------------------------------------------------------
# Predictors  (UNCHANGED)
# ---------------------------------------------------------------------------
class KerasPredictor:
    def __init__(self, path):
        import tensorflow as tf
        self.model = tf.keras.models.load_model(str(path), compile=False)
        try:
            dummy = np.zeros((1, IMG_SIZE, IMG_SIZE, 1), dtype=np.float32)
            self.model(dummy, training=False)
        except Exception:
            pass
        print(f"[INFO] Loaded Keras model: {path}", flush=True)

    def predict_batch(self, inp_batch):
        out = self.model(inp_batch, training=False).numpy()
        results = []
        for row in out:
            results.append((
                float(row[OPEN_CLASS_INDEX]),
                float(row[CLOSED_CLASS_INDEX]),
            ))
        return results


class TFLitePredictor:
    def __init__(self, path):
        from ai_edge_litert.interpreter import Interpreter
        self.interpreter = Interpreter(model_path=str(path))
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        out_quant = self.output_details[0]["quantization"]
        self.out_scale = out_quant[0]
        self.out_zero_pt = out_quant[1]
        print(f"[INFO] Loaded TFLite model: {path}", flush=True)

    def predict_batch(self, inp_batch):
        results = []
        for i in range(inp_batch.shape[0]):
            single = inp_batch[i:i + 1]
            self.interpreter.set_tensor(
                self.input_details[0]["index"], single
            )
            self.interpreter.invoke()
            out = self.interpreter.get_tensor(
                self.output_details[0]["index"]
            )[0]
            p_open = (float(out[OPEN_CLASS_INDEX]) - self.out_zero_pt) \
                * self.out_scale
            p_closed = (float(out[CLOSED_CLASS_INDEX]) - self.out_zero_pt) \
                * self.out_scale
            results.append((p_open, p_closed))
        return results


# ---------------------------------------------------------------------------
# PERCLOS  (UNCHANGED)
# ---------------------------------------------------------------------------
class PerclosCounter:
    def __init__(self, window=PERCLOS_WINDOW, thresh=PERCLOS_THRESH):
        self.buffer = deque([False] * window, maxlen=window)
        self.thresh = thresh

    def update(self, is_closed):
        self.buffer.append(is_closed)
        perclos = sum(self.buffer) / len(self.buffer)
        return perclos, perclos >= self.thresh


# ---------------------------------------------------------------------------
# Landmark locator  (UNCHANGED)
# ---------------------------------------------------------------------------
class EyeLandmarkLocator:
    MESH_WIDTH = 640
    MESH_HEIGHT = 480

    def __init__(self, max_faces=1, refine=True):
        self.mp_face_mesh = mp.solutions.face_mesh
        self.mesh = self.mp_face_mesh.FaceMesh(
            max_num_faces=max_faces,
            refine_landmarks=refine,
            min_detection_confidence=0.35,
            min_tracking_confidence=0.45,
        )
        self.last_boxes = None
        self.last_ears = None
        self.last_contours = None
        self.contours = None
        self.lost_frames = 0
        self.clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))

    @staticmethod
    def _box_from_indices(landmarks, indices, img_w, img_h, pad_ratio):
        xs = [landmarks[i].x * img_w for i in indices]
        ys = [landmarks[i].y * img_h for i in indices]
        x1, x2 = min(xs), max(xs)
        y1, y2 = min(ys), max(ys)

        bw, bh = x2 - x1, y2 - y1
        pad_x = bw * pad_ratio
        pad_y = bh * pad_ratio

        x1 = max(0.0, x1 - pad_x)
        y1 = max(0.0, y1 - pad_y)
        x2 = min(float(img_w), x2 + pad_x)
        y2 = min(float(img_h), y2 + pad_y)

        return (x1 / img_w, y1 / img_h,
                (x2 - x1) / img_w, (y2 - y1) / img_h)

    def locate(self, bgr_frame):
        img_h, img_w = bgr_frame.shape[:2]

        small = cv2.resize(
            bgr_frame, (self.MESH_WIDTH, self.MESH_HEIGHT),
            interpolation=cv2.INTER_AREA
        )
        # Try the original frame first to preserve natural contrast.
        rgb = cv2.cvtColor(small, cv2.COLOR_BGR2RGB)
        result = self.mesh.process(rgb)
        if not result.multi_face_landmarks:
            # Helmet shadows / IR lighting: retry with local contrast enhancement.
            gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
            enhanced = self.clahe.apply(gray)
            enhanced_rgb = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2RGB)
            result = self.mesh.process(enhanced_rgb)

        if not result.multi_face_landmarks:
            self.lost_frames += 1
            if (self.last_boxes is not None
                    and self.lost_frames <= LANDMARK_LOST_GRACE):
                self.contours = None  # Do not draw old landmarks as current detections.
                return self.last_boxes, self.last_ears
            self.last_boxes = None
            self.last_ears = None
            self.contours = None
            return None, (None, None)

        self.lost_frames = 0
        lm = result.multi_face_landmarks[0].landmark
        # True eyelid contours; visual only, independent of classification.
        left_outline = [33, 160, 158, 133, 153, 144]
        right_outline = [362, 385, 387, 263, 373, 380]
        self.contours = [np.array([(int(lm[i].x * img_w), int(lm[i].y * img_h))
                                   for i in outline], dtype=np.int32)
                         for outline in (left_outline, right_outline)]

        right_box = self._box_from_indices(
            lm, RIGHT_EYE_IDX, img_w, img_h, EYE_PAD_RATIO
        )
        left_box = self._box_from_indices(
            lm, LEFT_EYE_IDX, img_w, img_h, EYE_PAD_RATIO
        )

        right_ear = eye_aspect_ratio(lm, RIGHT_EAR_IDX, img_w, img_h)
        left_ear = eye_aspect_ratio(lm, LEFT_EAR_IDX, img_w, img_h)

        boxes = [right_box, left_box]
        ears = (right_ear, left_ear)

        self.last_boxes = boxes
        self.last_ears = ears
        return boxes, ears

    def close(self):
        try:
            self.mesh.close()
        except Exception:
            pass


def box_to_pixels(box, frame_shape):
    x, y, w, h = box
    height, width = frame_shape[:2]
    x1 = max(0, min(width, int(x * width)))
    y1 = max(0, min(height, int(y * height)))
    x2 = max(0, min(width, int((x + w) * width)))
    y2 = max(0, min(height, int((y + h) * height)))
    return x1, y1, x2, y2


class EyeStateSmoother:
    def __init__(self, window=SMOOTH_WINDOW):
        self.buffer = deque(maxlen=window)

    def update(self, closed_bool):
        self.buffer.append(closed_bool)
        return sum(self.buffer) > (len(self.buffer) / 2)


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
def run(model_path, tflite_path, source, fast=False):
    use_tflite = tflite_path is not None

    predictor = (
        TFLitePredictor(tflite_path)
        if use_tflite
        else KerasPredictor(model_path)
    )

    locator = EyeLandmarkLocator(refine=True)

    # ISSUE 1: latest-frame reader replaces flush_camera_buffer().
    reader = LatestFrameReader(source)

    landmark_interval = (
        LANDMARK_INTERVAL_FAST if fast else LANDMARK_INTERVAL
    )

    perclos = PerclosCounter()
    smoothers = [EyeStateSmoother(), EyeStateSmoother()]

    # Closure timer state.
    closed_start_time = None
    last_closed_time = None

    fps_time = time.monotonic()
    frame_count = 0
    fps = 0.0

    landmark_ms = 0.0
    inference_ms = 0.0
    total_ms = 0.0

    frame_idx = 0
    cached_boxes = None
    cached_boxes_frame = -999
    cached_ears = (None, None)

    ble = BleSender(BLE_DEVICE_NAME, BLE_CHAR_UUID)
    last_led_level = None

    print('[LED] Drowsiness sends to YOLO local LED manager (start YOLO first).', flush=True)

    print("[INFO] Q: quit | S: screenshot", flush=True)
    print(f"[INFO] Landmark interval: every {landmark_interval} frames",
          flush=True)

    try:
        while True:
            t_frame_start = time.monotonic()

            # ISSUE 1: always grab the newest frame.
            frame, frame_ts = reader.read_latest()
            if frame is None:
                time.sleep(0.005)
                continue

            # ISSUE 2: reject stale frames so they cannot extend timers.
            frame_age = time.monotonic() - frame_ts
            if frame_age > MAX_FRAME_AGE_SEC:
                print(f"[STREAM] Dropping stale frame: "
                      f"{frame_age:.2f} sec old", flush=True)
                continue
            if frame_age > 0.15:
                # Optional verbose log for near-stale frames.
                print(f"[STREAM] Frame age: {frame_age:.3f} sec",
                      flush=True)

            if frame.shape[1] != 640 or frame.shape[0] != 480:
                frame = cv2.resize(frame, (640, 480))

            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            height, width = frame.shape[:2]

            frame_idx += 1

            # ---------- MediaPipe (throttled) ----------
            if (frame_idx - cached_boxes_frame) >= landmark_interval \
                    or cached_boxes is None:
                t_lm = time.monotonic()
                boxes, ears = locator.locate(frame)
                landmark_ms = (time.monotonic() - t_lm) * 1000.0
                cached_boxes = boxes
                cached_ears = ears
                cached_boxes_frame = frame_idx
            else:
                boxes = cached_boxes
                ears = cached_ears

            eye_boxes = boxes
            right_ear, left_ear = ears
            if locator.contours is not None:
                for contour in locator.contours:
                    cv2.polylines(frame, [contour], True, (0, 220, 0), 2,
                                  lineType=cv2.LINE_AA)

            label_str = "No face"
            valid_prediction = False
            is_frame_closed = False
            closed_duration = 0.0
            level = "SMALL"
            eye_previews = []

            # ---------- Batch inference ----------
            if eye_boxes is not None:
                crops = []
                crop_boxes = []
                for box in eye_boxes:
                    x1, y1, x2, y2 = box_to_pixels(box, frame.shape)
                    crop = gray[y1:y2, x1:x2]
                    if crop.size == 0:
                        continue
                    crops.append(crop)
                    crop_boxes.append((x1, y1, x2, y2))

                if len(crops) == 2:
                    batch = np.concatenate(
                        [preprocess_esp32_style(c, use_tflite)
                         for c in crops],
                        axis=0
                    )

                    t_inf = time.monotonic()
                    preds = predictor.predict_batch(batch)
                    inference_ms = (time.monotonic() - t_inf) * 1000.0

                    closed_states = []
                    confidence_states = []

                    ear_by_index = [right_ear, left_ear]
                    name_by_index = ["RIGHT", "LEFT"]

                    for index, ((p_open, p_closed), (x1, y1, x2, y2)) \
                            in enumerate(zip(preds, crop_boxes)):
                        confidence = max(p_open, p_closed)
                        confident = confidence >= CONF_THRESH

                        model_closed = (p_closed > p_open and confident)
                        ear_val = ear_by_index[index]
                        ear_closed = (
                            ear_val is not None
                            and ear_val < EAR_CLOSED_THRESH
                        )

                        # EAR alone is unreliable for downward gaze and squinting.
                        # Use the trained classifier as the primary decision.
                        raw_closed = model_closed
                        is_closed = smoothers[index].update(raw_closed)

                        closed_states.append(is_closed)
                        confidence_states.append(confident)

                        ear_str = f"{ear_val:.3f}" if ear_val is not None \
                            else "N/A"
                        print(
                            f"[{name_by_index[index]}] "
                            f"Open={p_open:.2f} Closed={p_closed:.2f} "
                            f"EAR={ear_str} "
                            f"ModelClosed={model_closed} "
                            f"EARClosed={ear_closed} "
                            f"FinalClosed={is_closed}",
                            flush=True,
                        )

                        if not confident:
                            color = (0, 255, 255)
                            state = "Uncertain"
                        elif is_closed:
                            color = (0, 0, 220)
                            state = "Closed"
                        else:
                            color = (0, 220, 0)
                            state = "Open"

                        cv2.rectangle(
                            frame, (x1, y1), (x2, y2), color, 2
                        )
                        cv2.putText(
                            frame,
                            f"{state} {confidence:.0%}",
                            (x1, max(18, y1 - 8)),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.5, color, 1
                        )

                        if frame_idx % EYE_PREVIEW_INTERVAL == 0:
                            crop = crops[index]
                            preview = cv2.resize(crop, (160, 80))
                            preview = cv2.cvtColor(
                                preview, cv2.COLOR_GRAY2BGR
                            )
                            cv2.putText(
                                preview,
                                f"O:{p_open:.2f} C:{p_closed:.2f}",
                                (3, 15),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.4, color, 1
                            )
                            eye_previews.append(preview)

                    valid_prediction = (
                        len(closed_states) == 2
                        and all(confidence_states)
                    )

                    if valid_prediction:
                        is_frame_closed = any(closed_states)
                        label_str = (
                            "CLOSED" if is_frame_closed else "OPEN"
                        )
                    else:
                        label_str = "UNCERTAIN"

            # Missing landmarks are not evidence that the eyes are open.
            if eye_boxes is None:
                label_str = "UNKNOWN - FACE NOT TRACKED"
            elif not valid_prediction:
                label_str = "UNKNOWN - EYE CLASSIFICATION"

            # ---------- PERCLOS (UNCHANGED) ----------
            # Do not insert fake 'open' frames when tracking is lost.
            if valid_prediction:
                perclos_val, _ = perclos.update(is_frame_closed)
            else:
                perclos_val = sum(perclos.buffer) / len(perclos.buffer)

            # ------------------------------------------------------------------
            # ISSUE 3 + ISSUE 4: blink filter + short noise grace.
            #
            # - While CLOSED: keep timer running from the true start of closure.
            # - Short OPEN/UNCERTAIN blips (<= OPEN_GRACE_SEC): keep timer.
            # - Longer OPEN: reset timer.
            # - Once total closure duration >= BLINK_IGNORE_SEC, escalate:
            #       0.5 - 3.0 s   -> MEDIUM
            #       > 3.0 s       -> BIG
            # - Below BLINK_IGNORE_SEC: still SMALL (treated as blink).
            # ------------------------------------------------------------------
            if valid_prediction and is_frame_closed:
                now = time.monotonic()
                last_closed_time = now
                if closed_start_time is None:
                    closed_start_time = now
                closed_duration = now - closed_start_time

                if closed_duration < BLINK_IGNORE_SEC:
                    level = "SMALL"
                elif closed_duration <= BIG_THRESHOLD_SEC:
                    level = "MEDIUM"
                else:
                    level = "BIG"
            else:
                now = time.monotonic()
                if (
                    last_closed_time is not None
                    and (now - last_closed_time) <= OPEN_GRACE_SEC
                    and closed_start_time is not None
                ):
                    closed_duration = now - closed_start_time
                    if closed_duration < BLINK_IGNORE_SEC:
                        level = "SMALL"
                    elif closed_duration <= BIG_THRESHOLD_SEC:
                        level = "MEDIUM"
                    else:
                        level = "BIG"
                else:
                    closed_start_time = None
                    last_closed_time = None
                    closed_duration = 0.0
                    level = "SMALL"

            # Debug: continuous-closure timer
            print(f"[TIMER] Closed Time: {closed_duration:.1f}  |  "
                  f"Level: {level}", flush=True)

            # Existing BLE receiver supports SMALL/MEDIUM/BIG only.
            # UNKNOWN must not be silently mapped to SMALL (safe).
            # Retain the last transmitted warning until valid tracking resumes.
            # Do not mark lost tracking as SAFE; keep local manager informed.
            led_level = level if valid_prediction else 'UNKNOWN'
            if led_level != last_led_level:
                ble.set_level(led_level)
                last_led_level = led_level

            if level == "BIG":
                cv2.rectangle(
                    frame, (0, 0), (width, 45), (0, 0, 180), -1
                )
                cv2.putText(
                    frame,
                    "BIG DROWSINESS - WAKE UP!",
                    (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.8, (255, 255, 255), 2
                )

            if not valid_prediction:
                cv2.putText(frame, label_str, (10, 70),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 165, 255), 2)

            # ---------- FPS ----------
            frame_count += 1
            elapsed = time.monotonic() - fps_time
            if elapsed >= 1.0:
                fps = frame_count / elapsed
                fps_time = time.monotonic()
                frame_count = 0

            total_ms = (time.monotonic() - t_frame_start) * 1000.0

            # Show the camera without the black HUD panel.
            display = frame.copy()
            # Enlarge the preview only; inference still uses the original frame.
            display = cv2.resize(
                display, None, fx=1.5, fy=1.5,
                interpolation=cv2.INTER_LINEAR
            )
            cv2.imshow("Drowsiness Levels Test", display)

            if len(eye_previews) == 2:
                cv2.imshow("Eye crops", np.hstack(eye_previews))

            key = cv2.waitKey(1) & 0xFF

            if key == ord("q"):
                break

            if key == ord("s"):
                filename = f"screenshot_{int(time.time())}.png"
                cv2.imwrite(filename, display)
                print(f"[INFO] Saved {filename}", flush=True)

    finally:
        ble.stop()
        reader.release()
        locator.close()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--model",
        default=str(
            Path(__file__).resolve().parent
            / "models"
            / "best_model_m1.keras"
        )
    )
    parser.add_argument("--tflite", default=None)
    parser.add_argument(
        "--source",
        default="tcp://[::1]:8888"
    )
    parser.add_argument(
        "--fast",
        action="store_true",
        help="Run MediaPipe less often for higher FPS at some accuracy cost."
    )

    args = parser.parse_args()
    selected_path = Path(args.tflite or args.model)

    if not selected_path.is_file():
        raise SystemExit(f"[ERROR] File not found: {selected_path}")

    run(args.model, args.tflite, args.source, fast=args.fast)