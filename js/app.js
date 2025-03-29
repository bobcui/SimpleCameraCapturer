/**
 * SimpleCapture - Main Application
 * An app for recording and playing back high-quality slow-motion videos
 */
document.addEventListener('DOMContentLoaded', () => {
    // Main application elements
    const recordButton = document.getElementById('record-button');
    const switchCameraButton = document.getElementById('switch-camera');
    const settingsButton = document.getElementById('settings-button');
    const settingsPanel = document.getElementById('settings-panel');
    const closeSettingsButton = document.getElementById('close-settings');
    const durationSelect = document.getElementById('duration-select');
    const fpsSelect = document.getElementById('fps-select');
    
    // Initialize modules
    const camera = new Camera();
    const recorder = new Recorder();
    const player = new Player();
    
    // Application state
    let appState = 'initializing'; // initializing, ready, recording, playback
    
    // Initialize camera on load
    initializeCamera();
    
    // Set up event listeners
    recordButton.addEventListener('click', handleRecordButton);
    switchCameraButton.addEventListener('click', handleCameraSwitch);
    settingsButton.addEventListener('click', toggleSettings);
    closeSettingsButton.addEventListener('click', toggleSettings);
    durationSelect.addEventListener('change', updateSettings);
    fpsSelect.addEventListener('change', updateSettings);
    
    // Add portrait orientation lock if supported
    if (screen.orientation && typeof screen.orientation.lock === 'function') {
        screen.orientation.lock('portrait').catch(e => {
            console.log('Orientation lock not supported:', e);
        });
    } else {
        console.log('Screen orientation API not supported on this device');
    }
    
    /**
     * Initialize the camera
     */
    async function initializeCamera() {
        try {
            const success = await camera.initialize();
            if (success) {
                appState = 'ready';
                console.log('Camera initialized successfully');
                
                // Apply initial settings
                updateSettings();
            } else {
                console.warn('Camera initialization failed - running in limited mode');
                
                // Set app to a special state that shows the UI but disables recording
                appState = 'limited';
                
                // Add a notification to the UI
                const statusIndicator = document.getElementById('status-indicator');
                statusIndicator.textContent = 'Camera Unavailable';
                statusIndicator.style.color = '#ffcc00';
                statusIndicator.classList.remove('hidden');
                
                // Disable buttons that require camera access
                recordButton.disabled = true;
                recordButton.style.opacity = 0.5;
                switchCameraButton.disabled = true;
                switchCameraButton.style.opacity = 0.5;
                
                // Show an informative message
                setTimeout(() => {
                    alert('SimpleCapture is running in limited mode. Camera access is not available in this environment.\n\nOn a real iOS device, you would be able to record and play back videos.');
                }, 500);
            }
        } catch (error) {
            console.error('Camera initialization error:', error);
            alert('Camera error: ' + error.message);
        }
    }
    
    /**
     * Handle record button press
     */
    async function handleRecordButton() {
        if (appState === 'ready') {
            // Start recording
            startRecording();
        } else if (appState === 'recording') {
            // Do nothing while recording - wait for auto-stop
            console.log('Recording in progress, please wait...');
        } else if (appState === 'playback') {
            // Stop playback and return to camera mode
            player.stopPlayback();
            appState = 'ready';
            recordButton.classList.remove('recording');
        }
    }
    
    /**
     * Start recording process
     */
    async function startRecording() {
        try {
            // Update UI to recording state
            appState = 'recording';
            recordButton.classList.add('recording');
            switchCameraButton.disabled = true; // Disable camera switching during recording
            
            // Start recording with current stream
            const videoBlob = await recorder.startRecording(camera.getStream());
            
            // When recording finishes, switch to playback
            startPlayback(videoBlob);
            
            // Re-enable camera switching
            switchCameraButton.disabled = false;
        } catch (error) {
            console.error('Recording error:', error);
            alert('Recording error: ' + error);
            appState = 'ready';
            recordButton.classList.remove('recording');
            switchCameraButton.disabled = false;
        }
    }
    
    /**
     * Start playback of the recorded video
     * @param {Blob} videoBlob - The recorded video blob
     */
    function startPlayback(videoBlob) {
        if (!videoBlob) {
            console.error('No video data to play');
            appState = 'ready';
            return;
        }
        
        appState = 'playback';
        player.loadVideo(videoBlob);
    }
    
    /**
     * Handle camera switch button
     */
    async function handleCameraSwitch() {
        if (appState !== 'ready') {
            console.log('Cannot switch camera while recording or playing');
            return;
        }
        
        try {
            await camera.switchCamera();
            console.log('Camera switched');
            
            // Reapply current settings
            updateSettings();
        } catch (error) {
            console.error('Error switching camera:', error);
            alert('Could not switch camera: ' + error.message);
        }
    }
    
    /**
     * Toggle settings panel visibility
     */
    function toggleSettings() {
        settingsPanel.classList.toggle('active');
        settingsPanel.classList.toggle('hidden');
    }
    
    /**
     * Update settings from user selection
     */
    function updateSettings() {
        // Update recording duration
        const duration = parseInt(durationSelect.value, 10);
        recorder.setDuration(duration);
        console.log(`Recording duration set to ${duration} seconds`);
        
        // Update frame rate
        const fps = parseInt(fpsSelect.value, 10);
        recorder.setFrameRate(fps);
        camera.setFrameRate(fps).then(success => {
            if (success) {
                console.log(`Frame rate set to ${fps} FPS`);
            } else {
                console.warn(`Device may not support ${fps} FPS recording`);
            }
        });
    }
    
    /**
     * Handle visibility change to manage camera resources
     */
    document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
            // App is in background
            if (appState === 'recording') {
                // If recording, force stop
                recorder.stopRecording();
                appState = 'ready';
                recordButton.classList.remove('recording');
            }
        } else {
            // App is visible again, reinitialize camera if needed
            if (appState === 'ready' && !camera.getStream()) {
                initializeCamera();
            }
        }
    });
    
    /**
     * Handle page unload to clean up resources
     */
    window.addEventListener('beforeunload', () => {
        camera.stop();
        if (appState === 'recording') {
            recorder.stopRecording();
        }
        if (appState === 'playback') {
            player.stopPlayback();
        }
    });
});
