import AVFoundation
import UIKit

class RecorderManager {
    
    // Recording settings
    private var duration: Int = 10 // Default 10 seconds
    private var frameRate: Int = 60 // Default 60 FPS
    
    // Recording objects
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var captureSession: AVCaptureSession?
    
    // Timer for recording duration
    private var recordingTimer: Timer?
    private var startTime: Date?
    private var tempVideoURL: URL?
    
    // Flags
    private var isRecording = false
    private var hasFinishedRecordingSession = false
    
    // Callbacks
    var onRecordingComplete: ((Result<URL, Error>) -> Void)?
    var onTimerUpdate: ((Int) -> Void)?
    
    // MARK: - Error Handling
    
    enum RecorderError: Error, LocalizedError {
        case recordingInProgress
        case captureSessionInvalid
        case assetWriterCreationFailed
        case outputCreationFailed
        case devicePerformance
        case interrupted
        case authorizationDenied
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .recordingInProgress:
                return "Recording already in progress"
            case .captureSessionInvalid:
                return "Camera not ready"
            case .assetWriterCreationFailed:
                return "Failed to create recording file"
            case .outputCreationFailed:
                return "Failed to set up recording output"
            case .devicePerformance:
                return "Device performance issue - recording stopped"
            case .interrupted:
                return "Recording was interrupted"
            case .authorizationDenied:
                return "Camera access not authorized"
            case .unknown:
                return "Unknown recording error"
            }
        }
    }
    
    // MARK: - Setup Methods
    
    init() {
        // Initialize recorder properties
    }
    
    // MARK: - Settings
    
    func setDuration(_ seconds: Int) {
        // Validate between 5-30 seconds
        if seconds >= 5 && seconds <= 30 {
            duration = seconds
        }
    }
    
    func setFrameRate(_ fps: Int) {
        // Typically 60 or 120
        if fps == 60 || fps == 120 {
            frameRate = fps
        }
    }
    
    // MARK: - Recording Methods
    
    func startRecording(captureSession: AVCaptureSession) {
        // Ensure we're not already recording
        guard !isRecording else {
            onRecordingComplete?(.failure(RecorderError.recordingInProgress))
            return
        }
        
        // Store capture session
        self.captureSession = captureSession
        
        // Reset flags
        hasFinishedRecordingSession = false
        
        // Create temporary URL for video
        let tempDir = FileManager.default.temporaryDirectory
        tempVideoURL = tempDir.appendingPathComponent("simplecapture_video_\(Date().timeIntervalSince1970).mp4")
        
        guard let videoURL = tempVideoURL else {
            onRecordingComplete?(.failure(RecorderError.assetWriterCreationFailed))
            return
        }
        
        // Remove any existing file
        try? FileManager.default.removeItem(at: videoURL)
        
        // Create asset writer
        do {
            assetWriter = try AVAssetWriter(outputURL: videoURL, fileType: .mp4)
        } catch {
            print("Error creating asset writer: \(error.localizedDescription)")
            onRecordingComplete?(.failure(error))
            return
        }
        
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920, // 1080p resolution
            AVVideoHeightKey: 1080,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000, // 10 Mbps for good quality
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: frameRate // One keyframe per second
            ]
        ]
        
        // Create writer input
        assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        guard let writerInput = assetWriterInput else {
            onRecordingComplete?(.failure(RecorderError.outputCreationFailed))
            return
        }
        
        // Configure writer input
        writerInput.expectsMediaDataInRealTime = true
        writerInput.transform = CGAffineTransform(rotationAngle: .pi/2) // Portrait orientation
        
        // Add input to writer
        if let writer = assetWriter, writer.canAdd(writerInput) {
            writer.add(writerInput)
        } else {
            onRecordingComplete?(.failure(RecorderError.outputCreationFailed))
            return
        }
        
        // Create and configure video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = false // We want all frames for slow-motion
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        // Add output to session
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            onRecordingComplete?(.failure(RecorderError.outputCreationFailed))
            return
        }
        
        self.videoOutput = videoOutput
        
        // Set recording flag
        isRecording = true
        
        // Start asset writer
        if assetWriter?.startWriting() != true {
            stopRecording()
            onRecordingComplete?(.failure(RecorderError.assetWriterCreationFailed))
            return
        }
        
        assetWriter?.startSession(atSourceTime: CMTime.zero)
        
        // Start timer for recording duration
        startTime = Date()
        startTimer()
        
        print("Recording started for \(duration) seconds at \(frameRate) FPS")
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("Stopping recording")
        
        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Flag that we're finishing
        hasFinishedRecordingSession = true
        
        // If writer input isn't ready yet, we need to wait a bit
        if let writerInput = assetWriterInput, !writerInput.isReadyForMoreMediaData {
            print("Writer input not ready, waiting...")
            // Wait briefly for writer to be ready
            let deadline = DispatchTime.now() + .milliseconds(500)
            DispatchQueue.global().asyncAfter(deadline: deadline) { [weak self] in
                self?.finalizeRecording()
            }
        } else {
            finalizeRecording()
        }
    }
    
    private func finalizeRecording() {
        isRecording = false
        
        // Clean up capture session
        if let videoOutput = videoOutput, let captureSession = captureSession {
            captureSession.beginConfiguration()
            captureSession.removeOutput(videoOutput)
            captureSession.commitConfiguration()
        }
        
        self.videoOutput = nil
        
        // Finalize asset writer
        assetWriterInput?.markAsFinished()
        
        if let writer = assetWriter, writer.status == .writing {
            writer.finishWriting { [weak self] in
                guard let self = self else { return }
                
                if let error = writer.error {
                    print("Error finishing writing: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        self.onRecordingComplete?(.failure(error))
                    }
                    return
                }
                
                if let videoURL = self.tempVideoURL {
                    DispatchQueue.main.async {
                        self.onRecordingComplete?(.success(videoURL))
                    }
                } else {
                    DispatchQueue.main.async {
                        self.onRecordingComplete?(.failure(RecorderError.unknown))
                    }
                }
            }
        } else {
            let error = assetWriter?.error ?? RecorderError.unknown
            print("Asset writer not in writing state: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.onRecordingComplete?(.failure(error))
            }
        }
        
        assetWriter = nil
        assetWriterInput = nil
    }
    
    // MARK: - Timer Methods
    
    private func startTimer() {
        // Create a timer to update UI and stop recording when duration is reached
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            let elapsedTime = Int(-startTime.timeIntervalSinceNow * 1000)
            let remainingTime = max(0, self.duration * 1000 - elapsedTime)
            
            // Update timer display
            DispatchQueue.main.async {
                self.onTimerUpdate?(remainingTime)
            }
            
            // Check if we've reached the duration
            if remainingTime <= 0 {
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
                
                // Stop recording on main thread to avoid threading issues
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension RecorderManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Skip if we're not recording or already finishing
        guard isRecording, !hasFinishedRecordingSession else { return }
        
        // Make sure the writer input is ready
        guard let writerInput = assetWriterInput, writerInput.isReadyForMoreMediaData else {
            return
        }
        
        // Check for error status in the asset writer
        if let writer = assetWriter, writer.status == .failed {
            print("AssetWriter failed: \(writer.error?.localizedDescription ?? "unknown error")")
            DispatchQueue.main.async {
                self.stopRecording()
                self.onRecordingComplete?(.failure(writer.error ?? RecorderError.unknown))
            }
            return
        }
        
        // Append the sample buffer
        if !writerInput.append(sampleBuffer) {
            print("Failed to append sample buffer")
            
            if let error = assetWriter?.error {
                print("AssetWriter error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.stopRecording()
                    self.onRecordingComplete?(.failure(error))
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // This is called when frames are dropped, which is bad for slow-motion
        print("Warning: Dropped frame detected")
        
        // If we're dropping multiple frames, we might want to consider stopping recording
        // As an optimization, you could count dropped frames and stop if too many are dropped
    }
}