//
//  MicrojamTutorialAvatarScreenController.swift
//  microjam
//
//  Created by Charles Martin on 30/3/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTutorialAvatarScreenController: UIViewController {
    
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
    /// Link to the users' profile data.
    let profile: PerformerProfile = UserProfile.shared.profile

    @IBAction func skipTutorial(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
        UserDefaults.standard.set(true, forKey: SettingsKeys.tutorialCompleted)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.image = profile.avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarContainerView.isHidden = false
        
//        // add observer for UserProfile updates.
//        NotificationCenter.default.addObserver(self, selector: #selector(userProfileDataUpdated), name: NSNotification.Name(rawValue: userProfileUpdatedNotificationKey), object: nil)
    }

//    /// Called by a notification when the UserProfile successfully loads a record.
//    @objc func userProfileDataUpdated() {
//        print("USVC: UserProfile updated, updating UI.")
//        avatarImageView.image = profile.avatar
//        avatarImageView.contentMode = .scaleAspectFill
//        avatarContainerView.isHidden = false
//    }
    
    /// Open image picker to change avatar.
    @IBAction func changeAvatar(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func generateAvatar(_ sender: Any) {
        let newAvatar = PerformerProfile.randomUserAvatar()
        if let newAvatar = newAvatar {
            UserProfile.shared.updateAvatar(newAvatar)
            avatarImageView.image = newAvatar
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

/// Extensions to UserSettingsViewController to interact with an image picker and navigatino controller.
extension MicrojamTutorialAvatarScreenController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        if let newAvatar = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            UserProfile.shared.updateAvatar(newAvatar)
            avatarImageView.image = newAvatar
        }
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
