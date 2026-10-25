# Driver Drowsiness Detection System

**A Real-Time Multi-Modal Deep Learning System for Driver Safety**

Graduation Project — Data Science Department, College of Computing, Umm Al-Qura University
Project ID: DS-GP-2026-001 | Supervisor: Dr. Mohammad Kamal Halwani

---

## Overview

Driver drowsiness is responsible for an estimated 20–30% of fatal road crashes worldwide. This project presents a complete, real-time drowsiness detection system that monitors three simultaneous behavioral indicators using only a standard webcam and a CPU-equipped laptop — no wearable sensors or vehicle modifications required.

The system fuses three modalities through a rule-based decision module:

- **Eye Closure (PERCLOS)** — classifies eye state every frame using a deep learning model. If the eyes are closed more than 60% of the time within a 3-second, 90-frame window, a DANGER alert is triggered.
- **Yawn Detection** — a dedicated model detects yawning. Two or more yawn events within a 2-minute rolling window trigger a WARNING alert.
- **Head Pose Estimation** — MediaPipe FaceMesh + PnP algorithm tracks head pitch. Sustained downward head deviation beyond 20 consecutive frames indicates imminent microsleep.

**Alert logic:**
- 🟠 **WARNING** — one non-PERCLOS indicator is active
- 🔴 **DANGER** — PERCLOS triggers, or two or more indicators are active simultaneously

---

## Model Architecture

The core classification backbone is **EfficientNetV2-S** pre-trained on ImageNet, augmented with a **Convolutional Block Attention Module (CBAM)** that applies sequential channel and spatial attention. This combination provides:

- Channel attention: identifies which of the 1,280 feature channels are most informative
- Spatial attention: focuses on the eyelid gap and iris — the small discriminative region within each eye crop

### Two-Phase Transfer Learning Strategy

| Phase | Layers Trained | Purpose |
|---|---|---|
| Phase 1 | CBAM + classification head only | Adapt attention and classifier to the new task |
| Phase 2 | Full network fine-tuning | End-to-end optimization |

### Sensor-Specific Submodels + Weighted Majority Voting

The MRL Eye Dataset contains images from three distinct infrared sensors with very different characteristics. Training a single pooled model would bias toward the dominant sensor (sensor 02 contributes ~70% of images). Instead, three independent submodels are trained — one per sensor — and combined at inference time using Weighted Majority Voting, where each model's weight is proportional to its individual test-set accuracy.

---

## Datasets

| Dataset | Source | Size | Task |
|---|---|---|---|
| MRL Eye Dataset | VSB-Technical University of Ostrava | 84,898 infrared images | Eye state (open/closed) |
| Yawn Eye Dataset | Kaggle | — | Yawn detection |

The MRL dataset covers 33 subjects (17 male, 16 female) across three infrared sensor types, under varying illumination, with and without glasses, in daytime and nighttime conditions.

---

## Results

| Model | Test Accuracy |
|---|---|
| Main Eye Model (EfficientNetV2-S + CBAM) | **99.11%** |
| Weighted Majority Voting Ensemble (3 submodels) | **95.69%** |
| Yawn Detection Model | **99.53%** |

**System-level performance:** 25–30 fps on a standard Intel Core i7 CPU (no GPU required). Audio alerts delivered within 100ms of state changes via a multi-threaded alert manager.

---

## Real-Time Pipeline

```
Webcam → MediaPipe FaceMesh (478 landmarks) → [Eye crop | Face crop | Head pose]
       → [Eye model | Yawn model | PnP geometry]
       → Temporal buffers (PERCLOS / yawn count / head deviation)
       → Alert decision logic → Annotated display + Audio alert
```

The entire pipeline runs on a single thread (except audio playback in a daemon thread). Switching to GPU requires only changing `DEVICE = 'cpu'` to `DEVICE = 'cuda'` — no other code changes.

---

## Project Structure

```
drowsiness-detection-main/
├── src/
│   ├── model.py          # EfficientNetV2-S + CBAM architecture
│   ├── dataset.py        # MRL and Yawn dataset preparation
│   ├── train.py          # Two-phase training loop
│   ├── evaluate.py       # Evaluation + voting weight computation
│   └── demo.py           # Live webcam demo
├── outputs/
│   ├── models/           # Trained .pth files (see Releases)
│   └── plots/            # Confusion matrices
├── alert_danger.wav      # DANGER alert sound
├── alert_warning.wav     # WARNING alert sound
├── requirements.txt
└── .gitignore
```

---

## How to Run

**Install dependencies:**
```bash
pip install -r requirements.txt
```

**Prepare datasets** (MRL Eye Dataset must be placed in `mrl_data/`):
```bash
python src/dataset.py --task eye
python src/dataset.py --task yawn
```

**Train models:**
```bash
python src/train.py                    # Main eye model
python src/train.py --sensor small     # Sensor-specific submodel
python src/train.py --sensor medium
python src/train.py --sensor large
python src/train.py --task yawn        # Yawn detection model
```

**Evaluate:**
```bash
python src/evaluate.py --task all
```

**Run live demo:**
```bash
python src/demo.py --cam 0
```

Press **Q** or **ESC** to exit.

---

## Requirements

- Python 3.9+
- PyTorch (CUDA optional — CPU inference supported)
- OpenCV, MediaPipe, NumPy, Pillow, scikit-learn
- Full list in `requirements.txt`

> **Note:** Trained model weights (.pth files) are too large for GitHub. Download them from the [Releases](../../releases) section.

---

## Team

| Name |
|---|
| Abdullah Mansour Habit |
| Salman Talaq Alsulami |
| Abdulaziz Mohammed Alghriby |
| Mujahid Naji Al-Harbi |
| Nasser Jamal Banjar |

**University:** Umm Al-Qura University — College of Computing, Data Science Department
**Supervisor:** Dr. Mohammad Kamal Halwani
**Year:** 2025 / 2026
