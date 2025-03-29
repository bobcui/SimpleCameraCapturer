import UIKit

class SettingsPanel: UIView {
    // UI elements
    private var titleLabel: UILabel!
    private var closeButton: UIButton!
    private var durationPickerLabel: UILabel!
    private var durationPicker: UIPickerView!
    private var frameRatePickerLabel: UILabel!
    private var frameRatePicker: UIPickerView!
    
    // Data
    private var durations: [String] = []
    private var frameRates: [String] = []
    
    // Delegate
    weak var delegate: SettingsPanelDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Panel appearance
        backgroundColor = UIColor(white: 0.1, alpha: 0.95)
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
        
        // Handle for dragging
        let handleView = UIView()
        handleView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        handleView.layer.cornerRadius = 2.5
        addSubview(handleView)
        
        // Title and close button
        titleLabel = UILabel()
        titleLabel.text = "Settings"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        addSubview(titleLabel)
        
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        addSubview(closeButton)
        
        // Duration picker
        durationPickerLabel = UILabel()
        durationPickerLabel.text = "Recording Duration"
        durationPickerLabel.textColor = .lightGray
        durationPickerLabel.font = UIFont.systemFont(ofSize: 16)
        addSubview(durationPickerLabel)
        
        durationPicker = UIPickerView()
        durationPicker.delegate = self
        durationPicker.dataSource = self
        addSubview(durationPicker)
        
        // Frame rate picker
        frameRatePickerLabel = UILabel()
        frameRatePickerLabel.text = "Frame Rate"
        frameRatePickerLabel.textColor = .lightGray
        frameRatePickerLabel.font = UIFont.systemFont(ofSize: 16)
        addSubview(frameRatePickerLabel)
        
        frameRatePicker = UIPickerView()
        frameRatePicker.delegate = self
        frameRatePicker.dataSource = self
        addSubview(frameRatePicker)
        
        // Layout constraints
        handleView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        durationPickerLabel.translatesAutoresizingMaskIntoConstraints = false
        durationPicker.translatesAutoresizingMaskIntoConstraints = false
        frameRatePickerLabel.translatesAutoresizingMaskIntoConstraints = false
        frameRatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Handle
            handleView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            // Title and close button
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 25),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Duration picker
            durationPickerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            durationPickerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            durationPicker.topAnchor.constraint(equalTo: durationPickerLabel.bottomAnchor, constant: 5),
            durationPicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            durationPicker.trailingAnchor.constraint(equalTo: trailingAnchor),
            durationPicker.heightAnchor.constraint(equalToConstant: 120),
            
            // Frame rate picker
            frameRatePickerLabel.topAnchor.constraint(equalTo: durationPicker.bottomAnchor, constant: 20),
            frameRatePickerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            frameRatePicker.topAnchor.constraint(equalTo: frameRatePickerLabel.bottomAnchor, constant: 5),
            frameRatePicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            frameRatePicker.trailingAnchor.constraint(equalTo: trailingAnchor),
            frameRatePicker.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Add swipe down gesture
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeButtonPressed))
        swipeGesture.direction = .down
        addGestureRecognizer(swipeGesture)
    }
    
    func setup(durations: [String], frameRates: [String], selectedDurationIndex: Int, selectedFrameRateIndex: Int) {
        self.durations = durations
        self.frameRates = frameRates
        
        durationPicker.reloadAllComponents()
        frameRatePicker.reloadAllComponents()
        
        durationPicker.selectRow(selectedDurationIndex, inComponent: 0, animated: false)
        frameRatePicker.selectRow(selectedFrameRateIndex, inComponent: 0, animated: false)
    }
    
    @objc private func closeButtonPressed() {
        delegate?.settingsPanelDidClose(self)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension SettingsPanel: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == durationPicker {
            return durations.count
        } else {
            return frameRates.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == durationPicker {
            return durations[row]
        } else {
            return frameRates[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == durationPicker {
            delegate?.settingsPanel(self, didChangeDurationAtIndex: row)
        } else {
            delegate?.settingsPanel(self, didChangeFrameRateAtIndex: row)
        }
    }
    
    // Style the text
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title: String
        
        if pickerView == durationPicker {
            title = durations[row]
        } else {
            title = frameRates[row]
        }
        
        return NSAttributedString(
            string: title,
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)
            ]
        )
    }
}

// MARK: - Settings Panel Delegate Protocol
protocol SettingsPanelDelegate: AnyObject {
    func settingsPanel(_ panel: SettingsPanel, didChangeDurationAtIndex index: Int)
    func settingsPanel(_ panel: SettingsPanel, didChangeFrameRateAtIndex index: Int)
    func settingsPanelDidClose(_ panel: SettingsPanel)
}