//
//  UserSettingsViewController.swift
//  microjam
// 
//  Manages User Settings such as ID, performer name and avatar
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

/// View controller for the "profile" tab: allows user to view/update avatar, name, and other details and shows their performances.
class UserSettingsViewController: UIViewController {
    
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
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme
    @IBOutlet weak var soundSchemeDropDownButton: UIButton!
    /// Header view used if not logged in - View shown if user is not logged into iCloud.
    let noAccountHeaderView = NoAccountWarningStackView()
    /// Link to the users' profile data.
    let profile: PerformerProfile = UserProfile.shared.profile
    
    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> UserSettingsViewController? {
        print("USVC: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"UserSettingsViewController", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as? UserSettingsViewController
        return controller
    }
    
    /// updates the profile screen's fields according to the present UserProfile data.
    @objc func updateUI() {
        // Display appropriate views if user is not logged in.
        if UserProfile.shared.loggedIn {
            noAccountHeaderView.isHidden = true
        } else {
            noAccountHeaderView.isHidden = false
        }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stageNameField.delegate = self // become delegate for the stagename field.
        // Soundscheme Dropdown initialisation.
        soundSchemeDropDown.anchorView = self.soundSchemeDropDownButton // anchor dropdown to intrument button
        soundSchemeDropDown.dataSource = Array(SoundSchemes.namesForKeys.values) // set dropdown datasource to available SoundSchemes
        soundSchemeDropDown.direction = .bottom
        // Action triggered on selection
        soundSchemeDropDown.selectionAction = {(index: Int, item: String) -> Void in
            print("DropDown selected:", index, item)
            if let sound = SoundSchemes.keysForNames[item] {
                self.profile.soundScheme = Int64(sound)
                self.updateUI()
            }
        }
        // Set up the no account view and collection view.
        noAccountHeaderView.frame = CGRect(x: 0, y: 0, width: containerStack.frame.width, height: 100) // TODO: This doesn't work in a stack view derp.
        containerStack.insertArrangedSubview(noAccountHeaderView, at: 0)
        setupProfileCollectionView()
        updateUI()
        // add observer for UserProfile updates.
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NSNotification.Name(rawValue: userProfileUpdatedNotificationKey), object: nil)
    }
    
    /// Setup the user performance collection view at the bottom of the profile screen.
    func setupProfileCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let controller = SimpleProfileCollectionViewController(collectionViewLayout: layout) // using simplified userperfcontroller.
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        containerStack.addArrangedSubview(controller.view)
        controller.didMove(toParent: self)
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

    /// When the view disappears, updates the profile on iCloud
    override func viewWillDisappear(_ animated: Bool) {
        UserProfile.shared.updateUserProfile()
    }
    
    /// When the view will appear, updates UI with latest profile / performance information
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
    }
    
    /// Opens the SoundScheme dropdown menu.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        soundSchemeDropDown.show()
    }
    
}

/// Extensions to UserSettingsViewController to interact with an image picker and navigatino controller.
extension UserSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            print("USVC: Updating image")
            UserProfile.shared.updateAvatar(image)
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
            UserProfile.shared.updateUserProfile()
            print("USVC: Set stage name to: ", newName)
        }
        return true
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
