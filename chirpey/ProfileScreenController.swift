//
//  ProfileScreenController.swift
//  microjam
//
//  Created by Charles Martin on 4/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// View Controller for the profile screen; subclass of UserPerfController to handle the flow layout and fetching of performances from the local user.
class ProfileScreenController: UserPerfController {
    /// Link to the users' profile data - not used right now, might be used later.
    let profile: PerformerProfile = UserProfile.shared.profile
    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> ProfileScreenController? {
        print("Profile Controller: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"ProfileScreenController", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as? ProfileScreenController
        return controller
    }
    static let headerID = "ProfileSceneHeader"
    static let footerID = "ProfileSceneFooter"
    /// Storage for the headerView
    var headerView : ProfileHeaderCollectionReusableView?
    var footerView : ProfileFooterCollectionReusableView?


    // MARK: - Collection View Setup
    
    /// Override of the header function size to be 300
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 310)
    }
    
    /// Override to present header view from storyboard.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            headerView = (collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileScreenController.headerID, for: indexPath) as! ProfileHeaderCollectionReusableView)
            headerView?.updateUI() // update with latest information
            headerView?.stageNameField.delegate = self // become delegate for the stagename field.
            return headerView!
        case UICollectionView.elementKindSectionFooter:
            footerView = (collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: ProfileScreenController.footerID, for: indexPath) as! ProfileFooterCollectionReusableView)
            return footerView!
        default:
            return UICollectionReusableView()
        }
    }

    
    /// Override of the footer function size to be 100 - just needs a few labels.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 200)
    }
    
    // MARK: - Life cycle
    
    /// Override of viewDidLoad in order to set the perfomerID to the local user.
    @objc override func viewDidLoad() {
        super.viewDidLoad()
        performerID = CKRecord.ID(recordName: "__defaultOwner__")
        NotificationCenter.default.addObserver(self, selector: #selector(exportDataReady), name: .userDataExportReady, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setColourTheme), name: .setColourTheme, object: nil) // notification for colour theme.
    }
    
    /// When the view disappears, updates the profile on iCloud
    override func viewWillDisappear(_ animated: Bool) {
        UserProfile.shared.updateUserProfile()
    }
    
    /// When the view will appear, updates UI with latest profile / performance information
    override func viewWillAppear(_ animated: Bool) {
        headerView?.updateUI()
        super.viewWillAppear(animated)
    }
    
    deinit {
        // Clean up notification center observers
        NotificationCenter.default.removeObserver(self, name: .userDataExportReady, object: nil)
        NotificationCenter.default.removeObserver(self, name: .setColourTheme, object: nil)
    }
    
    // MARK: - Interface builder actions for header
    
    /// Triggered when user changes the jam colour slider
    @IBAction func jamColourSliderMoved(_ sender: UISlider) {
        let colour = PerformerProfile.colourFromHue(hue: sender.value)
        sender.tintColor = colour
        sender.thumbTintColor = colour
        profile.jamColour = colour
    }
    
    /// Triggered when user changes the background colour
    @IBAction func backgroundColourSliderMoved(_ sender: UISlider) {
        let colour = PerformerProfile.colourFromHue(hue: sender.value)
        sender.tintColor = colour
        sender.thumbTintColor = colour
        profile.backgroundColour = colour
    }
    
    /// Opens the SoundScheme dropdown menu.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        headerView?.soundSchemeDropDown.show()
    }
    
    /// Open image picker to change avatar.
    @IBAction func changeAvatar(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func openInterfaceSettings(_ sender: Any) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)

    }
    //    MARK: - Interface Builder Actions for footer
    
    /// Action to open the microjam website in the default browser
    @IBAction func openMicrojamWebsite(_ sender: Any) {
        if let url = URL(string: "https://microjam.info") {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    /// Action to open the privacy policy in the default browser
    @IBAction func openPrivacyPolicy(_ sender: Any) {
        if let url = URL(string: "https://microjam.info/privacy") {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    @IBAction func exportDataButtonTapped(_ sender: Any) {
        // FIXME: Fill this in.
        print("Printing User Records")
        UserProfile.shared.exportRecords()
    }
    
    /// Called when export data is ready to be downloaded elsewhere.
    @objc func exportDataReady() {
        if let exportData = UserProfile.shared.exportedData {
            let activityViewController = UIActivityViewController(activityItems: [exportData as NSString], applicationActivities: nil)
            present(activityViewController, animated: true, completion: {})
        }
    }
    
    @IBAction func deleteDataButtonTapped(_ sender: Any) {
        //        UserProfile.shared.deleteRecords(really: false)
        let alert = UIAlertController(title: "Deleting Data", message: "You can delete your performances by tapping the menu for each performance above. None of your personal data is stored by microjam.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}


/// Stage Name Chooser extension
/// Adds functions to handle user changing the UITextField for their stage name on the settings screen.
extension ProfileScreenController: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newName = headerView?.stageNameField.text {
            UserProfile.shared.profile.stageName = newName
            UserProfile.shared.updateUserProfile()
            print("ProfileHeader: Set stage name to: ", newName)
        }
        return true
    }
}

/// Extensions to UserSettingsViewController to interact with an image picker and navigatino controller.
extension ProfileScreenController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            print("ProfileHeader: Updating image")
            UserProfile.shared.updateAvatar(image)
            headerView?.avatarImageView.image = image
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

extension ProfileScreenController {
    @objc override func setColourTheme() {
        UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) ? setDarkMode() : setLightMode()
        headerView?.setColourTheme()
        footerView?.setColourTheme()
    }
}
