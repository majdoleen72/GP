"""Experimental RiderShield EAR + iris + Keras model hybrid with persisted per-camera profile.
Requires: opencv-python, mediapipe, numpy, and existing drowsiness_led_bridge.py.
Not validated for real riding or safety-critical use.
"""
import argparse
import json
from pathlib import Path
import time
from collections import deque
import cv2
import numpy as np
import mediapipe as mp

class KerasEyeModel:
    def __init__(self, path):
        import tensorflow as tf
        self.model = tf.keras.models.load_model(str(path), compile=False)
        self.model_path = path

    def predict(self, frame, readings):
        gray=cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        crops=[]
        for _,_,points in readings:
            x,y,w,h=cv2.boundingRect(points)
            px=int(w*.30);py=int(h*.30)
            x1=max(0,x-px);y1=max(0,y-py)
            x2=min(gray.shape[1],x+w+px);y2=min(gray.shape[0],y+h+py)
            crop=gray[y1:y2,x1:x2]
            if crop.size==0:return None
            # Match the existing model pipeline: grayscale 32x32, normalize 0..1.
            if np.mean(crop)<80 and np.ptp(crop)>0:
                crop=((crop.astype(np.float32)-crop.min())/(crop.max()-crop.min())*255).astype(np.uint8)
            crop=cv2.resize(crop,(32,32),interpolation=cv2.INTER_AREA)
            crops.append(crop.astype(np.float32)/255.0)
        batch=np.asarray(crops,dtype=np.float32)[...,None]
        out=np.asarray(self.model(batch,training=False)).reshape(2,-1)
        if out.shape[1]!=2:return None
        return out


# MediaPipe Face Mesh eye contours, EAR points, and refined iris points.
EYES = [
    dict(name='RIGHT', outline=[362,385,387,263,373,380], ear=[362,385,387,263,373,380], iris=list(range(473,478))),
    dict(name='LEFT', outline=[33,160,158,133,153,144], ear=[33,160,158,133,153,144], iris=list(range(468,473))),
]
BLINK_IGNORE_SEC = 0.5
BIG_THRESHOLD_SEC = 3.0
OPEN_GRACE_SEC = 0.15

def dist(a,b):
    return float(np.linalg.norm(a-b))

def measure(lm, w, h):
    out=[]
    for eye in EYES:
        p=np.array([[lm[i].x*w,lm[i].y*h] for i in eye['ear']],dtype=float)
        width=dist(p[0],p[3])
        ear=(dist(p[1],p[5])+dist(p[2],p[4]))/(2*width) if width>1 else np.nan
        iris=np.array([[lm[i].x*w,lm[i].y*h] for i in eye['iris']],dtype=float)
        # Iris vertical position relative to outer eye corners. Downward gaze increases y.
        iris_y=float(np.mean(iris[:,1]))
        mid_y=float((p[0,1]+p[3,1])/2)
        gaze=(iris_y-mid_y)/width if width>1 else np.nan
        out.append((ear,gaze,np.round(p).astype(np.int32)))
    return out

def main(source, no_ble, calibration_path, model_path, fusion):
    cap=cv2.VideoCapture(int(source) if source.isdecimal() else source)
    if not cap.isOpened():
        raise SystemExit('Cannot open camera. Try --source 1')
    cap.set(cv2.CAP_PROP_BUFFERSIZE,1)
    ble=None
    if not no_ble:
        from drowsiness_led_bridge import BleSender
        ble=BleSender('RiderShield-Helmet','12345678-1234-5678-1234-56789abcdef1')
    eye_model=None
    if model_path:
        path=Path(model_path)
        if not path.is_file():
            raise SystemExit(f"[MODEL] Not found: {path}. Use --model PATH or --no-model")
        eye_model=KerasEyeModel(path)
        print(f"[MODEL] Loaded {path}; class 0=OPEN, class 1=CLOSED")
    samples={k:[] for k in ('open','down','closed')}
    calibration_file=Path(calibration_path).expanduser().resolve()
    if calibration_file.is_file():
        try:
            data=json.loads(calibration_file.read_text(encoding='utf-8'))
            if data.get('version') != 1:
                raise ValueError('unsupported calibration version')
            for k in samples:
                arr=np.asarray(data['samples'][k],dtype=float)
                if arr.ndim!=3 or arr.shape[1:]!=(2,2) or len(arr)<5 or not np.all(np.isfinite(arr)):
                    raise ValueError(f'invalid {k} calibration')
                samples[k]=[v.copy() for v in arr]
            print(f'[CAL] Loaded {calibration_file}',flush=True)
        except (OSError,ValueError,KeyError,TypeError) as exc:
            print(f'[CAL] Cannot load calibration: {exc}. Calibrate O/D/C again.',flush=True)
            samples={k:[] for k in ('open','down','closed')}
    history=deque(maxlen=3)
    closed_since=None
    last_closed=None
    last_sent=None
    model_scores=None
    last_frame_ts=0.0
    mesh=mp.solutions.face_mesh.FaceMesh(max_num_faces=1,refine_landmarks=True,
                                         min_detection_confidence=.5,min_tracking_confidence=.5)
    try:
        while True:
            ok,frame=cap.read()
            if not ok:
                time.sleep(.02)
                continue
            frame=cv2.resize(frame,(640,480))
            frame_time=time.monotonic()
            if frame_time-last_frame_ts<0.005: continue
            last_frame_ts=frame_time
            rgb=cv2.cvtColor(frame,cv2.COLOR_BGR2RGB)
            result=mesh.process(rgb)
            values=None
            readings=None
            if result.multi_face_landmarks:
                readings=measure(result.multi_face_landmarks[0].landmark,640,480)
                if all(np.isfinite(x) and np.isfinite(g) and .01<x<.65 for x,g,_ in readings):
                    values=np.array([[x,g] for x,g,_ in readings])
                    for i,(_,_,contour) in enumerate(readings):
                        cv2.polylines(frame,[contour],True,(0,220,0),2,cv2.LINE_AA)
                        x,y,w,h=cv2.boundingRect(contour)
                        cv2.rectangle(frame,(max(0,x-12),max(0,y-12)),(min(639,x+w+12),min(479,y+h+12)),(0,255,255),1)
                        cv2.putText(frame,f'{EYES[i]["name"]} EAR:{values[i,0]:.3f} G:{values[i,1]:+.3f}',
                                    (max(0,x-30),max(20,y-17)),cv2.FONT_HERSHEY_SIMPLEX,.43,(255,255,255),1)
            model_scores=None
            if eye_model is not None and readings is not None and values is not None:
                try:
                    model_scores=eye_model.predict(frame,readings)
                except Exception as exc:
                    print(f"[MODEL] Prediction failed: {exc}",flush=True)
            ready=all(len(samples[k])>=5 for k in samples)
            state='UNCALIBRATED: O=open D=look down C=closed'
            if ready and values is not None:
                op=np.median(np.stack(samples['open']),axis=0)
                dn=np.median(np.stack(samples['down']),axis=0)
                cl=np.median(np.stack(samples['closed']),axis=0)
                # Closed EAR must be sufficiently below BOTH open-gaze reference values.
                min_open=np.minimum(op[:,0],dn[:,0])
                separation=min_open-cl[:,0]
                if np.any(separation<.025):
                    state='CALIBRATION OVERLAP - cannot distinguish; R to retry'
                else:
                    # The closed decision uses a conservative per-eye EAR threshold.
                    closed_thr=cl[:,0]+.35*separation
                    open_thr=cl[:,0]+.70*separation
                    ear=values[:,0]
                    # Gaze helps label downward-open readings, but is not used as
                    # proof of open eyes (iris detection can fail when lids close).
                    if np.all(ear<closed_thr):
                        raw='CLOSED'
                    elif np.all(ear>open_thr):
                        raw='OPEN'
                    else:
                        raw='UNCERTAIN'
                    # Conservative fusion: the trained model can resolve only EAR ambiguity
                    # when BOTH eyes agree with >= 0.85 confidence. Never override a
                    # clear EAR CLOSED or OPEN result based on a model previously shown
                    # to make false OPEN predictions.
                    if fusion and raw=='UNCERTAIN' and model_scores is not None:
                        if np.all(model_scores[:,1]>=0.85):
                            raw='CLOSED'
                        elif np.all(model_scores[:,0]>=0.85):
                            # Do not treat model OPEN as proof of openness when EAR is ambiguous.
                            raw='UNCERTAIN'
                    if raw=='OPEN':
                        down_gaze=np.all(np.abs(values[:,1]-dn[:,1]) < np.abs(values[:,1]-op[:,1]))
                        state='OPEN - LOOKING DOWN' if down_gaze else 'OPEN'
                    else:
                        state=raw
                    history.append(raw)
                    if len(history)==3 and history.count('CLOSED')>=2:
                        state='CLOSED'
                    elif raw=='CLOSED':
                        state='UNCERTAIN - VERIFYING CLOSURE'
            elif ready:
                state='UNKNOWN - NO RELIABLE LANDMARKS'
            now=time.monotonic()
            if state=='CLOSED':
                last_closed=now
                if closed_since is None: closed_since=now
            elif state.startswith('OPEN'):
                if last_closed is None or now-last_closed>OPEN_GRACE_SEC:
                    closed_since=None
                    last_closed=None
            else:
                # Ambiguous frames must not create new closure evidence or reset
                # a previous warning as though the eyes were definitely open.
                if last_closed is not None and now-last_closed>OPEN_GRACE_SEC:
                    closed_since=None
                    last_closed=None
            duration=(now-closed_since) if (closed_since is not None and last_closed is not None and now-last_closed<=OPEN_GRACE_SEC) else 0.
            level='SMALL' if duration<BLINK_IGNORE_SEC else ('MEDIUM' if duration<=BIG_THRESHOLD_SEC else 'BIG')
            # Do not claim SAFE during uncertainty; existing LED manager handles UNKNOWN.
            outgoing=level if state=='CLOSED' or state.startswith('OPEN') else 'UNKNOWN'
            if ble and outgoing!=last_sent:
                ble.set_level(outgoing)
                last_sent=outgoing
            if level=='BIG' and state=='CLOSED':
                cv2.putText(frame,'DROWSINESS ALERT!',(10,35),cv2.FONT_HERSHEY_SIMPLEX,.85,(0,0,255),2)
            if model_scores is not None:
                cv2.putText(frame, f'Model C R:{model_scores[0,1]:.2f} L:{model_scores[1,1]:.2f} | Fusion:{fusion}',
                            (10,130),cv2.FONT_HERSHEY_SIMPLEX,.48,(255,255,0),1)
                if state.startswith('OPEN') and np.all(model_scores[:,1]>.85):
                    cv2.putText(frame,'MODEL DISAGREES WITH EAR OPEN',(10,155),cv2.FONT_HERSHEY_SIMPLEX,.46,(0,165,255),1)
                if state=='CLOSED' and np.all(model_scores[:,0]>.85):
                    cv2.putText(frame,'MODEL DISAGREES WITH EAR CLOSED',(10,155),cv2.FONT_HERSHEY_SIMPLEX,.46,(0,165,255),1)
            cv2.putText(frame,state,(10,70),cv2.FONT_HERSHEY_SIMPLEX,.53,(0,165,255),2)
            cv2.putText(frame,f'Closed: {duration:.1f}s | LED: {outgoing}',(10,100),cv2.FONT_HERSHEY_SIMPLEX,.55,(255,255,255),2)
            cv2.putText(frame,'O open | D eyes down/head still | C closed | R reset | Q quit',
                        (8,465),cv2.FONT_HERSHEY_SIMPLEX,.45,(255,255,255),1)
            cv2.imshow('RiderShield EAR + Gaze evaluation',frame)
            key=cv2.waitKey(1)&0xff
            if key==ord('q'):break
            if key==ord('r'):
                samples={k:[] for k in samples}
                history.clear();closed_since=last_closed=None
                print('[CAL] reset (saved calibration kept until new O/D/C complete)')
            if key in (ord('o'),ord('d'),ord('c')):
                name={ord('o'):'open',ord('d'):'down',ord('c'):'closed'}[key]
                if values is None:
                    print('[CAL] No eye landmarks; retry')
                else:
                    # Collect 10 frames after keypress to avoid one-frame calibration noise.
                    samples[name]=[values.copy()]
                    for _ in range(9):
                        ok,f=cap.read()
                        if not ok:continue
                        f=cv2.resize(f,(640,480))
                        res=mesh.process(cv2.cvtColor(f,cv2.COLOR_BGR2RGB))
                        if res.multi_face_landmarks:
                            v=np.array([[e,g] for e,g,_ in measure(res.multi_face_landmarks[0].landmark,640,480)])
                            if np.all(np.isfinite(v)) and np.all((v[:,0]>.01)&(v[:,0]<.65)):
                                samples[name].append(v)
                    print(f'[CAL] {name}: {len(samples[name])} samples',flush=True)
                    if all(len(samples[k])>=5 for k in samples):
                        op=np.median(np.stack(samples['open']),axis=0)
                        dn=np.median(np.stack(samples['down']),axis=0)
                        cl=np.median(np.stack(samples['closed']),axis=0)
                        if np.any(np.minimum(op[:,0],dn[:,0])-cl[:,0]<.025):
                            print('[CAL] Open/down and closed overlap; NOT saved. Recalibrate.',flush=True)
                        else:
                            try:
                                calibration_file.parent.mkdir(parents=True,exist_ok=True)
                                payload={'version':1,'samples':{k:[v.tolist() for v in samples[k]] for k in samples}}
                                temp=calibration_file.with_suffix(calibration_file.suffix+'.tmp')
                                temp.write_text(json.dumps(payload,indent=2),encoding='utf-8')
                                temp.replace(calibration_file)
                                print(f'[CAL] Saved {calibration_file}',flush=True)
                            except OSError as exc:
                                print(f'[CAL] Save failed: {exc}',flush=True)
                    history.clear();closed_since=last_closed=None
    finally:
        if ble:
            ble.set_level('UNKNOWN')
            ble.stop()
        mesh.close();cap.release();cv2.destroyAllWindows()

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--model',default=str(Path(__file__).with_name('models')/'best_model_m1.keras'),help='Existing trained Keras eye model')
    parser.add_argument('--no-model',action='store_true',help='EAR + iris baseline only')
    parser.add_argument('--fusion',action='store_true',help='Allow strong CLOSED model evidence to resolve uncertain EAR frames')
    parser.add_argument('--source',default='tcp://[::1]:8888',help='TCP camera stream URL (original default); use 0 for laptop webcam')
    parser.add_argument('--no-ble',action='store_true',help='Webcam-only test; no UDP LED traffic')
    parser.add_argument('--calibration',default=str(Path(__file__).with_name('ridershield_eye_calibration.json')),help='Calibration JSON path')
    args=parser.parse_args()
    main(args.source,args.no_ble,args.calibration,None if args.no_model else args.model,args.fusion)
