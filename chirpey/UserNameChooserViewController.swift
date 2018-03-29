//
//  UserNameChooserViewController.swift
//  microjam
//
//  Username choosing screen displayed on first launch.
//
//  Created by Charles Martin on 28/2/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class UserNameChooserViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UITextFieldDelegate {

    /// Text field for entering stage name.
    @IBOutlet weak var userNameTextField: UITextField!
    
    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> UserNameChooserViewController? {
        print("UserNameVC: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"UserNameChooserViewController", bundle: nil)
        return storyboard.instantiateInitialViewController() as? UserNameChooserViewController
    }
    
    /// IBAction for pressing continue once stage name is set.
    @IBAction func userNameChoiceButtonPushed(_ sender: Any) {
        if let newName = userNameTextField.text {
            UserDefaults.standard.set(newName, forKey: SettingsKeys.performerKey)
            print("UserNameVC: Set Name to: ", newName)
        }
        // dismiss
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
    }
    

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {  //delegate method
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        self.userNameChoiceButtonPushed(self) // accept the user name
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
