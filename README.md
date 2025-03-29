# SimpleCapture iOS Application

SimpleCapture is an iOS application designed for recording and playing back high-quality slow-motion videos with customizable settings.

## Key Features

- **Video Recording**
  - Support for recording at 60 FPS and 120 FPS
  - Configurable recording duration (5-30 seconds)
  - Clear status indicators during recording
  - Camera switching between front and rear cameras

- **Playback Functionality**
  - Automatic looping of recorded videos
  - Adjustable playback speed (0.25x to 2.0x)
  - Muted audio during playback to focus on visual content
  - Intuitive playback controls

- **User Interface**
  - Clean, iOS-style design
  - Status indicators for recording and playback
  - Settings panel for configuration
  - Portrait orientation lock for consistent experience

## Application Structure

- **HTML/CSS/JavaScript Architecture**
  - Modular JavaScript with separate classes for Camera, Recorder, and Player
  - Responsive CSS for various iOS device displays
  - Clean HTML structure following iOS design principles

- **Core Modules**
  - `camera.js`: Handles camera initialization, switching, and frame rate configuration
  - `recorder.js`: Manages recording functionality and timer display
  - `player.js`: Controls video playback with variable speed options
  - `app.js`: Main application logic and UI interactions

## Requirements

- **Device Compatibility**
  - iPad 10, iPhone XS Max, and newer iOS devices
  - Modern Safari browser with camera permissions

## UI Sections

1. **Header**: App title and description
2. **Camera View**: Primary video display area
3. **Status Bar**: Shows recording status and timer
4. **Controls**:
   - Record Button: Start/stop recording
   - Camera Switch: Toggle between front/rear cameras
   - Settings: Access configuration options
5. **Playback Controls**: Slider for adjusting video speed
6. **Settings Panel**: Options for recording duration and frame rate

## Browser Access
When testing in a browser environment:
- Camera access permission is required
- In secure contexts (HTTPS), all features will be available
- In environments without camera access, the app will run in limited mode

---

*Note: This application is optimized for iOS devices and may have limited functionality when running in non-mobile environments.*