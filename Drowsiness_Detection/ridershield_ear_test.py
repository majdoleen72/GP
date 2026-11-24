"""RiderShield EAR-only evaluation. Requires test_levels_laptop.py and drowsiness_led_bridge.py nearby.
Calibration: press O with eyes open; C with eyes closed; R resets; Q quits.
Experimental only; never use as a validated rider safety device.
"""
import argparse
import time
from collections import deque
import cv2
import numpy as np
from test_levels import LatestFrameReader, EyeLandmarkLocator, box_to_pixels
from drowsiness_led_bridge import BleSender

OPEN_GRACE_SEC = 0.15
BLINK_IGNORE_SEC = 0.5
BIG_THRESHOLD_SEC = 3.0
MAX_FRAME_AGE_SEC = 0.25


def main(source):
    reader = LatestFrameReader(int(source) if source.isdecimal() else source)
    locator = EyeLandmarkLocator(refine=True)
    ble = BleSender('RiderShield-Helmet', '12345678-1234-5678-1234-56789abcdef1')
    # Calibrate both eyes separately. Values must be distinct to be useful.
    samples = {'open': None, 'closed': None}
    histories = [deque(maxlen=3), deque(maxlen=3)]
    closed_since = None
    last_closed = None
    last_sent = None
    try:
        while True:
            frame, ts = reader.read_latest()
            if frame is None or time.monotonic() - ts > MAX_FRAME_AGE_SEC:
                time.sleep(0.005)
                continue
            frame = cv2.resize(frame, (640, 480))
            boxes, ears = locator.locate(frame)
            now = time.monotonic()
            values = np.array(ears, dtype=float) if ears is not None and all(v is not None for v in ears) else None
            if locator.contours is not None and boxes is not None:
                for contour in locator.contours:
                    cv2.polylines(frame, [contour], True, (0, 220, 0), 2, cv2.LINE_AA)
            calibrated = samples['open'] is not None and samples['closed'] is not None
            valid = False
            closed = False
            label = 'UNCALIBRATED: press O (open), then C (closed)'
            if calibrated:
                op, cl = samples['open'], samples['closed']
                if np.all(op - cl >= 0.035):
                    if values is not None and np.all(np.isfinite(values)) and np.all((values > 0.01) & (values < 0.65)):
                        thresholds = (op + cl) / 2
                        states = values < thresholds
                        for i in range(2):
                            histories[i].append(bool(states[i]))
                        if all(len(h) == 3 for h in histories):
                            closed = any(sum(h) >= 2 for h in histories)
                            valid = True
                            label = 'CLOSED' if closed else 'OPEN'
                    if not valid:
                        label = 'UNKNOWN - TRACKING'
                else:
                    label = 'BAD CALIBRATION - press R and retry'
            if boxes is not None:
                for i, box in enumerate(boxes):
                    x1, y1, x2, y2 = box_to_pixels(box, frame.shape)
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 255), 2)
                    v = values[i] if values is not None else float('nan')
                    cv2.putText(frame, f'EAR {v:.3f}', (x1, max(20, y1-8)), cv2.FONT_HERSHEY_SIMPLEX, .5, (0,255,255), 1)
            if valid and closed:
                last_closed = now
                if closed_since is None:
                    closed_since = now
            elif valid and not closed:
                if last_closed is None or now-last_closed > OPEN_GRACE_SEC:
                    closed_since = None
                    last_closed = None
            # Unknown tracking cannot establish a new closure or a safe state.
            duration = now-closed_since if closed_since is not None and last_closed is not None and now-last_closed <= OPEN_GRACE_SEC else 0.0
            level = 'SMALL' if duration < BLINK_IGNORE_SEC else ('MEDIUM' if duration <= BIG_THRESHOLD_SEC else 'BIG')
            outgoing = level if valid else 'UNKNOWN'
            if outgoing != last_sent:
                ble.set_level(outgoing)
                last_sent = outgoing
            if level == 'BIG' and valid:
                cv2.putText(frame, 'DROWSINESS ALERT', (10, 40), cv2.FONT_HERSHEY_SIMPLEX, .9, (0,0,255), 2)
            cv2.putText(frame, label, (10, 75), cv2.FONT_HERSHEY_SIMPLEX, .65, (0, 165, 255), 2)
            cv2.putText(frame, f'Time: {duration:.1f}s  LED: {outgoing}', (10, 105), cv2.FONT_HERSHEY_SIMPLEX, .6, (255,255,255), 2)
            cv2.putText(frame, 'O: open  C: closed  R: reset  Q: quit', (10, 465), cv2.FONT_HERSHEY_SIMPLEX, .5, (255,255,255), 1)
            cv2.imshow('RiderShield EAR-only test', frame)
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            if key == ord('r'):
                samples = {'open': None, 'closed': None}
                for h in histories: h.clear()
                closed_since = last_closed = None
                print('[CALIBRATION] Reset')
            if key in (ord('o'), ord('c')):
                if values is None or not np.all(np.isfinite(values)):
                    print('[CALIBRATION] Eyes not tracked; retry')
                else:
                    samples['open' if key == ord('o') else 'closed'] = values.copy()
                    print('[CALIBRATION]', 'OPEN' if key == ord('o') else 'CLOSED', values)
                    for h in histories: h.clear()
                    closed_since = last_closed = None
    finally:
        ble.set_level('UNKNOWN')
        ble.stop()
        reader.release()
        locator.close()
        cv2.destroyAllWindows()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', default='0')
    args = parser.parse_args()
    main(args.source)
