# SimpleCapture - High-Quality Slow-Motion iOS App

## Overview
SimpleCapture is a native iOS application for recording and playing back high-quality slow-motion videos. The app allows users to record videos at high frame rates (60 FPS or 120 FPS) and play them back at various speeds from 0.25x to 2.0x.

## Features
- Record videos at high frame rates (60 FPS or 120 FPS)
- Adjustable recording duration (5-30 seconds)
- Configurable playback speed (0.25x to 2.0x)
- Camera switching between front and back
- Real-time recording countdown
- Save videos to photo library
- Portrait orientation optimized UI

## Requirements
- iOS 14.0+
- Xcode 13.0+
- Swift 5.0+
- iPhone with front and rear cameras

## Installation
1. Download the SimpleCapture.zip file
2. Extract the contents
3. Open SimpleCapture.xcodeproj in Xcode
4. Build and run on your iOS device (note: camera functionality requires a physical device)

## Usage
### Recording
1. Launch the app
2. Use the gear icon to adjust frame rate and recording duration
3. Press the large red button to start recording
4. The countdown timer shows remaining recording time
5. Recording stops automatically when time is up, or press the stop button

### Playback
- After recording, the app automatically switches to playback mode
- Use the slider to adjust playback speed (0.25x to 2.0x)
- Press play/pause to control playback
- Press the save button (top right) to save the video to your photo library
- Press the X button (top left) to discard and record a new video

## Technical Implementation
SimpleCapture is built using:
- AVFoundation for camera access and recording
- UIKit for the user interface
- Swift's Result type for robust error handling
- Comprehensive fallback mechanisms for device compatibility

## Compatibility Notes
- 120 FPS recording may not be available on all devices
- If the app crashes on startup, try using 60 FPS mode
- For best results, use in well-lit environments

## License
This app is distributed under the MIT license. See LICENSE file for details.