"""Experimental RiderShield webcam EAR + downward-gaze calibration.
Requires: opencv-python, mediapipe, numpy, and existing drowsiness_led_bridge.py.
Not validated for real riding or safety-critical use.
"""
import argparse
import time
from collections import deque
import cv2
import numpy as np
import mediapipe as mp

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

def main(source, no_ble):
    cap=cv2.VideoCapture(int(source) if source.isdecimal() else source)
    if not cap.isOpened():
        raise SystemExit('Cannot open camera. Try --source 1')
    cap.set(cv2.CAP_PROP_BUFFERSIZE,1)
    ble=None
    if not no_ble:
        from drowsiness_led_bridge import BleSender
        ble=BleSender('RiderShield-Helmet','12345678-1234-5678-1234-56789abcdef1')
    samples={k:[] for k in ('open','down','closed')}
    history=deque(maxlen=3)
    closed_since=None
    last_closed=None
    last_sent=None
    mesh=mp.solutions.face_mesh.FaceMesh(max_num_faces=1,refine_landmarks=True,
                                         min_detection_confidence=.5,min_tracking_confidence=.5)
    try:
        while True:
            ok,frame=cap.read()
            if not ok:
                time.sleep(.02)
                continue
            frame=cv2.resize(frame,(640,480))
            rgb=cv2.cvtColor(frame,cv2.COLOR_BGR2RGB)
            result=mesh.process(rgb)
            values=None
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
                print('[CAL] reset')
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
                    history.clear();closed_since=last_closed=None
    finally:
        if ble:
            ble.set_level('UNKNOWN')
            ble.stop()
        mesh.close();cap.release();cv2.destroyAllWindows()

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',default='0')
    parser.add_argument('--no-ble',action='store_true',help='Webcam-only test; no LED/BLE traffic')
    args=parser.parse_args()
    main(args.source,args.no_ble)
