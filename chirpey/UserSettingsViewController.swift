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

/// Displays iCloud User Settings screen to allow user to update avatar, name, and other details.
class UserSettingsViewController: UIViewController {
    
    /// Stack for the whole profile screen
    @IBOutlet weak var containerStack: UIStackView!
    /// stack for the Avatar view and stagename field
    @IBOutlet weak var identityStack: UIStackView!
    /// stack for the colour selectors and soundscheme dropdown
    @IBOutlet weak var settingsStack: UIStackView!
    /// View shown if user is not logged into iCloud.
    @IBOutlet weak var noAccountView: UIView!
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
    let profile: PerformerProfile = UserProfile.shared.profile
    
    /// updates the profile screen's fields according to the present UserProfile data.
    func updateUI() {
        // Display appropriate views if user is not logged in.
        if UserProfile.shared.loggedIn {
            noAccountView.isHidden = true
        } else {
            noAccountView.isHidden = false
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
        
        setupProfileCollectionView()
        
        updateUI()
        
        // add observer for UserProfile updates.
        NotificationCenter.default.addObserver(self, selector: #selector(userProfileDataUpdated), name: NSNotification.Name(rawValue: userProfileUpdatedNotificationKey), object: nil)
    }
    
    /// Setup the user performance collection view at the bottom of the profile screen.
    func setupProfileCollectionView() {
        print("setting up the collection view")
        // Setup the collection view
        let layout = UICollectionViewFlowLayout()
        let controller = UserPerfController(collectionViewLayout: layout)
        controller.performer = profile.stageName
        controller.performerID = UserProfile.shared.recordID
        navigationController?.pushViewController(controller, animated: true)
        addChildViewController(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        // put the controller where it should go.
        containerStack.addArrangedSubview(controller.view)
//        NSLayoutConstraint.activate([
//            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
//            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
//            controller.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
//            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
//            ])
        controller.didMove(toParentViewController: self)
    }
    
    /// Called by a notification when the UserProfile successfully loads a record.
    @objc func userProfileDataUpdated() {
        print("USVC: UserProfile updated, updating UI.")
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
        UserProfile.shared.updateUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("USVC: view will appear")
        
        if (!UserProfile.shared.loggedIn) {
            print("USVC: Profile not logged in, asking UserProfile for update")
        }
        updateUI()
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

