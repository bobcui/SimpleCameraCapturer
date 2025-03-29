import UIKit

class SettingsPanel: UIViewController {
    
    // UI components
    private let titleLabel = UILabel()
    private let frameRateSegment = UISegmentedControl(items: ["60 FPS", "120 FPS"])
    private let frameRateLabel = UILabel()
    private let durationSlider = UISlider()
    private let durationLabel = UILabel()
    private let durationValueLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let fpsInfoLabel = UILabel()
    
    // Settings values
    var frameRate: Int = 60 {
        didSet {
            updateUI()
        }
    }
    
    var recordingDuration: Int = 10 {
        didSet {
            updateUI()
        }
    }
    
    // Callback
    var onSave: ((Int, Int) -> Void)?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title label
        titleLabel.text = "Recording Settings"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        
        // Frame rate selector
        frameRateLabel.text = "Frame Rate"
        frameRateLabel.font = UIFont.systemFont(ofSize: 17)
        
        frameRateSegment.selectedSegmentIndex = frameRate == 60 ? 0 : 1
        frameRateSegment.addTarget(self, action: #selector(frameRateChanged), for: .valueChanged)
        
        // FPS info label
        fpsInfoLabel.text = "Higher frame rates provide smoother slow-motion but may not be supported on all devices. If the app crashes at startup, try using 60 FPS."
        fpsInfoLabel.font = UIFont.systemFont(ofSize: 13)
        fpsInfoLabel.textColor = .secondaryLabel
        fpsInfoLabel.numberOfLines = 0
        
        // Duration slider
        durationLabel.text = "Recording Duration"
        durationLabel.font = UIFont.systemFont(ofSize: 17)
        
        durationSlider.minimumValue = 5
        durationSlider.maximumValue = 30
        durationSlider.value = Float(recordingDuration)
        durationSlider.addTarget(self, action: #selector(durationChanged), for: .valueChanged)
        
        durationValueLabel.text = "\(recordingDuration) seconds"
        durationValueLabel.font = UIFont.systemFont(ofSize: 15)
        durationValueLabel.textAlignment = .center
        
        // Buttons
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(frameRateLabel)
        view.addSubview(frameRateSegment)
        view.addSubview(fpsInfoLabel)
        view.addSubview(durationLabel)
        view.addSubview(durationSlider)
        view.addSubview(durationValueLabel)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
    }
    
    private func setupConstraints() {
        // Enable autolayout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        frameRateLabel.translatesAutoresizingMaskIntoConstraints = false
        frameRateSegment.translatesAutoresizingMaskIntoConstraints = false
        fpsInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationSlider.translatesAutoresizingMaskIntoConstraints = false
        durationValueLabel.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Frame rate
            frameRateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            frameRateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            frameRateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            frameRateSegment.topAnchor.constraint(equalTo: frameRateLabel.bottomAnchor, constant: 10),
            frameRateSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            frameRateSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            fpsInfoLabel.topAnchor.constraint(equalTo: frameRateSegment.bottomAnchor, constant: 10),
            fpsInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fpsInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Duration
            durationLabel.topAnchor.constraint(equalTo: fpsInfoLabel.bottomAnchor, constant: 30),
            durationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            durationSlider.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 10),
            durationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            durationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            durationValueLabel.topAnchor.constraint(equalTo: durationSlider.bottomAnchor, constant: 10),
            durationValueLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Buttons
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        frameRateSegment.selectedSegmentIndex = frameRate == 60 ? 0 : 1
        durationSlider.value = Float(recordingDuration)
        durationValueLabel.text = "\(recordingDuration) seconds"
    }
    
    // MARK: - Actions
    
    @objc private func frameRateChanged(_ sender: UISegmentedControl) {
        frameRate = sender.selectedSegmentIndex == 0 ? 60 : 120
    }
    
    @objc private func durationChanged(_ sender: UISlider) {
        recordingDuration = Int(sender.value)
        durationValueLabel.text = "\(recordingDuration) seconds"
    }
    
    @objc private func saveButtonTapped() {
        onSave?(frameRate, recordingDuration)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
}