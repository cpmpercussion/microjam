//
//  MixerTableViewCell.swift
//  microjam
//
//  Created by Charles Martin on 7/11/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

let margin : CGFloat = 20.0
let elementHeight: CGFloat = 60.0

class MixerTableViewCell: UITableViewCell {
    
    var chirp: ChirpView?
    
    let avatarView : UIImageView = {
        let avatar = UIImageView(frame: CGRect(x: 0, y: 0, width: elementHeight, height: elementHeight))
        avatar.image = #imageLiteral(resourceName: "empty-profile-image")
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = elementHeight / 2.0
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()

    let volumeSlider : UISlider = {
        let slider = UISlider()
        /// Accessibility elements
        slider.isAccessibilityElement = true
        slider.accessibilityTraits = UIAccessibilityTraits.button
        slider.accessibilityLabel = "Volume Slider"
        slider.accessibilityHint = "Change the volume of this layer"
        slider.accessibilityIdentifier = "Volume Slider"
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    

    let instrumentLabel : UILabel = {
        let label = UILabel()
        label.text = "Instrument"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let muteButton : UIButton = {
        let button = UIButton(type: .system)
        //button.setTitle("Mute", for: .normal)
        button.setImage(#imageLiteral(resourceName: "mute-button"), for: .normal)
        button.setTitleColor(ButtonColors.recordDisabled, for: .normal)
        button.tintColor = ButtonColors.recordDisabled
        button.translatesAutoresizingMaskIntoConstraints = false
        /// Accessibility elements
        button.isAccessibilityElement = true
        button.accessibilityTraits = UIAccessibilityTraits.button
        button.accessibilityLabel = "Mute Button"
        button.accessibilityHint = "Tap to mute this layer"
        button.accessibilityIdentifier = "Mute Button"
        return button
    }()
    
    let robojamButton : UIButton = {
        let button = UIButton(type: .system)
        //button.setTitle("RoboJam", for: .normal)
        button.setImage(#imageLiteral(resourceName: "microjam-roboplay"), for: .normal)
        button.setTitleColor(ButtonColors.roboplay, for: .normal)
        button.tintColor = ButtonColors.roboplay
        button.translatesAutoresizingMaskIntoConstraints = false
        /// Accessibility elements
        button.isAccessibilityElement = true
        button.accessibilityTraits = UIAccessibilityTraits.button
        button.accessibilityLabel = "RoboJam Button"
        button.accessibilityHint = "Tap to generate a RoboJam"
        button.accessibilityIdentifier = "RoboJam Button"
        return button
    }()
    
    let deleteButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        /// Accessibility elements
        button.isAccessibilityElement = true
        button.accessibilityTraits = UIAccessibilityTraits.button
        button.accessibilityLabel = "Delete Button"
        button.accessibilityHint = "Tap to delete this layer"
        button.accessibilityIdentifier = "Delete Button"
        return button
    }()
    
    /// Set the mute button's state externally.
    func setMute(muted: Bool) {
        if muted {
            muteButton.solidGlow()
        } else {
            muteButton.deactivateGlowing()
        }
    }

    /// Set the volume level externally.
    func setVolume(vol: Float) {
        volumeSlider.setValue(vol, animated: true)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func setVolume(sender: UISlider) {
        chirp?.setVolume(toLevel: sender.value)
    }
    
    @objc private func toggleMute(sender: UIButton) {
        if let chirp = chirp {
            if chirp.muted {
                chirp.muteOff()
            } else {
                chirp.muteOn()
            }
            setMute(muted: chirp.muted)
        }
    }
    
    /// Add subviews and constraints for the view.
    private func initSubviews() {
        let margins = layoutMarginsGuide
        
        contentView.addSubview(avatarView)
        contentView.addSubview(instrumentLabel)
        contentView.addSubview(muteButton)
        contentView.addSubview(volumeSlider)
        contentView.addSubview(robojamButton)
        //contentView.addSubview(deleteButton)
        
        // Constraints for the mute button
        avatarView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: elementHeight).isActive = true
        avatarView.widthAnchor.constraint(equalToConstant: elementHeight).isActive = true
        avatarView.layer.cornerRadius = elementHeight / 2.0
        avatarView.contentMode = .scaleAspectFill
        avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        
        instrumentLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: margin).isActive = true
        instrumentLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        instrumentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        muteButton.leadingAnchor.constraint(equalTo: instrumentLabel.trailingAnchor, constant: margin).isActive = true
        // muteButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        muteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        muteButton.heightAnchor.constraint(equalToConstant: 0.5*elementHeight).isActive = true
        muteButton.widthAnchor.constraint(equalToConstant: 0.5*elementHeight).isActive = true


        volumeSlider.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor, constant: margin).isActive = true
        // volumeSlider.widthAnchor.constraint(equalToConstant: 300).isActive = true
        volumeSlider.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true


        robojamButton.leadingAnchor.constraint(equalTo: volumeSlider.trailingAnchor, constant: margin).isActive = true
        // robojamButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        robojamButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        robojamButton.heightAnchor.constraint(equalToConstant: 0.5*elementHeight).isActive = true
        robojamButton.widthAnchor.constraint(equalToConstant: 0.5*elementHeight).isActive = true
        robojamButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true

        //deleteButton.leadingAnchor.constraint(equalTo: robojamButton.trailingAnchor, constant: margin).isActive = true
        // deleteButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        //deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        volumeSlider.maximumValue = 1.0
        volumeSlider.minimumValue = 0.0
        volumeSlider.addTarget(self, action: #selector(self.setVolume(sender:)), for: .valueChanged)
        muteButton.addTarget(self, action: #selector(self.toggleMute(sender:)), for: .touchUpInside)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

// Set up dark and light mode.
extension MixerTableViewCell {
    
    @objc func setColourTheme() {
        if UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) {
            setDarkMode()
        } else {
            setLightMode()
        }
    }
    
    func setDarkMode() {
        backgroundColor = DarkMode.background
        instrumentLabel.textColor = DarkMode.text
        muteButton.setTitleColor(DarkMode.highlight, for: .normal)
        robojamButton.setTitleColor(DarkMode.highlight, for: .normal)
        deleteButton.setTitleColor(DarkMode.highlight, for: .normal)
    }
    
    func setLightMode() {
        backgroundColor = LightMode.background
        instrumentLabel.textColor = LightMode.text
        muteButton.setTitleColor(LightMode.highlight, for: .normal)
        robojamButton.setTitleColor(LightMode.highlight, for: .normal)
        deleteButton.setTitleColor(LightMode.highlight, for: .normal)
    }
}
