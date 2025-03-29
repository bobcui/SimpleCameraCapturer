import AVFoundation
import UIKit

class VideoPlayerManager {
    
    // Player objects
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var videoURL: URL?
    
    // Playback settings
    private var playbackSpeed: Float = 0.5 // Default to 0.5x
    private var isLooping = true
    
    // Error handling
    enum PlayerError: Error, LocalizedError {
        case videoNotLoaded
        case invalidURL
        case playerCreationFailed
        
        var errorDescription: String? {
            switch self {
            case .videoNotLoaded:
                return "No video is loaded"
            case .invalidURL:
                return "Invalid video URL"
            case .playerCreationFailed:
                return "Failed to create video player"
            }
        }
    }
    
    // MARK: - Setup Methods
    
    func setupPlayerInView(_ view: UIView) {
        // Clean up any existing player
        cleanup()
        
        // Create new player
        player = AVPlayer()
        
        // Create layer for display
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        
        // Store layer
        playerLayer = layer
        
        print("Video player setup in view")
    }
    
    // MARK: - Playback Methods
    
    func loadVideo(from url: URL) {
        guard let player = player else {
            print("Error: Player not initialized")
            return
        }
        
        // Store URL
        videoURL = url
        
        // Create asset and item
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        if isLooping {
            // Set up looping playback
            if let queuePlayer = player as? AVQueuePlayer {
                playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            } else {
                // Create new queue player for looping
                let queuePlayer = AVQueuePlayer(playerItem: playerItem)
                playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
                
                // Replace the player
                playerLayer?.player = queuePlayer
                self.player = queuePlayer
            }
        } else {
            // Non-looping playback
            player.replaceCurrentItem(with: playerItem)
            
            // Add notification for playback ended
            NotificationCenter.default.addObserver(self, 
                                                  selector: #selector(playerDidFinishPlaying),
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: playerItem)
        }
        
        // Apply current speed
        setPlaybackSpeed(playbackSpeed)
        
        print("Video loaded from \(url.lastPathComponent)")
    }
    
    func play() {
        guard let player = player, player.currentItem != nil else {
            print("Error: No video loaded")
            return
        }
        
        player.play()
        print("Playback started at \(playbackSpeed)x speed")
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        guard let player = player else { return }
        
        // Validate speed between 0.25 and 2.0
        let validatedSpeed = max(0.25, min(speed, 2.0))
        playbackSpeed = validatedSpeed
        
        // Set playback rate
        player.rate = validatedSpeed
        
        print("Playback speed set to \(validatedSpeed)x")
    }
    
    func setLooping(_ shouldLoop: Bool) {
        isLooping = shouldLoop
        
        // If we have a loaded video, reload it with new looping setting
        if let url = videoURL {
            loadVideo(from: url)
        }
    }
    
    @objc private func playerDidFinishPlaying(notification: Notification) {
        if isLooping {
            // If looping, restart from beginning
            player?.seek(to: .zero)
            player?.play()
        }
    }
    
    // MARK: - Cleanup Methods
    
    func cleanup() {
        // Remove observation
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Stop and clean up player
        player?.pause()
        playerLooper = nil
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
    }
    
    deinit {
        cleanup()
    }
}