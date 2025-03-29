import Foundation

class SettingsManager {
    // Default settings
    private let defaultDuration: TimeInterval = 10.0
    private let defaultFrameRate: Int = 120
    
    // Current settings
    private(set) var recordingDuration: TimeInterval
    private(set) var frameRate: Int
    
    // Available options
    let durationOptions: [TimeInterval] = [5.0, 10.0, 15.0, 20.0, 30.0]
    let frameRateOptions: [Int] = [60, 120]
    
    // Delegate
    weak var delegate: SettingsDelegate?
    
    init() {
        self.recordingDuration = defaultDuration
        self.frameRate = defaultFrameRate
    }
    
    func setRecordingDuration(_ duration: TimeInterval) {
        guard durationOptions.contains(duration) else { return }
        recordingDuration = duration
        delegate?.settingsDidUpdate()
    }
    
    func setFrameRate(_ fps: Int) {
        guard frameRateOptions.contains(fps) else { return }
        frameRate = fps
        delegate?.settingsDidUpdate()
    }
    
    func resetToDefaults() {
        recordingDuration = defaultDuration
        frameRate = defaultFrameRate
        delegate?.settingsDidUpdate()
    }
}

// Protocol for settings updates
protocol SettingsDelegate: AnyObject {
    func settingsDidUpdate()
}