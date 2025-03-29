import Foundation
import AVFoundation
import UIKit

class RecorderManager: NSObject {
    // Recording properties
    private var cameraManager: CameraManager
    private var isRecording = false
    private var recordingDuration: TimeInterval = 10.0
    private var timer: Timer?
    private var startTime: Date?
    private var recordedVideoURL: URL?
    
    // UI elements
    weak var statusLabel: UILabel?
    weak var timerLabel: UILabel?
    weak var recordButton: UIButton?
    
    // Delegate
    weak var delegate: RecorderManagerDelegate?
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init()
        
        // Set as recording delegate
        cameraManager.recordingDelegate = self
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        startTime = Date()
        
        // Update UI
        statusLabel?.text = "Recording"
        statusLabel?.isHidden = false
        recordButton?.isSelected = true
        
        // Start timer
        startTimer()
        
        // Start recording
        cameraManager.startRecording(duration: recordingDuration)
        
        // Haptic feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        cameraManager.stopRecording()
        stopTimer()
    }
    
    func setDuration(_ seconds: TimeInterval) {
        recordingDuration = seconds
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        // Cancel any existing timer
        timer?.invalidate()
        
        // Update timer immediately
        updateTimerDisplay()
        
        // Create a new timer that fires every 0.1 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimerDisplay()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerLabel?.text = "00:00"
    }
    
    private func updateTimerDisplay() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, recordingDuration - elapsed)
        
        let seconds = Int(remaining)
        let milliseconds = Int((remaining - Double(seconds)) * 100)
        
        timerLabel?.text = String(format: "%02d:%02d", seconds, milliseconds)
        
        // If timer has reached zero, update UI
        if remaining <= 0 {
            timerLabel?.text = "00:00"
            timer?.invalidate()
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        stopTimer()
        recordedVideoURL = nil
    }
}

// MARK: - RecordingDelegate Implementation
extension RecorderManager: RecordingDelegate {
    func recordingDidStart() {
        print("Recording started")
    }
    
    func recordingDidFinish(fileURL: URL) {
        print("Recording finished: \(fileURL)")
        isRecording = false
        stopTimer()
        
        // Update UI
        statusLabel?.isHidden = true
        recordButton?.isSelected = false
        
        // Save the URL
        recordedVideoURL = fileURL
        
        // Notify delegate
        delegate?.recorderDidFinishRecording(videoURL: fileURL)
        
        // Haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
    }
    
    func recordingDidFail(with error: Error) {
        print("Recording failed: \(error)")
        isRecording = false
        stopTimer()
        
        // Update UI
        statusLabel?.isHidden = true
        recordButton?.isSelected = false
        
        // Notify delegate
        delegate?.recorderDidFailRecording(error: error)
        
        // Haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.error)
    }
}

// Protocol for recorder events
protocol RecorderManagerDelegate: AnyObject {
    func recorderDidFinishRecording(videoURL: URL)
    func recorderDidFailRecording(error: Error)
}