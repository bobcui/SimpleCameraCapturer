import UIKit
import AVFoundation

class VideoPlayerManager: NSObject {
    // Playback properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoURL: URL?
    private var playbackRate: Float = 0.5
    private var timeObserver: Any?
    
    // UI elements
    weak var playerView: UIView?
    weak var statusLabel: UILabel?
    weak var timeLabel: UILabel?
    weak var speedLabel: UILabel?
    weak var speedSlider: UISlider?
    weak var playbackControlsView: UIView?
    
    // Delegate
    weak var delegate: VideoPlayerDelegate?
    
    func setupPlayerView(_ view: UIView) {
        playerView = view
    }
    
    func loadVideo(url: URL) {
        // Stop any existing playback
        stopPlayback()
        
        videoURL = url
        player = AVPlayer(url: url)
        
        // Create player layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerView = playerView, let playerLayer = playerLayer {
            playerLayer.frame = playerView.bounds
            playerView.layer.addSublayer(playerLayer)
        }
        
        // Set playback rate
        updatePlaybackRate(playbackRate)
        
        // Add time observer
        addTimeObserver()
        
        // Show controls
        playbackControlsView?.isHidden = false
        
        // Update UI
        statusLabel?.text = "Replaying"
        statusLabel?.isHidden = false
        speedLabel?.text = "\(playbackRate)x"
        speedSlider?.value = playbackRate
        
        // Start playback with looping
        startPlayback()
        
        // Add notification for playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        updatePlaybackRate(rate)
        speedLabel?.text = "\(rate)x"
    }
    
    private func updatePlaybackRate(_ rate: Float) {
        player?.rate = rate
    }
    
    func startPlayback() {
        player?.play()
    }
    
    func stopPlayback() {
        player?.pause()
        
        // Remove time observer
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Remove player layer
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        // Reset player
        player = nil
        
        // Hide UI elements
        statusLabel?.isHidden = true
        playbackControlsView?.isHidden = true
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Notify delegate
        delegate?.playerDidStopPlayback()
    }
    
    private func addTimeObserver() {
        // Create a time observer that updates every 0.1 seconds
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            self?.updateTimeLabel(time)
        }
    }
    
    private func updateTimeLabel(_ time: CMTime) {
        guard let player = player, let duration = player.currentItem?.duration else {
            return
        }
        
        let seconds = CMTimeGetSeconds(time)
        let totalSeconds = CMTimeGetSeconds(duration)
        
        // Don't update if time is invalid
        if seconds.isNaN || totalSeconds.isNaN { return }
        
        let minutes = Int(seconds / 60)
        let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((seconds - Double(Int(seconds))) * 100)
        
        timeLabel?.text = String(format: "%02d:%02d.%02d", minutes, remainingSeconds, milliseconds)
    }
    
    @objc private func playerDidFinishPlaying(notification: Notification) {
        // Loop playback
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
    func cleanup() {
        stopPlayback()
        videoURL = nil
    }
}

// Protocol for player events
protocol VideoPlayerDelegate: AnyObject {
    func playerDidStopPlayback()
}