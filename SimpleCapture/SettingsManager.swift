import Foundation

class SettingsManager {
    
    // Keys for UserDefaults
    private enum Keys {
        static let frameRate = "SimpleCapture.frameRate"
        static let recordingDuration = "SimpleCapture.recordingDuration"
        static let playbackSpeed = "SimpleCapture.playbackSpeed"
    }
    
    // Default values
    private let defaultFrameRate = 60
    private let defaultRecordingDuration = 10
    private let defaultPlaybackSpeed: Float = 0.5
    
    // UserDefaults instance
    private let defaults = UserDefaults.standard
    
    // MARK: - Singleton
    
    static let shared = SettingsManager()
    
    private init() {
        // Set default values if this is the first launch
        if !defaults.bool(forKey: "SimpleCapture.initialized") {
            resetToDefaults()
            defaults.set(true, forKey: "SimpleCapture.initialized")
        }
    }
    
    // MARK: - Settings Access
    
    var frameRate: Int {
        get {
            return defaults.integer(forKey: Keys.frameRate)
        }
        set {
            // Only allow 60 or 120 FPS
            let validValue = (newValue == 60 || newValue == 120) ? newValue : defaultFrameRate
            defaults.set(validValue, forKey: Keys.frameRate)
        }
    }
    
    var recordingDuration: Int {
        get {
            return defaults.integer(forKey: Keys.recordingDuration)
        }
        set {
            // Limit between 5-30 seconds
            let validValue = max(5, min(newValue, 30))
            defaults.set(validValue, forKey: Keys.recordingDuration)
        }
    }
    
    var playbackSpeed: Float {
        get {
            return defaults.float(forKey: Keys.playbackSpeed)
        }
        set {
            // Limit between 0.25x - 2.0x
            let validValue = max(0.25, min(newValue, 2.0))
            defaults.set(validValue, forKey: Keys.playbackSpeed)
        }
    }
    
    // MARK: - Utilities
    
    func resetToDefaults() {
        defaults.set(defaultFrameRate, forKey: Keys.frameRate)
        defaults.set(defaultRecordingDuration, forKey: Keys.recordingDuration)
        defaults.set(defaultPlaybackSpeed, forKey: Keys.playbackSpeed)
    }
}