//
//  UserSettingsViewController.swift
//  microjam
// 
//  Manages User Settings such as ID, performer name and avatar
//  That 
//  Created by Charles Martin on 2/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

// Much help borrowed from:
// https://medium.com/@guilhermerambo/synchronizing-data-with-cloudkit-94c6246a3fda
// https://github.com/insidegui/CloudKitchenSink/blob/master/CloudKitchenSink/UserViewController.swift
// Thx!

import UIKit
import CloudKit
import DropDown

/// Displays iCloud User Settings screen to allow user to update avatar, name, and other details.
class UserSettingsViewController: UIViewController {
    
    /// stack for the Avatar view and stagename field
    @IBOutlet weak var identityStack: UIStackView!
    /// stack for the colour selectors and soundscheme dropdown
    @IBOutlet weak var settingsStack: UIStackView!
    /// View shown if user is not logged into iCloud.
    @IBOutlet weak var noAccountView: UIStackView!
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
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme
    @IBOutlet weak var soundSchemeDropDownButton: UIButton!
    
    /// Link to the users' profile data.
    let profile = UserProfile.shared
    
    /// updates the profile screen's fields according to a PerformerProfile object
    func updateUI() {
        avatarImageView.image = profile.avatar
        avatarContainerView.isHidden = false
        stageNameField.text = profile.stageName
        jamColourSlider.setValue(PerformerProfile.hueFrom(colour: profile.jamColour), animated: true)
        jamColourSlider.tintColor = profile.jamColour
        jamColourSlider.thumbTintColor = profile.jamColour
        backgroundColourSlider.tintColor = profile.backgroundColour
        backgroundColourSlider.thumbTintColor = profile.backgroundColour
        backgroundColourSlider.setValue(PerformerProfile.hueFrom(colour: profile.backgroundColour), animated: true)
        soundSchemeDropDownButton.setTitle(SoundSchemes.namesForKeys[Int(profile.soundScheme)], for: .normal)
    }
    
    
    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> UserSettingsViewController? {
        print("USVC: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"UserSettingsViewController", bundle: nil)
        let navController = storyboard.instantiateInitialViewController() as? UINavigationController
        return navController?.topViewController as? UserSettingsViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stageNameField.delegate = self // become delegate for the stagename field.
        
        // Display appropriate views if user is not logged in.
        if profile.loggedIn {
            identityStack.isHidden = false
            settingsStack.isHidden = false
            noAccountView.isHidden = true
        } else {
            identityStack.isHidden = true
            settingsStack.isHidden = true
            noAccountView.isHidden = false
        }
        
        // Soundscheme Dropdown initialisation.
        soundSchemeDropDown.anchorView = self.soundSchemeDropDownButton // anchor dropdown to intrument button
        soundSchemeDropDown.dataSource = Array(SoundSchemes.namesForKeys.values) // set dropdown datasource to available SoundSchemes
        soundSchemeDropDown.direction = .bottom
        
        // Action triggered on selection
        soundSchemeDropDown.selectionAction = {(index: Int, item: String) -> Void in
            print("DropDown selected:", index, item)
            if let sound = SoundSchemes.keysForNames[item] {
                self.profile.soundScheme = Int64(sound)
                UserDefaults.standard.set(sound, forKey: SettingsKeys.soundSchemeKey)
                self.updateUI()
            }
        }
        updateUI()
    }
    

    
    /// Used by login button, opens Settings app so that user can log into iCloud.
    @IBAction func logIn(_ sender: Any) {
        UIApplication.shared.open(URL(string: "App-Prefs:root=Settings")!, options: [:], completionHandler: nil)
    }
    
    /// Open image picker to change avatar.
    @IBAction func changeAvatar(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    /// Triggered when user changes the jam colour slider
    @IBAction func jamSliderMoved(_ sender: UISlider) {
        let colour = PerformerProfile.colourFromHue(hue: sender.value)
        sender.tintColor = colour
        sender.thumbTintColor = colour
        profile.jamColour = colour
    }
    
    /// Triggered when user changes the background colour
    @IBAction func backgroundSliderMoved(_ sender: UISlider) {
        let colour = PerformerProfile.colourFromHue(hue: sender.value)
        sender.tintColor = colour
        sender.thumbTintColor = colour
        profile.backgroundColour = colour
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("USVC: view will disappear")
        profile.updateUserProfile()
    }
    
    @IBAction func soundSchemeTapped(_ sender: Any) {
        soundSchemeDropDown.show()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // When segue occurs, request to upload basic profile info to CloudKit
        print("USVC: preparing to segue")
    }
}


/// Extensions to UserSettingsViewController to interact with an image picker and navigatino controller.
extension UserSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print("USVC: Updating image")
            profile.updateAvatar(image)
            avatarImageView.image = image
        }
    }
}

/// Stage Name Chooser extension
/// Adds functions to handle user changing the UITextField for their stage name on the settings screen.
extension UserSettingsViewController: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newName = stageNameField.text {
            profile.stageName = newName
            profile.updateUserProfile()
            print("USVC: Set stage name to: ", newName)
        }
        return true
    }
}

