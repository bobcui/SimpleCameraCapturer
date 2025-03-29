import AVFoundation
import UIKit

class CameraManager {
    
    // Camera properties
    private var captureSession: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Configuration
    private var currentPosition: AVCaptureDevice.Position = .back
    private var lastRecordedVideoURL: URL?
    
    // Error handling
    enum CameraError: Error, LocalizedError {
        case cameraUnavailable
        case cameraSetupFailed
        case invalidCameraInput
        case noCamera
        case accessDenied
        case invalidOperation
        case highFrameRateUnsupported
        
        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is unavailable"
            case .cameraSetupFailed:
                return "Failed to set up the camera"
            case .invalidCameraInput:
                return "Invalid camera input"
            case .noCamera:
                return "No camera available"
            case .accessDenied:
                return "Camera access denied"
            case .invalidOperation:
                return "Invalid camera operation"
            case .highFrameRateUnsupported:
                return "High frame rate not supported on this device"
            }
        }
    }
    
    // MARK: - Initialization
    
    func initialize(preferredFrameRate: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        // Check authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession(preferredFrameRate: preferredFrameRate, completion: completion)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession(preferredFrameRate: preferredFrameRate, completion: completion)
                } else {
                    completion(.failure(CameraError.accessDenied))
                }
            }
            
        default:
            completion(.failure(CameraError.accessDenied))
        }
    }
    
    private func setupCaptureSession(preferredFrameRate: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Create a new capture session
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            do {
                // Get the appropriate camera
                guard let videoDevice = self.getCamera(position: self.currentPosition) else {
                    completion(.failure(CameraError.noCamera))
                    return
                }
                
                // Check if device supports requested frame rate
                let supportedFrameRates = try self.getSupportedFrameRates(for: videoDevice)
                
                if preferredFrameRate > 60 && !supportedFrameRates.contains(where: { $0 >= Float64(preferredFrameRate) }) {
                    completion(.failure(CameraError.highFrameRateUnsupported))
                    return
                }
                
                // Try to set the frame rate
                try self.setFrameRate(for: videoDevice, fps: preferredFrameRate)
                
                // Create input from device
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                
                // Check if session can add input
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    completion(.failure(CameraError.invalidCameraInput))
                    return
                }
                
                // Create and add output
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
                
                // Create and configure preview layer
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.videoGravity = .resizeAspectFill
                
                // Store references
                self.captureSession = session
                self.previewLayer = previewLayer
                
                // Start the session
                session.startRunning()
                
                completion(.success(()))
                
            } catch {
                print("Camera setup failed: \(error.localizedDescription)")
                
                // Map the error if possible
                if let error = error as? CameraError {
                    completion(.failure(error))
                } else {
                    completion(.failure(CameraError.cameraSetupFailed))
                }
            }
        }
    }
    
    // MARK: - Camera Control
    
    func switchCamera(completion: @escaping (Error?) -> Void) {
        guard let session = captureSession, let currentInput = videoDeviceInput else {
            completion(CameraError.invalidOperation)
            return
        }
        
        // Determine the new position
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        // Get the new camera
        guard let newCamera = getCamera(position: newPosition) else {
            completion(CameraError.noCamera)
            return
        }
        
        do {
            // Create input for the new camera
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            
            // Configure the session
            session.beginConfiguration()
            
            // Remove old input
            session.removeInput(currentInput)
            
            // Add new input
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
                currentPosition = newPosition
            } else {
                // If can't add the new input, add the old one back
                session.addInput(currentInput)
                throw CameraError.invalidCameraInput
            }
            
            session.commitConfiguration()
            
            completion(nil)
            
        } catch {
            completion(error)
        }
    }
    
    func stopCamera() {
        captureSession?.stopRunning()
    }
    
    // MARK: - Helper Methods
    
    private func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
    
    private func getSupportedFrameRates(for device: AVCaptureDevice) throws -> [Float64] {
        var frameRates: [Float64] = []
        
        do {
            try device.lockForConfiguration()
            
            // Go through all formats for this device
            for format in device.formats {
                // Find the highest supported frame rate
                let ranges = format.videoSupportedFrameRateRanges
                for range in ranges {
                    frameRates.append(range.maxFrameRate)
                }
            }
            
            device.unlockForConfiguration()
            
            return frameRates.sorted()
            
        } catch {
            print("Error getting supported frame rates: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func setFrameRate(for device: AVCaptureDevice, fps: Int) throws {
        do {
            try device.lockForConfiguration()
            
            // Find a format that supports the requested FPS
            var selectedFormat: AVCaptureDevice.Format?
            var maxWidth: Int32 = 0
            
            // Look for the format with highest resolution that supports our FPS
            for format in device.formats {
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let width = dimensions.width
                
                // Check if this format supports the desired frame rate
                let ranges = format.videoSupportedFrameRateRanges
                for range in ranges {
                    if range.maxFrameRate >= Float64(fps) && width >= maxWidth {
                        selectedFormat = format
                        maxWidth = width
                    }
                }
            }
            
            // Set the format if we found one
            if let format = selectedFormat {
                device.activeFormat = format
                
                // Set frame rate
                device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
                device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
                
                print("Set camera to \(fps) FPS with resolution \(maxWidth)p")
            } else {
                print("No format available for \(fps) FPS")
                // Use the default format but try to set the frame rate anyway
                device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
                device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
            }
            
            device.unlockForConfiguration()
            
        } catch {
            print("Error setting frame rate: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Accessors
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }
    
    func getLastRecordedVideoURL() -> URL? {
        return lastRecordedVideoURL
    }
    
    func setLastRecordedVideoURL(_ url: URL) {
        lastRecordedVideoURL = url
    }
}