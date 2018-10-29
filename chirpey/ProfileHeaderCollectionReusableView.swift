//
//  ProfileHeaderCollectionReusableView.swift
//  microjam
//
//  Created by Charles Martin on 11/7/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import DropDown

class ProfileHeaderCollectionReusableView: UICollectionReusableView {
    
    /// Stack for the whole profile screen
    @IBOutlet weak var containerStack: UIStackView!
    /// stack for the Avatar view and stagename field
    @IBOutlet weak var identityStack: UIStackView!
    /// stack for the colour selectors and soundscheme dropdown
    @IBOutlet weak var settingsStack: UIStackView!
    /// Activity indicator used when loading avatar.
    @IBOutlet weak var avatarSpinner: UIActivityIndicatorView!
    /// Container view for avatar image.
    @IBOutlet weak var avatarContainerView: UIView! {
        didSet {
            avatarContainerView.clipsToBounds = true
            avatarContainerView.layer.cornerRadius = avatarContainerView.bounds.height / 2
        }
    }
    /// Avatar image view.
    @IBOutlet weak var avatarImageView: UIImageView!
    /// Text field for the user's stage name
    @IBOutlet weak var stageNameField: UITextField!
    /// Slider to control the jam drawing colour
    @IBOutlet weak var jamColourSlider: UISlider!
    /// Slider to control the jam background colour
    @IBOutlet weak var backgroundColourSlider: UISlider!
    /// Dropdown menu for selecting SoundScheme
    let soundSchemeDropDown = DropDown()
    /// Button connected to the soundscheme dropdown menu.
    @IBOutlet weak var soundSchemeDropDownButton: UIButton!
    /// Header view used if not logged in - View shown if user is not logged into iCloud.
    let noAccountHeaderView = NoAccountWarningStackView()
    /// Labels Outlet Collection
    @IBOutlet var profileHeaderLabels: [UILabel]!
    /// Buttons outlet collection
    @IBOutlet var profileHeaderButtons: [UIButton]!
    /// Container for Settings stack
    @IBOutlet var profileHeaderContainerViews: [UIView]!
    
    
    /// updates the profile screen's fields according to the present UserProfile data.
    @objc func updateUI() {
        // Display appropriate views if user is not logged in.
        if UserProfile.shared.loggedIn {
            noAccountHeaderView.isHidden = true
        } else {
            noAccountHeaderView.isHidden = false
        }
        let profile = UserProfile.shared.profile // Fill in from local user's profile.
        avatarImageView.image = profile.avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarContainerView.isHidden = false
        stageNameField.text = profile.stageName
        jamColourSlider.setValue(PerformerProfile.hueFrom(colour: profile.jamColour), animated: true)
        jamColourSlider.tintColor = profile.jamColour
        jamColourSlider.thumbTintColor = profile.jamColour
        backgroundColourSlider.tintColor = profile.backgroundColour
        backgroundColourSlider.thumbTintColor = profile.backgroundColour
        backgroundColourSlider.setValue(PerformerProfile.hueFrom(colour: profile.backgroundColour), animated: true)
        soundSchemeDropDownButton.setTitle(SoundSchemes.namesForKeys[profile.soundScheme], for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Soundscheme Dropdown initialisation.
        soundSchemeDropDown.anchorView = soundSchemeDropDownButton // anchor dropdown to intrument button
        soundSchemeDropDown.dataSource = Array(SoundSchemes.namesForKeys.values) // set dropdown datasource to available SoundSchemes
        soundSchemeDropDown.direction = .bottom
        // Action triggered on selection
        soundSchemeDropDown.selectionAction = {(index: Int, item: String) -> Void in
            print("ProfileHeader: DropDown selected.", index, item)
            if let sound = SoundSchemes.keysForNames[item] {
                UserProfile.shared.profile.soundScheme = Int64(sound)
                self.updateUI()
            }
        }
        
        // Set up the no account view and collection view.
        noAccountHeaderView.frame = CGRect(x: 0, y: 0, width: containerStack.frame.width, height: 100) // TODO: This doesn't work in a stack view derp.
        containerStack.insertArrangedSubview(noAccountHeaderView, at: 0)
        
        // add observer for UserProfile updates.
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NSNotification.Name(rawValue: userProfileUpdatedNotificationKey), object: nil)
        
        setColourTheme() // set up light or dark mode.
    }

}

// Set up dark and light mode.
extension ProfileHeaderCollectionReusableView {
    
    @objc func setColourTheme() {
        UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) ? setDarkMode() : setLightMode()
    }
    
    func setDarkMode() {
        backgroundColor = DarkMode.background
        for view in profileHeaderContainerViews {
            view.backgroundColor = DarkMode.background
        }
        //avatarImageView //: UIImageView!
        stageNameField.textColor = DarkMode.text
        for view in profileHeaderLabels {
            view.textColor = DarkMode.text
        }
        for button in profileHeaderButtons {
            button.setTitleColor(DarkMode.highlight, for: .normal)
        }
    }
    
    func setLightMode() {
        backgroundColor = LightMode.background
        for view in profileHeaderContainerViews {
            view.backgroundColor = LightMode.background
        }
        //avatarImageView //: UIImageView!
        stageNameField.textColor = LightMode.text
        for view in profileHeaderLabels {
            view.textColor = LightMode.text
        }
        for button in profileHeaderButtons {
            button.setTitleColor(LightMode.highlight, for: .normal)
        }
    }
}
