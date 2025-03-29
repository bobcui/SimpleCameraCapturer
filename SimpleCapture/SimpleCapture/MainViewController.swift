import UIKit
import AVFoundation

class MainViewController: UIViewController {
    
    // UI Elements
    private let cameraView = UIView()
    private let controlsContainer = UIView()
    private let recordButton = UIButton(type: .system)
    private let switchCameraButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let playerView = UIView()
    private let speedSlider = UISlider()
    private let speedLabel = UILabel()
    private let currentSpeedLabel = UILabel()
    private let timerLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // Managers
    private let cameraManager = CameraManager()
    private let recorderManager = RecorderManager()
    private let playerManager = VideoPlayerManager()
    
    // State variables
    private var isRecording = false
    private var isInPlaybackMode = false
    private var currentPlaybackSpeed: Float = 0.5 // Default 0.5x
    private var currentFrameRate: Int = 60 // Default 60 FPS
    private var currentDuration: Int = 10 // Default 10 seconds
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupCallbacks()
        
        // Initialize with default settings
        recorderManager.setFrameRate(currentFrameRate)
        recorderManager.setDuration(currentDuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Initialize camera when view appears
        initializeCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean up when view disappears
        if isRecording {
            stopRecording()
        }
        
        cameraManager.stopCamera()
        playerManager.cleanup()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Camera view
        cameraView.backgroundColor = .black
        
        // Player view (initially hidden)
        playerView.backgroundColor = .black
        playerView.isHidden = true
        
        // Timer label
        timerLabel.textColor = .white
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold)
        timerLabel.text = "00:00.00"
        timerLabel.isHidden = true
        
        // Record button
        recordButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        recordButton.tintColor = .systemRed
        recordButton.contentHorizontalAlignment = .fill
        recordButton.contentVerticalAlignment = .fill
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        
        // Switch camera button
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.addTarget(self, action: #selector(switchCameraTapped), for: .touchUpInside)
        
        // Settings button
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        
        // Controls container
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Playback controls (initially hidden)
        speedSlider.minimumValue = 0.25
        speedSlider.maximumValue = 2.0
        speedSlider.value = 0.5 // Default 0.5x
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedSlider.isHidden = true
        
        speedLabel.text = "Playback Speed"
        speedLabel.textColor = .white
        speedLabel.textAlignment = .center
        speedLabel.isHidden = true
        
        currentSpeedLabel.text = "0.5x"
        currentSpeedLabel.textColor = .white
        currentSpeedLabel.textAlignment = .center
        currentSpeedLabel.isHidden = true
        
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        playButton.isHidden = true
        
        backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isHidden = true
        
        saveButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        saveButton.tintColor = .white
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.isHidden = true
        
        // Activity indicator
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        
        // Add subviews
        view.addSubview(cameraView)
        view.addSubview(playerView)
        view.addSubview(controlsContainer)
        controlsContainer.addSubview(recordButton)
        controlsContainer.addSubview(switchCameraButton)
        controlsContainer.addSubview(settingsButton)
        view.addSubview(timerLabel)
        view.addSubview(speedSlider)
        view.addSubview(speedLabel)
        view.addSubview(currentSpeedLabel)
        view.addSubview(playButton)
        view.addSubview(backButton)
        view.addSubview(saveButton)
        view.addSubview(activityIndicator)
    }
    
    private func setupConstraints() {
        // Enable autolayout
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        playerView.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        currentSpeedLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Camera view (full screen)
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Player view (full screen)
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Controls container (at bottom)
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Record button (centered in controls)
            recordButton.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 70),
            recordButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Switch camera button (left of record)
            switchCameraButton.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 30),
            switchCameraButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 40),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Settings button (right of record)
            settingsButton.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -30),
            settingsButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Timer label (top center)
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Speed label (above slider)
            speedLabel.bottomAnchor.constraint(equalTo: speedSlider.topAnchor, constant: -10),
            speedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Speed slider (above controls)
            speedSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            speedSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            speedSlider.bottomAnchor.constraint(equalTo: controlsContainer.topAnchor, constant: -40),
            
            // Current speed label (above slider)
            currentSpeedLabel.topAnchor.constraint(equalTo: speedSlider.bottomAnchor, constant: 10),
            currentSpeedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Play button (center in controls during playback)
            playButton.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Back button (top left)
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Save button (top right)
            saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 40),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Activity indicator (center)
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCallbacks() {
        // Set up recorder callbacks
        recorderManager.onRecordingComplete = { [weak self] result in
            guard let self = self else { return }
            
            self.isRecording = false
            self.updateRecordButtonForState()
            self.timerLabel.isHidden = true
            
            switch result {
            case .success(let videoURL):
                print("Recording completed successfully: \(videoURL.lastPathComponent)")
                self.enterPlaybackMode(with: videoURL)
                
            case .failure(let error):
                print("Recording failed: \(error.localizedDescription)")
                self.showAlert(title: "Recording Failed", message: error.localizedDescription)
            }
        }
        
        recorderManager.onTimerUpdate = { [weak self] remainingTimeMs in
            guard let self = self else { return }
            
            // Format time as MM:SS.hh
            let seconds = remainingTimeMs / 1000
            let milliseconds = (remainingTimeMs % 1000) / 10
            let timeString = String(format: "%02d:%02d.%02d", seconds / 60, seconds % 60, milliseconds)
            
            DispatchQueue.main.async {
                self.timerLabel.text = timeString
            }
        }
    }
    
    // MARK: - Camera Initialization
    
    private func initializeCamera() {
        activityIndicator.startAnimating()
        
        // Initialize camera with appropriate frame rate
        cameraManager.initialize(preferredFrameRate: currentFrameRate) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success:
                    print("Camera initialized successfully")
                    // Set up preview layer
                    if let previewLayer = self.cameraManager.getPreviewLayer() {
                        previewLayer.frame = self.cameraView.bounds
                        self.cameraView.layer.addSublayer(previewLayer)
                    }
                    
                case .failure(let error):
                    print("Camera initialization failed: \(error.localizedDescription)")
                    self.showAlert(title: "Camera Error", message: error.localizedDescription)
                    
                    // If we failed with high frame rate, try falling back to standard frame rate
                    if self.currentFrameRate > 60 {
                        self.currentFrameRate = 60
                        self.recorderManager.setFrameRate(60)
                        
                        // Try again with lower frame rate
                        self.initializeCamera()
                    }
                }
            }
        }
    }
    
    // MARK: - Recording
    
    private func startRecording() {
        guard let session = cameraManager.getCaptureSession() else {
            showAlert(title: "Cannot Record", message: "Camera not initialized properly.")
            return
        }
        
        isRecording = true
        updateRecordButtonForState()
        timerLabel.isHidden = false
        
        // Start recording
        recorderManager.startRecording(captureSession: session)
    }
    
    private func stopRecording() {
        isRecording = false
        updateRecordButtonForState()
        timerLabel.isHidden = true
        recorderManager.stopRecording()
    }
    
    private func updateRecordButtonForState() {
        if isRecording {
            recordButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        } else {
            recordButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        }
    }
    
    // MARK: - Playback
    
    private func enterPlaybackMode(with videoURL: URL) {
        isInPlaybackMode = true
        
        // Hide camera UI
        cameraView.isHidden = true
        recordButton.isHidden = true
        switchCameraButton.isHidden = true
        settingsButton.isHidden = true
        
        // Show playback UI
        playerView.isHidden = false
        speedSlider.isHidden = false
        speedLabel.isHidden = false
        currentSpeedLabel.isHidden = false
        playButton.isHidden = false
        backButton.isHidden = false
        saveButton.isHidden = false
        
        // Stop camera to free up resources
        cameraManager.stopCamera()
        
        // Setup player
        playerManager.setupPlayerInView(playerView)
        playerManager.loadVideo(from: videoURL)
        playerManager.setPlaybackSpeed(currentPlaybackSpeed)
        playerManager.play()
        
        // Update UI
        updatePlayButtonForState()
    }
    
    private func exitPlaybackMode() {
        isInPlaybackMode = false
        
        // Show camera UI
        cameraView.isHidden = false
        recordButton.isHidden = false
        switchCameraButton.isHidden = false
        settingsButton.isHidden = false
        
        // Hide playback UI
        playerView.isHidden = true
        speedSlider.isHidden = true
        speedLabel.isHidden = true
        currentSpeedLabel.isHidden = true
        playButton.isHidden = true
        backButton.isHidden = true
        saveButton.isHidden = true
        
        // Clean up player
        playerManager.cleanup()
        
        // Reinitialize camera
        initializeCamera()
    }
    
    private func updatePlayButtonForState() {
        // Update play/pause button
        let isPaused = playButton.tag == 0
        
        if isPaused {
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    // MARK: - Saving Video
    
    private func saveVideoToPhotoLibrary(from sourceURL: URL) {
        activityIndicator.startAnimating()
        
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: sourceURL, options: nil)
                }) { success, error in
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        
                        if success {
                            self.showAlert(title: "Success", message: "Video saved to Photo Library")
                        } else {
                            self.showAlert(title: "Error", message: "Could not save video: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Cannot Save Video", message: "Photo Library access is not authorized")
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func recordTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc private func switchCameraTapped() {
        // Don't allow camera switch during recording
        if isRecording { return }
        
        activityIndicator.startAnimating()
        
        cameraManager.switchCamera { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                if let error = error {
                    self.showAlert(title: "Camera Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func settingsTapped() {
        // Don't allow settings during recording
        if isRecording { return }
        
        let settingsPanel = SettingsPanel()
        settingsPanel.frameRate = currentFrameRate
        settingsPanel.recordingDuration = currentDuration
        
        settingsPanel.onSave = { [weak self] frameRate, duration in
            guard let self = self else { return }
            
            // Only reinitialize camera if frame rate changed
            let frameRateChanged = self.currentFrameRate != frameRate
            
            self.currentFrameRate = frameRate
            self.currentDuration = duration
            
            self.recorderManager.setFrameRate(frameRate)
            self.recorderManager.setDuration(duration)
            
            if frameRateChanged {
                // Reinitialize camera with new frame rate
                self.initializeCamera()
            }
        }
        
        settingsPanel.modalPresentationStyle = .formSheet
        present(settingsPanel, animated: true)
    }
    
    @objc private func speedChanged(_ sender: UISlider) {
        currentPlaybackSpeed = sender.value
        currentSpeedLabel.text = String(format: "%.2fx", currentPlaybackSpeed)
        playerManager.setPlaybackSpeed(currentPlaybackSpeed)
    }
    
    @objc private func playTapped() {
        let isPaused = playButton.tag == 0
        
        if isPaused {
            // Currently paused, so play
            playerManager.play()
            playButton.tag = 1
        } else {
            // Currently playing, so pause
            playerManager.pause()
            playButton.tag = 0
        }
        
        updatePlayButtonForState()
    }
    
    @objc private func backTapped() {
        exitPlaybackMode()
    }
    
    @objc private func saveTapped() {
        if let videoURL = cameraManager.getLastRecordedVideoURL() {
            saveVideoToPhotoLibrary(from: videoURL)
        } else {
            showAlert(title: "Cannot Save", message: "No video available to save")
        }
    }
    
    // MARK: - Utility Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIViewController Extensions

extension MainViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}