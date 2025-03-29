/**
 * Recorder module - handles video recording functionality
 */
class Recorder {
    constructor() {
        this.mediaRecorder = null;
        this.recordedChunks = [];
        this.recordingDuration = 10000; // Default 10 seconds in ms
        this.isRecording = false;
        this.timerInterval = null;
        this.timerDisplay = document.getElementById('timer-display');
        this.statusIndicator = document.getElementById('status-indicator');
        this.startTime = 0;
        this.fps = 120; // Default FPS setting
    }

    /**
     * Start recording from the provided stream
     * @param {MediaStream} stream - The media stream to record
     * @returns {Promise} Resolves when recording is complete
     */
    startRecording(stream) {
        if (!stream) {
            console.error('No stream provided for recording');
            return Promise.reject('No camera stream available');
        }
        
        if (this.isRecording) {
            console.warn('Already recording');
            return Promise.reject('Already recording');
        }
        
        this.recordedChunks = [];
        this.isRecording = true;
        
        // Show recording status
        this.statusIndicator.textContent = 'Recording';
        this.statusIndicator.classList.remove('hidden');
        
        // Set up media recorder with appropriate MIME type and quality
        const options = { 
            mimeType: 'video/webm;codecs=vp9', 
            videoBitsPerSecond: 8000000 // 8 Mbps for high quality
        };
        
        try {
            this.mediaRecorder = new MediaRecorder(stream, options);
        } catch (e) {
            // Fallback if vp9 not supported
            try {
                const fallbackOptions = { 
                    mimeType: 'video/webm', 
                    videoBitsPerSecond: 8000000
                };
                this.mediaRecorder = new MediaRecorder(stream, fallbackOptions);
            } catch (e) {
                console.error("MediaRecorder is not supported by this browser:", e);
                this.isRecording = false;
                this.statusIndicator.classList.add('hidden');
                return Promise.reject("Cannot create MediaRecorder: " + e.message);
            }
        }
        
        // Set up event handlers
        this.mediaRecorder.ondataavailable = (event) => {
            if (event.data && event.data.size > 0) {
                this.recordedChunks.push(event.data);
            }
        };
        
        // Start the timer
        this.startTimer();
        
        // Start the recorder
        this.mediaRecorder.start(100); // Capture in 100ms chunks
        this.startTime = Date.now();
        
        // Return a promise that resolves when recording completes
        return new Promise((resolve) => {
            this.mediaRecorder.onstop = () => {
                this.isRecording = false;
                this.statusIndicator.classList.add('hidden');
                clearInterval(this.timerInterval);
                
                // Create a blob from the recorded chunks
                const blob = new Blob(this.recordedChunks, { type: 'video/webm' });
                resolve(blob);
            };
            
            // Stop recording after the specified duration
            setTimeout(() => {
                if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
                    this.mediaRecorder.stop();
                }
            }, this.recordingDuration);
        });
    }

    /**
     * Force stop the current recording
     */
    stopRecording() {
        if (this.mediaRecorder && this.isRecording) {
            this.mediaRecorder.stop();
            this.isRecording = false;
            clearInterval(this.timerInterval);
            this.statusIndicator.classList.add('hidden');
        }
    }

    /**
     * Start the countdown timer
     */
    startTimer() {
        const startTime = Date.now();
        const endTime = startTime + this.recordingDuration;
        
        // Update timer immediately
        this.updateTimerDisplay(endTime - Date.now());
        
        // Update timer every 100ms
        this.timerInterval = setInterval(() => {
            const remaining = endTime - Date.now();
            
            if (remaining <= 0) {
                clearInterval(this.timerInterval);
                this.timerDisplay.textContent = '00:00';
                return;
            }
            
            this.updateTimerDisplay(remaining);
        }, 100);
    }

    /**
     * Update the timer display with the remaining time
     * @param {number} timeInMs - Remaining time in milliseconds
     */
    updateTimerDisplay(timeInMs) {
        const seconds = Math.floor(timeInMs / 1000);
        const milliseconds = Math.floor((timeInMs % 1000) / 10);
        
        this.timerDisplay.textContent = 
            `${seconds.toString().padStart(2, '0')}:${milliseconds.toString().padStart(2, '0')}`;
    }

    /**
     * Set the recording duration
     * @param {number} seconds - Duration in seconds
     */
    setDuration(seconds) {
        this.recordingDuration = seconds * 1000;
    }
    
    /**
     * Set the desired frame rate for recording
     * @param {number} fps - Frames per second
     */
    setFrameRate(fps) {
        this.fps = fps;
    }

    /**
     * Check if recording is currently in progress
     * @returns {boolean} True if recording is active
     */
    isActive() {
        return this.isRecording;
    }
}

// Export the Recorder class
window.Recorder = Recorder;
