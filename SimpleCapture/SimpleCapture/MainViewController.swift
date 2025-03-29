import UIKit
import AVFoundation

class MainViewController: UIViewController {
    // Managers
    private var cameraManager: CameraManager!
    private var recorderManager: RecorderManager!
    private var playerManager: VideoPlayerManager!
    private var settingsManager: SettingsManager!
    
    // UI Elements
    private var cameraView: UIView!
    private var playerView: UIView!
    private var statusLabel: UILabel!
    private var timerLabel: UILabel!
    private var recordButton: UIButton!
    private var switchCameraButton: UIButton!
    private var settingsButton: UIButton!
    private var playbackControlsView: UIView!
    private var speedSlider: UISlider!
    private var speedLabel: UILabel!
    private var settingsPanel: SettingsPanel!
    
    // Application state
    private enum AppState {
        case initializing, ready, recording, playback
    }
    private var appState: AppState = .initializing
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupManagers()
        
        // Request camera permissions
        checkCameraPermissions()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup header
        let headerView = UIView()
        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.addSubview(headerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "SimpleCapture"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Record and playback high-quality slow-motion videos"
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textAlignment = .center
        headerView.addSubview(subtitleLabel)
        
        // Setup camera view
        cameraView = UIView()
        cameraView.backgroundColor = .black
        view.addSubview(cameraView)
        
        // Setup player view (initially hidden)
        playerView = UIView()
        playerView.backgroundColor = .black
        playerView.isHidden = true
        view.addSubview(playerView)
        
        // Status and timer
        let statusContainer = UIView()
        statusContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusContainer.layer.cornerRadius = 15
        view.addSubview(statusContainer)
        
        statusLabel = UILabel()
        statusLabel.text = "Recording"
        statusLabel.textColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // #FF3B30
        statusLabel.font = UIFont.boldSystemFont(ofSize: 16)
        statusLabel.isHidden = true
        statusContainer.addSubview(statusLabel)
        
        timerLabel = UILabel()
        timerLabel.text = "00:00"
        timerLabel.textColor = .white
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        statusContainer.addSubview(timerLabel)
        
        // Playback controls
        playbackControlsView = UIView()
        playbackControlsView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        playbackControlsView.isHidden = true
        view.addSubview(playbackControlsView)
        
        let speedTitleLabel = UILabel()
        speedTitleLabel.text = "Playback Speed:"
        speedTitleLabel.textColor = .white
        speedTitleLabel.font = UIFont.systemFont(ofSize: 14)
        playbackControlsView.addSubview(speedTitleLabel)
        
        speedLabel = UILabel()
        speedLabel.text = "0.5x"
        speedLabel.textColor = .white
        speedLabel.font = UIFont.systemFont(ofSize: 14)
        playbackControlsView.addSubview(speedLabel)
        
        speedSlider = UISlider()
        speedSlider.minimumValue = 0.25
        speedSlider.maximumValue = 2.0
        speedSlider.value = 0.5
        speedSlider.addTarget(self, action: #selector(speedSliderChanged(_:)), for: .valueChanged)
        playbackControlsView.addSubview(speedSlider)
        
        // Control buttons
        let controlsContainer = UIView()
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.addSubview(controlsContainer)
        
        switchCameraButton = UIButton(type: .system)
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.addTarget(self, action: #selector(switchCameraPressed), for: .touchUpInside)
        controlsContainer.addSubview(switchCameraButton)
        
        recordButton = UIButton(type: .custom)
        recordButton.backgroundColor = .white
        recordButton.layer.cornerRadius = 35
        recordButton.addTarget(self, action: #selector(recordButtonPressed), for: .touchUpInside)
        controlsContainer.addSubview(recordButton)
        
        let recordIcon = UIView()
        recordIcon.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // #FF3B30
        recordIcon.layer.cornerRadius = 27
        recordButton.addSubview(recordIcon)
        
        settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
        controlsContainer.addSubview(settingsButton)
        
        // Settings panel
        settingsPanel = SettingsPanel()
        settingsPanel.delegate = self
        settingsPanel.isHidden = true
        view.addSubview(settingsPanel)
        
        // Layout constraints
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        playerView.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        playbackControlsView.translatesAutoresizingMaskIntoConstraints = false
        speedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordIcon.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            // Camera View
            cameraView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Player View
            playerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.heightAnchor.constraint(equalTo: cameraView.heightAnchor),
            
            // Status Container
            statusContainer.topAnchor.constraint(equalTo: cameraView.topAnchor, constant: 10),
            statusContainer.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor, constant: 10),
            statusContainer.heightAnchor.constraint(equalToConstant: 30),
            
            // Status Label
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            
            // Timer Label
            timerLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 10),
            timerLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -10),
            timerLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            
            // Playback Controls
            playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playbackControlsView.heightAnchor.constraint(equalToConstant: 60),
            
            speedTitleLabel.topAnchor.constraint(equalTo: playbackControlsView.topAnchor, constant: 10),
            speedTitleLabel.centerXAnchor.constraint(equalTo: playbackControlsView.centerXAnchor, constant: -30),
            
            speedLabel.centerYAnchor.constraint(equalTo: speedTitleLabel.centerYAnchor),
            speedLabel.leadingAnchor.constraint(equalTo: speedTitleLabel.trailingAnchor, constant: 5),
            
            speedSlider.topAnchor.constraint(equalTo: speedTitleLabel.bottomAnchor, constant: 5),
            speedSlider.leadingAnchor.constraint(equalTo: playbackControlsView.leadingAnchor, constant: 40),
            speedSlider.trailingAnchor.constraint(equalTo: playbackControlsView.trailingAnchor, constant: -40),
            
            // Controls Container
            controlsContainer.topAnchor.constraint(equalTo: playbackControlsView.bottomAnchor),
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Control Buttons
            switchCameraButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            switchCameraButton.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 60),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 44),
            
            recordButton.centerXAnchor.constraint(equalTo: controlsContainer.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 70),
            recordButton.heightAnchor.constraint(equalToConstant: 70),
            
            recordIcon.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
            recordIcon.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            recordIcon.widthAnchor.constraint(equalToConstant: 54),
            recordIcon.heightAnchor.constraint(equalToConstant: 54),
            
            settingsButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -60),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Settings Panel
            settingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            settingsPanel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        ])
        
        // Link controls and playback view
        playbackControlsView.topAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
        cameraView.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor).isActive = true
    }
    
    private func setupManagers() {
        cameraManager = CameraManager()
        
        recorderManager = RecorderManager(cameraManager: cameraManager)
        recorderManager.statusLabel = statusLabel
        recorderManager.timerLabel = timerLabel
        recorderManager.recordButton = recordButton
        recorderManager.delegate = self
        
        playerManager = VideoPlayerManager()
        playerManager.setupPlayerView(playerView)
        playerManager.statusLabel = statusLabel
        playerManager.timeLabel = timerLabel
        playerManager.speedLabel = speedLabel
        playerManager.speedSlider = speedSlider
        playerManager.playbackControlsView = playbackControlsView
        playerManager.delegate = self
        
        settingsManager = SettingsManager()
        settingsManager.delegate = self
        
        // Set initial settings on the settings panel
        settingsPanel.setup(
            durations: settingsManager.durationOptions.map { "\(Int($0)) seconds" },
            frameRates: settingsManager.frameRateOptions.map { "\($0) FPS" },
            selectedDurationIndex: settingsManager.durationOptions.firstIndex(of: settingsManager.recordingDuration) ?? 1,
            selectedFrameRateIndex: settingsManager.frameRateOptions.firstIndex(of: settingsManager.frameRate) ?? 1
        )
    }
    
    // MARK: - Permission Handling
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted
            initializeCamera()
        case .notDetermined:
            // Permission not asked yet
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.initializeCamera()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            // Permission denied
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "SimpleCapture needs camera access to record videos. Please enable it in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Camera Initialization
    
    private func initializeCamera() {
        let success = cameraManager.setupCamera(in: cameraView)
        
        if success {
            cameraManager.startSession()
            appState = .ready
            
            // Apply settings
            cameraManager.setFrameRate(fps: settingsManager.frameRate)
            recorderManager.setDuration(settingsManager.recordingDuration)
        } else {
            showCameraErrorAlert()
        }
    }
    
    private func showCameraErrorAlert() {
        let alert = UIAlertController(
            title: "Camera Error",
            message: "There was a problem accessing the camera. Please restart the app and try again.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    // MARK: - Button Actions
    
    @objc private func recordButtonPressed() {
        switch appState {
        case .ready:
            // Start recording
            appState = .recording
            recorderManager.startRecording()
        case .recording:
            // Do nothing, recording will stop automatically
            break
        case .playback:
            // Stop playback and return to camera mode
            appState = .ready
            playerManager.stopPlayback()
            cameraView.isHidden = false
            playerView.isHidden = true
        case .initializing:
            // Not ready yet
            break
        }
    }
    
    @objc private func switchCameraPressed() {
        if appState == .ready {
            let success = cameraManager.switchCamera()
            if !success {
                showCameraSwitchErrorAlert()
            }
        }
    }
    
    private func showCameraSwitchErrorAlert() {
        let alert = UIAlertController(
            title: "Camera Switch Failed",
            message: "Unable to switch cameras. The device may not have multiple cameras or there may be a hardware issue.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    @objc private func settingsButtonPressed() {
        toggleSettingsPanel()
    }
    
    private func toggleSettingsPanel() {
        UIView.animate(withDuration: 0.3) {
            if self.settingsPanel.isHidden {
                self.settingsPanel.isHidden = false
                self.settingsPanel.transform = CGAffineTransform.identity
            } else {
                self.settingsPanel.transform = CGAffineTransform(translationX: 0, y: self.settingsPanel.frame.height)
                self.settingsPanel.isHidden = true
            }
        }
    }
    
    @objc private func speedSliderChanged(_ sender: UISlider) {
        // Round to nearest 0.25
        let roundedValue = round(sender.value * 4) / 4
        sender.value = roundedValue
        
        playerManager.setPlaybackRate(roundedValue)
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean up resources
        if appState == .recording {
            recorderManager.stopRecording()
        }
        
        if appState == .playback {
            playerManager.stopPlayback()
        }
        
        cameraManager.stopSession()
    }
}

// MARK: - RecorderManagerDelegate
extension MainViewController: RecorderManagerDelegate {
    func recorderDidFinishRecording(videoURL: URL) {
        appState = .playback
        
        // Switch to playback mode
        cameraView.isHidden = true
        playerView.isHidden = false
        
        // Load the video for playback
        playerManager.loadVideo(url: videoURL)
    }
    
    func recorderDidFailRecording(error: Error) {
        appState = .ready
        
        let alert = UIAlertController(
            title: "Recording Failed",
            message: "There was an error while recording: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - VideoPlayerDelegate
extension MainViewController: VideoPlayerDelegate {
    func playerDidStopPlayback() {
        appState = .ready
    }
}

// MARK: - SettingsDelegate
extension MainViewController: SettingsDelegate {
    func settingsDidUpdate() {
        // Apply new settings
        cameraManager.setFrameRate(fps: settingsManager.frameRate)
        recorderManager.setDuration(settingsManager.recordingDuration)
    }
}

// MARK: - SettingsPanelDelegate
extension MainViewController: SettingsPanelDelegate {
    func settingsPanel(_ panel: SettingsPanel, didChangeDurationAtIndex index: Int) {
        if index >= 0 && index < settingsManager.durationOptions.count {
            settingsManager.setRecordingDuration(settingsManager.durationOptions[index])
        }
    }
    
    func settingsPanel(_ panel: SettingsPanel, didChangeFrameRateAtIndex index: Int) {
        if index >= 0 && index < settingsManager.frameRateOptions.count {
            settingsManager.setFrameRate(settingsManager.frameRateOptions[index])
        }
    }
    
    func settingsPanelDidClose(_ panel: SettingsPanel) {
        toggleSettingsPanel()
    }
}