import Foundation
import AVFoundation
import UIKit

class CameraManager: NSObject {
    // Camera properties
    private var captureSession: AVCaptureSession?
    private var currentInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Settings
    private var currentFrameRate: Int = 120
    private var isUsingFrontCamera = false
    
    // Output file
    private var tempFilePath: URL?
    
    // Delegates
    weak var recordingDelegate: RecordingDelegate?
    
    override init() {
        super.init()
    }
    
    func setupCamera(in view: UIView) -> Bool {
        // Initialize capture session
        self.captureSession = AVCaptureSession()
        
        guard let captureSession = self.captureSession else { return false }
        
        // Set session preset
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .high
        }
        
        // Get the back camera
        guard let backCamera = getCamera(position: .back) else {
            print("Could not get back camera")
            return false
        }
        
        // Create input from camera
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                self.currentInput = input
            } else {
                print("Could not add camera input")
                return false
            }
        } catch {
            print("Error creating camera input: \(error)")
            return false
        }
        
        // Setup video output
        self.videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = self.videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Could not add video output")
            return false
        }
        
        // Setup preview layer
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = self.previewLayer else { return false }
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Set frame rate
        setFrameRate(fps: currentFrameRate)
        
        return true
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    func switchCamera() -> Bool {
        guard let session = captureSession, let currentInput = currentInput else { return false }
        
        // Begin session configuration
        session.beginConfiguration()
        
        // Remove current input
        session.removeInput(currentInput)
        
        // Get new camera
        let newPosition: AVCaptureDevice.Position = isUsingFrontCamera ? .back : .front
        guard let newCamera = getCamera(position: newPosition) else {
            // Failed to get new camera, revert to old one
            if session.canAddInput(currentInput) {
                session.addInput(currentInput)
            }
            session.commitConfiguration()
            return false
        }
        
        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                self.currentInput = newInput
                self.isUsingFrontCamera = !isUsingFrontCamera
            } else {
                // Cannot add new input, revert to old one
                if session.canAddInput(currentInput) {
                    session.addInput(currentInput)
                }
                session.commitConfiguration()
                return false
            }
        } catch {
            print("Error creating new input: \(error)")
            // Revert to old input
            if session.canAddInput(currentInput) {
                session.addInput(currentInput)
            }
            session.commitConfiguration()
            return false
        }
        
        // Update frame rate for new camera
        setFrameRate(fps: currentFrameRate)
        
        // Commit configuration
        session.commitConfiguration()
        return true
    }
    
    func setFrameRate(fps: Int) {
        self.currentFrameRate = fps
        
        guard let device = currentInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            let formats = device.formats
            var selectedFormat: AVCaptureDevice.Format?
            var maxFrameRate = 0
            
            // Find the format that supports the highest frame rate at 1080p
            for format in formats {
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let frameRates = format.videoSupportedFrameRateRanges
                
                if dimensions.height >= 1080 {
                    for range in frameRates {
                        if Int(range.maxFrameRate) > maxFrameRate && Int(range.maxFrameRate) >= fps {
                            maxFrameRate = Int(range.maxFrameRate)
                            selectedFormat = format
                        }
                    }
                }
            }
            
            if let format = selectedFormat {
                device.activeFormat = format
                
                // Set frame rate
                let targetFPS = fps > maxFrameRate ? maxFrameRate : fps
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFPS))
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFPS))
                
                print("Set frame rate to \(targetFPS) FPS")
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting frame rate: \(error)")
        }
    }
    
    func startRecording(duration: TimeInterval) {
        guard let output = videoOutput, !output.isRecording else { return }
        
        // Create a unique temporary file path
        let tempDir = NSTemporaryDirectory()
        let tempFileName = "recording-\(Date().timeIntervalSince1970).mp4"
        tempFilePath = URL(fileURLWithPath: tempDir).appendingPathComponent(tempFileName)
        
        guard let filePath = tempFilePath else { return }
        
        // Create connection
        guard let connection = output.connection(with: .video) else {
            print("No video connection available")
            return
        }
        
        // Set video orientation
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        // Start recording
        output.startRecording(to: filePath, recordingDelegate: self)
        
        // Set up timer to stop recording
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if output.isRecording {
                output.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        if let output = videoOutput, output.isRecording {
            output.stopRecording()
        }
    }
    
    // Helper method to get camera
    private func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        
        return discoverySession.devices.first
    }
    
    // Reset to prepare for a new recording
    func reset() {
        tempFilePath = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Notify delegate that recording has started
        recordingDelegate?.recordingDidStart()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error)")
            recordingDelegate?.recordingDidFail(with: error)
            return
        }
        
        // Notify delegate that recording completed successfully
        recordingDelegate?.recordingDidFinish(fileURL: outputFileURL)
    }
}

// Protocol for recording events
protocol RecordingDelegate: AnyObject {
    func recordingDidStart()
    func recordingDidFinish(fileURL: URL)
    func recordingDidFail(with error: Error)
}