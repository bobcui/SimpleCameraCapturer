/**
 * Player module - handles video playback with speed controls
 */
class Player {
    constructor() {
        this.videoElement = document.getElementById('playback-view');
        this.cameraView = document.getElementById('camera-view');
        this.playbackControls = document.getElementById('playback-controls');
        this.speedControl = document.getElementById('speed-control');
        this.speedValue = document.getElementById('speed-value');
        this.statusIndicator = document.getElementById('status-indicator');
        this.timerDisplay = document.getElementById('timer-display');
        this.timerInterval = null;
        this.videoBlob = null;
        this.playbackSpeed = 0.5; // Default playback speed (0.5x)
        
        // Set up speed control event listener
        this.speedControl.addEventListener('input', this.handleSpeedChange.bind(this));
    }

    /**
     * Load a video blob for playback
     * @param {Blob} videoBlob - The recorded video blob
     */
    loadVideo(videoBlob) {
        this.videoBlob = videoBlob;
        const videoURL = URL.createObjectURL(videoBlob);
        this.videoElement.src = videoURL;
        
        // Set playback speed
        this.videoElement.playbackRate = this.playbackSpeed;
        
        // Hide camera view, show playback
        this.cameraView.classList.add('hidden');
        this.videoElement.classList.remove('hidden');
        this.playbackControls.classList.remove('hidden');
        
        // Set up playback status
        this.statusIndicator.textContent = 'Replaying';
        this.statusIndicator.classList.remove('hidden');
        
        // Start playing
        this.videoElement.play().catch(error => {
            console.error('Error playing video:', error);
            alert('Could not play the recorded video. Please try again.');
        });
        
        // Set up timers and events
        this.startPlaybackTimer();
        this.videoElement.addEventListener('ended', this.onVideoEnded.bind(this));
    }

    /**
     * Handle playback speed change
     */
    handleSpeedChange() {
        this.playbackSpeed = parseFloat(this.speedControl.value);
        this.speedValue.textContent = `${this.playbackSpeed}x`;
        
        if (this.videoElement) {
            this.videoElement.playbackRate = this.playbackSpeed;
        }
    }

    /**
     * Start the playback timer to show current time
     */
    startPlaybackTimer() {
        // Clear any existing timer
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
        }
        
        this.timerInterval = setInterval(() => {
            if (this.videoElement.paused || this.videoElement.ended) {
                return;
            }
            
            const currentTime = this.videoElement.currentTime;
            const minutes = Math.floor(currentTime / 60);
            const seconds = Math.floor(currentTime % 60);
            const milliseconds = Math.floor((currentTime % 1) * 100);
            
            this.timerDisplay.textContent = 
                `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}.${milliseconds.toString().padStart(2, '0')}`;
        }, 50);
    }

    /**
     * Handle video end event (loop playback)
     */
    onVideoEnded() {
        // Video will loop automatically due to the 'loop' attribute
        console.log('Video playback looped');
    }

    /**
     * Stop playback and clean up
     */
    stopPlayback() {
        if (this.videoElement) {
            this.videoElement.pause();
            this.videoElement.removeEventListener('ended', this.onVideoEnded);
            
            if (this.videoElement.src) {
                URL.revokeObjectURL(this.videoElement.src);
                this.videoElement.src = '';
            }
        }
        
        // Clear timer
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
        
        // Hide playback elements
        this.videoElement.classList.add('hidden');
        this.playbackControls.classList.add('hidden');
        this.statusIndicator.classList.add('hidden');
        
        // Show camera view
        this.cameraView.classList.remove('hidden');
        
        // Reset timer display
        this.timerDisplay.textContent = '00:00';
        
        this.videoBlob = null;
    }

    /**
     * Check if playback is currently active
     * @returns {boolean} True if video is currently playing
     */
    isPlaying() {
        return !this.videoElement.paused && !this.videoElement.ended && 
               this.videoElement.readyState > 2 && !this.videoElement.classList.contains('hidden');
    }
}

// Export the Player class
window.Player = Player;
