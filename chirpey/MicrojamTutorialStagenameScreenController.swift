//
//  MicrojamTutorialStagenameScreenControllerViewController.swift
//  microjam
//
//  Created by Charles Martin on 30/3/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTutorialStagenameScreenController: UIViewController {
    
    /// Link to the users' profile data.
    let profile: PerformerProfile = UserProfile.shared.profile

    /// Text field for entering stage name.
    @IBOutlet weak var userNameTextField: UITextField!
    
    @IBAction func generateStageName(_ sender: Any) {
        let newName = PerformerProfile.randomPerformerName()
        userNameTextField.text = newName
        UserDefaults.standard.set(newName, forKey: SettingsKeys.performerKey)
        profile.stageName = newName
        UserProfile.shared.updateUserProfile()
    }
    
    @IBAction func skipTutorial(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
        UserDefaults.standard.set(true, forKey: SettingsKeys.tutorialCompleted)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.text = profile.stageName
        userNameTextField.delegate = self // UI TextFieldDelegate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension MicrojamTutorialStagenameScreenController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {  // text field delegate delegate method
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newName = userNameTextField.text {
            profile.stageName = newName
            UserDefaults.standard.set(newName, forKey: SettingsKeys.performerKey)
            UserProfile.shared.updateUserProfile()
        }
        return true
    }
}


