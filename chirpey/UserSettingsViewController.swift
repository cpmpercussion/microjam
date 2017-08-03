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

/// Displays iCloud User Settings screen to allow user to update avatar, name, and other details.
class UserSettingsViewController: UIViewController {
    
    /// ID Label shown in UserSettings screen REMOVE FOR RELEASE
    @IBOutlet weak var idLabel: UILabel!
    /// Username label shown in UserSettings screens
    @IBOutlet weak var nameLabel: UILabel!
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
    
    /// CKRecord of user information.
    var userRecord: CKRecord? {
        didSet {
            if let userRecord = userRecord {
                // User Record Found, extract user data to display
                let profile = PerformerProfile() // start with blank profile
                var cloudNeedsUpdating = false
                // Avatar
                if let avatarPath = userRecord[UserCloudKeys.avatar] as? CKAsset,
                    let avatarImage = UIImage(contentsOfFile: avatarPath.fileURL.path) {
                    profile.avatar = avatarImage
                    print("USVC: Avatar found on Cloudkit.")
                }
                
                // Stage Name
                if let stageName = userRecord[UserCloudKeys.stagename] as? String {
                    profile.stageName = stageName
                    print("USVC: Stagename found on Cloudkit.")
                } else if let stageName = UserDefaults.standard.string(forKey: SettingsKeys.performerKey) {
                    profile.stageName = stageName
                    print("USVC: Stagename found in UserDefaults (updating in cloud)")
                    cloudNeedsUpdating = true
                }
                
                // Jam Colour
                if let jamHex = userRecord[UserCloudKeys.jamColour] as? String {
                    profile.jamColour = UIColor(jamHex)
                    print("USVC: jam colour found on Cloudkit.")
                } else {
                    let jamHue = UserDefaults.standard.float(forKey: SettingsKeys.performerColourKey)
                    profile.jamColour = UIColor(hue: CGFloat(jamHue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                    print("USVC: jam colour found in user defaults.")
                    cloudNeedsUpdating = true
                }
                
                // BG Colour
                if let bgHex = userRecord[UserCloudKeys.backgroundColour] as? String {
                    profile.backgroundColour = UIColor(bgHex)
                    print("USVC: bg colour found on Cloudkit.")
                } else {
                    let bgHue = UserDefaults.standard.float(forKey: SettingsKeys.backgroundColourKey)
                    profile.backgroundColour = UIColor(hue: CGFloat(bgHue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                    print("USVC: bg colour found in UserDefaults.")
                    cloudNeedsUpdating = true
                }
                
                // SoundScheme
                if let soundScheme = userRecord[UserCloudKeys.soundScheme] as? Int64 {
                    profile.soundScheme = soundScheme
                    print("USVC: soundscheme found on Cloudkit.")
                } else {
                    let soundScheme = UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)
                    profile.soundScheme = Int64(soundScheme)
                    print("USVC: soundscheme found in userdefaults.")
                    cloudNeedsUpdating = true
                }
                
                if (cloudNeedsUpdating) {
                    updateUserBasicProfile(userRecord, with: profile)
                }
                
                updateUI(profile: profile)
                userProfile = profile
                avatarContainerView.isHidden = false
            } else {
                // User Record not found, don't show user info fields.
                avatarContainerView.isHidden = true
            }
        }
    }
    
    /// Storage for a local copy of the users' profile data.
    var userProfile: PerformerProfile?
    
    /// updates the profile screen's fields according to a PerformerProfile object
    func updateUI(profile: PerformerProfile) {
        avatarImageView.image = profile.avatar
        stageNameField.text = profile.stageName
        jamColourSlider.setValue(PerformerProfile.hueFrom(colour: profile.jamColour), animated: true)
        jamColourSlider.tintColor = profile.jamColour
        jamColourSlider.thumbTintColor = profile.jamColour
        
        backgroundColourSlider.tintColor = profile.backgroundColour
        backgroundColourSlider.thumbTintColor = profile.backgroundColour
        backgroundColourSlider.setValue(PerformerProfile.hueFrom(colour: profile.backgroundColour), animated: true)
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
        NotificationCenter.default.addObserver(self, selector: #selector(startDiscoveryProcess), name: Notification.Name.CKAccountChanged, object: nil)
        startDiscoveryProcess()
    }
    
    /// Used to discover if user is logged into iCloud or not and display appropriate views.
    @objc private func startDiscoveryProcess() {
        self.noAccountView.isHidden = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    let alert = UIAlertController(title: "Account Error", message: "Unable to determine iCloud account status.\n\(error.localizedDescription)", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                } else {
                    switch status {
                    case .available:
                        self.fetchUserRecordIdentifier()
                    case .couldNotDetermine, .noAccount, .restricted:
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.showNoAccountInfo()
                    }
                }
            }
        }
    }
    
    /// Un-hides the view with login button.
    private func showNoAccountInfo() {
        self.noAccountView.isHidden = false
    }
    
    /// Used by login button, opens Settings app so that user can log into iCloud.
    @IBAction func logIn(_ sender: Any) {
        UIApplication.shared.open(URL(string: "App-Prefs:root=Settings")!, options: [:], completionHandler: nil)
    }
    
    /// Finds the user record on CloudKit.
    private func fetchUserRecordIdentifier() {
        container.fetchUserRecordID { recordID, error in
            guard let recordID = recordID, error == nil else {
                // TODO: fill in error handling.
                return
            }
            
            DispatchQueue.main.async {
                print("USVC: Found user: \(recordID.recordName). Discovering info.")
                self.idLabel.text = recordID.recordName
                self.fetchUserRecord(with: recordID)
                self.discoverIdentity(for: recordID)
                self.discoverFriends()
            }
        }
    }

    /// Looks up the user's record on CloudKit
    private func fetchUserRecord(with recordID: CKRecordID) {
        container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            guard let record = record, error == nil else {
                // TODO: fill in error handling.
                return
            }
            print("USVC: Found user record.")
            DispatchQueue.main.async {
                self.userRecord = record
            }
        }
    }
    
    /// Look up the user's name and other details on CloudKit
    private func discoverIdentity(for recordID: CKRecordID) {
        container.requestApplicationPermission(.userDiscoverability) { status, error in
            guard status == .granted, error == nil else {
                // TODO: look at this error handling.
                DispatchQueue.main.async {
                    print("USVC: Not authorised to show user's name.")
                    self.nameLabel.text = ""
                }
                return
            }
            
            self.container.discoverUserIdentity(withUserRecordID: recordID) { identity, error in
                defer {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
                
                guard let components = identity?.nameComponents, error == nil else {
                    // TODO: fill in error handling.
                    return
                }
                
                DispatchQueue.main.async {
                    let formatter = PersonNameComponentsFormatter()
                    self.nameLabel.text = formatter.string(from: components)
                }
            }
        }
    }
    
    /// Look up users contacts who also have microjam records.
    private func discoverFriends() {
        container.discoverAllIdentities { identities, error in
            guard let identities = identities, error == nil else {
                // TODO: fill in error handling.
                return
            }
            
            print("USVC: User has \(identities.count) contact(s) using the app:")
        }
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
        if let profile = userProfile {
            profile.jamColour = colour
        }
    }
    
    /// Triggered when user changes the background colour
    @IBAction func backgroundSliderMoved(_ sender: UISlider) {
        let colour = PerformerProfile.colourFromHue(hue: sender.value)
        sender.tintColor = colour
        sender.thumbTintColor = colour
        if let profile = userProfile {
            profile.backgroundColour = colour
        }
    }
    
    /// Update the User's stageName in CloudKit
    private func updateUserStageName(_ userRecord: CKRecord, with stageName: String) {
        userRecord[UserCloudKeys.stagename] = stageName as CKRecordValue
        container.publicCloudDatabase.save(userRecord) { _, error in
            if (error != nil) {
                print("USVC: Error saving to cloudkit")
                print(error ?? "")
            } else {
                print("USVC: updated user in cloudkit", stageName)
            }
        }
    }
    
    /// Update basic profile info in CloudKit (stagename, colours, and soundscheme)
    /// Does not update avatar image.
    internal func updateUserBasicProfile(_ userRecord: CKRecord, with profile: PerformerProfile) {
        userRecord[UserCloudKeys.stagename] = profile.stageName as CKRecordValue
        userRecord[UserCloudKeys.jamColour] = profile.jamColour.hexString() as CKRecordValue
        userRecord[UserCloudKeys.backgroundColour] = profile.backgroundColour.hexString() as CKRecordValue
        userRecord[UserCloudKeys.soundScheme] = profile.soundScheme as CKRecordValue
        
        container.publicCloudDatabase.save(userRecord) { _, error in
            if (error != nil) {
                print("USVC: Error saving to cloudkit")
                print(error ?? "")
            } else {
                print("USVC: updated user profile in cloudkit.")
            }
        }
        
        // update user defaults
        // FIXME: use of userdefaults should be deprecated.
        UserDefaults.standard.set(profile.stageName, forKey: SettingsKeys.performerKey)
        UserDefaults.standard.set(PerformerProfile.hueFrom(colour: profile.jamColour), forKey: SettingsKeys.performerColourKey)
        UserDefaults.standard.set(PerformerProfile.hueFrom(colour: profile.backgroundColour), forKey: SettingsKeys.backgroundColourKey)
        UserDefaults.standard.set(profile.soundScheme, forKey: SettingsKeys.soundSchemeKey)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("USVC: view will disappear")
        if let profile = userProfile, let record = userRecord {
            updateUserBasicProfile(record, with: profile)
        }
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
        
        guard let userRecord = userRecord,
            let image = info[UIImagePickerControllerOriginalImage] as? UIImage,
            let imageData = UIImagePNGRepresentation(image)
            else {
                print("Missing some data, unable to set the avatar now")
                return
        }
        
        let previousImage = avatarImageView.image
        avatarImageView.image = image
        
        do {
            let path = NSTemporaryDirectory() + "avatar_temp_\(UUID().uuidString).png"
            let url = URL(fileURLWithPath: path)
            
            try imageData.write(to: url)
            
            updateUserRecord(userRecord, with: url, fallbackImage: previousImage)
        } catch {
            print("USVC: Error writing avatar to temporary directory: \(error)")
        }
    }
    
    /// Update the user's avatar in CloudKit
    private func updateUserRecord(_ userRecord: CKRecord, with avatarURL: URL, fallbackImage: UIImage?) {
        avatarSpinner.startAnimating()
        avatarImageView.alpha = 0.5
        
        userRecord[UserCloudKeys.avatar] = CKAsset(fileURL: avatarURL)
        
        container.publicCloudDatabase.save(userRecord) { _, error in
            defer {
                DispatchQueue.main.async {
                    self.avatarImageView.alpha = 1
                    self.avatarSpinner.stopAnimating()
                    
                    do {
                        try FileManager.default.removeItem(at: avatarURL)
                    } catch {
                        print("USVC: Error deleting temporary avatar file: \(error)")
                    }
                }
            }
            
            guard error == nil else {
                // TODO: some kind of error handling
                DispatchQueue.main.async {
                    self.avatarImageView.image = fallbackImage
                }
                return
            }
            print("Successfully updated user record with new avatar")
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
            if let profile = userProfile, let record = userRecord {
                profile.stageName = newName
                updateUserBasicProfile(record, with: profile)
            }
            UserDefaults.standard.set(newName, forKey: SettingsKeys.performerKey)
            print("USVC: Set stage name to: ", newName)
        }
        return true
    }
}

