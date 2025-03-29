/**
 * Camera module - handles camera initialization, switching, and constraints
 */
class Camera {
    constructor() {
        this.stream = null;
        this.facingMode = 'environment'; // Start with back camera
        this.videoElement = document.getElementById('camera-view');
        this.constraints = {
            video: {
                facingMode: this.facingMode,
                width: { ideal: 1920 },
                height: { ideal: 1080 }
            },
            audio: false // No audio as per requirements
        };
        
        // Check for camera support
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            alert('Your browser does not support camera access. Please use a modern browser.');
            return;
        }
    }

    /**
     * Initialize the camera and get the stream
     */
    async initialize() {
        try {
            // Check if running in a secure context (needed for camera APIs)
            if (!window.isSecureContext) {
                console.warn('Camera access requires a secure context (HTTPS)');
                throw new Error('Camera access requires a secure context (HTTPS)');
            }
            
            // Check if we have the necessary APIs
            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                console.warn('MediaDevices API not available in this browser');
                throw new Error('Your browser does not support camera access');
            }
            
            // First try to enumerate devices to check if there are cameras
            const devices = await navigator.mediaDevices.enumerateDevices();
            const videoDevices = devices.filter(device => device.kind === 'videoinput');
            
            if (videoDevices.length === 0) {
                console.warn('No video input devices found');
                throw new Error('No camera detected on this device');
            }
            
            console.log(`Found ${videoDevices.length} camera(s)`);
            
            // Try to get camera permission with more specific constraints
            const constraints = {
                video: {
                    facingMode: this.facingMode,
                    width: { ideal: 1280 }, // Lower resolution for better compatibility
                    height: { ideal: 720 }
                },
                audio: false
            };
            
            this.stream = await navigator.mediaDevices.getUserMedia(constraints);
            this.videoElement.srcObject = this.stream;
            
            // Get device capabilities
            const track = this.stream.getVideoTracks()[0];
            const capabilities = track.getCapabilities();
            
            console.log('Camera capabilities:', capabilities);
            
            // Set high frame rate if supported
            if (capabilities.frameRate && capabilities.frameRate.max >= 60) {
                const settings = track.getSettings();
                console.log('Current settings:', settings);
                
                try {
                    await track.applyConstraints({
                        frameRate: { ideal: 60, min: 30 }
                    });
                    console.log('Applied high frame rate constraints');
                } catch (err) {
                    console.warn('Could not apply frame rate constraint:', err);
                }
            }
            
            return true;
        } catch (error) {
            console.error('Error accessing camera:', error);
            
            // Provide helpful error messages based on error type
            if (error.name === 'NotAllowedError') {
                alert('Camera access denied. Please allow camera access in your browser settings to use this app.');
            } else if (error.name === 'NotFoundError') {
                alert('No camera found on this device, or the camera is already in use by another application.');
            } else if (error.name === 'NotReadableError') {
                alert('Camera hardware error. Please try refreshing the page or restarting your device.');
            } else {
                alert(`Camera access error: ${error.message}`);
            }
            
            return false;
        }
    }

    /**
     * Switch between front and back cameras
     */
    async switchCamera() {
        // Toggle facing mode
        this.facingMode = this.facingMode === 'environment' ? 'user' : 'environment';
        
        // Stop all tracks in the current stream
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }
        
        // Update constraints
        this.constraints.video.facingMode = this.facingMode;
        
        // Re-initialize camera with new constraints
        return await this.initialize();
    }

    /**
     * Stop all camera tracks
     */
    stop() {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
            this.stream = null;
        }
    }

    /**
     * Get the current video stream
     * @returns {MediaStream} The current stream
     */
    getStream() {
        return this.stream;
    }

    /**
     * Try to set a specific frame rate for recording
     * @param {number} fps - The desired frames per second
     */
    async setFrameRate(fps) {
        if (!this.stream) return false;
        
        const videoTrack = this.stream.getVideoTracks()[0];
        if (!videoTrack) return false;
        
        try {
            await videoTrack.applyConstraints({
                frameRate: { ideal: fps }
            });
            console.log(`Set frame rate to ideal: ${fps} FPS`);
            return true;
        } catch (error) {
            console.warn(`Unable to set ${fps} FPS:`, error);
            return false;
        }
    }
}

// Export the Camera class
window.Camera = Camera;
