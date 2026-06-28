# Face Filter App - Edge AI Face Filter iOS Application

## Project Overview

FaceFilterApp is a real-time Snapchat-like iOS application built in Swift that applies four distinct AI-powered face filters entirely on-device, with no internet connection required. The app demonstrates edge AI deployment using Apple's ARKit, Core ML, Vision, and Core Image frameworks, running all inference locally on the iPhone's TrueDepth camera and Apple Neural Engine.


## Results

- All four filters run at a stable **60 FPS** on iPhone 16 Pro Max with no dropped frames
- The on-device age estimator outperforms a Colab T4 GPU baseline: **60 FPS on-device vs. 13.1 FPS on GPU**, demonstrating the performance advantage of Apple's Neural Engine for single-sample inference
- The Core Image aging pipeline achieves **60 FPS on-device vs. 5.6 FPS** on an equivalent CPU/GPU pipeline
- **100% user success rate** for the Accessories and 1900s filters in a 20-participant binary study; 80% for Expression detection and 70% for the Age Estimator
- Custom age classification model trained on **23,708 UTKFace images** in under 20 minutes using Apple Create ML, achieving 54.7% training accuracy and 52.8% validation accuracy across six age-group classes — consistent with published CNN-based age estimation benchmarks

## Features

- **Filter 1 — Accessories:** Real-time hat and sunglasses overlay anchored to face geometry via ARKit face tracking; accessories automatically follow head movement in 3D space
- **Filter 2 — Expression Detection:** Classifies facial expressions (Happy, Surprised, Angry, Neutral) in real time using ARKit's 52 blend shape coefficients — no separate ML model required
- **Filter 3 — Age Estimator:** Custom Core ML image classifier trained on the UTKFace dataset predicts the user's age group (0–15, 16–25, 26–35, 36–50, 51–65, 66+) with confidence score
- **Filter 4 — 1900s Effect:** Five-stage Core Image pixel processing chain applies a stylised historic visual effect (desaturation, warm tone shift, texture sharpening, vignette, bloom) to the live camera feed
- **Filter switching:** Smooth animated navigation between filters with dot-position indicators
- **Front/back camera toggle:** Flip between TrueDepth front camera (AR filters) and rear camera
- **In-app photo capture:** Save screenshots of any active filter directly to the iOS Photos app with flash feedback and toast confirmation

## Technologies

- **Swift** — primary application language
- **ARKit** (ARFaceTrackingConfiguration) — real-time 3D face tracking via TrueDepth camera; 1,220-vertex face mesh; 52 blend shape coefficients
- **SceneKit** (SCNPlane, SCNNode) — 3D scene rendering for accessory overlays
- **Core ML** (VNCoreMLModel, VNCoreMLRequest) — on-device inference for the age classification model
- **Vision** (VNImageRequestHandler, VNClassificationObservation) — image request pipeline for camera frame inference
- **Core Image** (CIFilter, CIContext) — pixel-level processing chain for the 1900s visual effect
- **UIKit** — interface layer; blur effects, animated controls, capture button
- **Apple Create ML** — model training tool used to train the custom age classifier
- **UTKFace Dataset** (Zhang, Song & Qi, 2017) — 23,708 labelled facial images used for age classifier training
- **Python** (shutil, os) — data preparation script to sort UTKFace images into class folders compatible with Create ML
- **Google Colab** (T4 GPU) — used for GPU-environment benchmarking of inference latency

## Setup / Installation

> **Requirements:** Mac with Xcode 16+, iPhone X or later (TrueDepth camera required for face tracking), iOS 17+, free Apple Developer account

1. Clone the repository:
```bash
git clone <repository-url>
cd FaceFilterApp
```

2. Open the project in Xcode:
```bash
open FaceFilterApp.xcodeproj
```

3. Add the trained Core ML model:
   - Either train your own (see [Training the Age Classifier](#training-the-age-classifier) below), or add your own `.mlmodel` file named `AgeClassifier.mlmodel`
   - Drag `AgeClassifier.mlmodel` into the Xcode project navigator — check **Copy items if needed** → Finish

4. Add accessory PNG assets:
   - Source two transparent-background PNG images: a party hat and a pair of sunglasses (e.g. from [flaticon.com](https://flaticon.com))
   - In Xcode, open `Assets.xcassets` → New Image Set → name exactly `hat` → drag PNG into the 2x slot
   - Repeat for `glasses`

5. Configure signing:
   - In Xcode → click the blue project icon → Targets → FaceFilterApp → Signing & Capabilities
   - Select your Apple ID under **Team**

6. Connect your iPhone via USB → select it as the build target → press **Cmd+R**

7. On first run, go to iPhone Settings → General → VPN & Device Management → trust your developer certificate

### Training the Age Classifier

If you want to train the age classification model yourself:

```bash
# 1. Download UTKFace dataset from Kaggle: kaggle.com/datasets/jangedoo/utkface-new
# 2. Run the sorting script to create class folders for Create ML:
python3 sort_utkface.py
```

Then open **Create ML** on your Mac (Xcode menu → Open Developer Tool → Create ML), create a new Image Classification project, drag in the `UTKFace_Sorted` folder, set iterations to 25, and click Train. Export via Get → Core ML Model.

## Usage

1. Launch the app on your iPhone — the front camera activates automatically with face tracking enabled
2. Point the front camera at your face — ARKit will detect and track it in real time
3. Use the **◀ Prev** and **Next ▶** buttons at the bottom to cycle through the four filters
4. The active filter name is shown at the top; dot indicators show your position in the sequence
5. Tap the **white circle button** (centre, above the nav bar) to capture and save a photo to your Photos app
6. Tap the **camera flip icon** (bottom right) to switch between front and rear camera

Filter-specific notes:
```
Filter 1 (Accessories)   — hat and glasses appear automatically when a face is detected
Filter 2 (Expression)    — make exaggerated expressions: big smile, wide eyes, furrowed brows
Filter 3 (Age Estimator) — hold still and face the camera directly; updates approximately once per second
Filter 4 (1900s)         — applies to the full camera frame; works with front or rear camera
```

## Project Structure

```
FaceFilterApp/
├── FaceFilterApp/
│   ├── ViewController.swift       # Main app logic — all four filters, AR session, UI
│   ├── Assets.xcassets/
│   │   ├── hat.imageset/          # Party hat PNG asset
│   │   ├── glasses.imageset/      # Sunglasses PNG asset
│   │   └── AppIcon.appiconset/    # App icon
│   ├── AgeClassifier.mlmodel      # Trained Core ML age classification model
│   ├── Info.plist                 # Camera and photo library privacy permissions
│   └── LaunchScreen.storyboard
├── scripts/
│   └── sort_utkface.py            # UTKFace dataset sorting script for Create ML
├── FaceFilterApp.xcodeproj
└── README.md
```

## Outputs / Example

The app renders all output directly on-screen in real time. When the capture button is tapped, a full-resolution PNG screenshot is saved to the device's Photos app.

**Filter 3 — Age Estimator label output example:**
```
Age: 16–25 🧑 (78%)
```

**Filter 2 — Expression label output example:**
```
Happy 😊
```

**UTKFace sorting script output:**
```bash
Done - sorted 23708 images into ~/Downloads/UTKFace_Sorted
```

**Create ML training results:**
```
Training accuracy:    54.7%
Validation accuracy:  52.8%
Classes:              6 (0_15, 16_25, 26_35, 36_50, 51_65, 66_plus)
Iterations:           25
Training images:      23,708
```

**Benchmark summary (iPhone 16 Pro Max vs. Colab T4 GPU):**
```
Filter                  iPhone FPS    Colab FPS    iPhone CPU%    iPhone RAM
────────────────────────────────────────────────────────────────────────────
1. Accessories          60            N/A           53%            208.8 MB
2. Expression           60            N/A           45%            210.0 MB
3. Age Estimator        60            13.1          37%            215.4 MB
4. 1900s Effect         60            5.6           101%           291.8 MB
```

## Notes / Additional Info

- **TrueDepth camera required:** ARKit face tracking (Filters 1, 2, 3) only works on iPhone X or later. The app will gracefully exit the AR session on unsupported devices.
- **Filter 4 CPU usage:** The Core Image pipeline for Filter 4 pushes CPU to ~101% during sustained use. This is expected behaviour — Apple's CIContext routes computation across CPU, GPU, and ISP simultaneously. The device may warm slightly during extended use of this filter.
- **Age estimator accuracy:** The model predicts age *groups* (six classes), not exact ages. It performs best on faces directly facing the camera in good lighting. At ~52.8% validation accuracy, roughly one in three predictions may fall outside the correct bracket — consistent with published age estimation benchmarks.
- **Expression detection sensitivity:** Thresholds are fixed (smile > 0.35, jaw open > 0.4, brow down > 0.4). If detection feels sluggish, try more exaggerated expressions — strong, deliberate movements register more reliably than subtle ones.
- **Privacy:** All face processing happens entirely on-device. No images, video, or biometric data are transmitted to any server at any point.
- **Photo library permission:** The app requests photo library write access when you first tap the capture button. If the permission dialog does not appear, go to iPhone Settings → FaceFilterApp → Photos → Add Photos Only.
- **Troubleshooting — "Face tracking not supported":** Confirm the build target is a physical iPhone X or later, not the Xcode simulator. The simulator does not emulate the TrueDepth sensor.
- **Troubleshooting — model not found crash:** Confirm `AgeClassifier.mlmodel` is added to the Xcode target (select the file → right panel → Target Membership → FaceFilterApp checked).
- **Troubleshooting — accessories not appearing:** Confirm the PNG assets are named exactly `hat` and `glasses` (lowercase) in `Assets.xcassets`. The image names in code are case-sensitive.
