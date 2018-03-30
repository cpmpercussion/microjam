//
//  MicrojamTutorialStagenameScreenControllerViewController.swift
//  microjam
//
//  Created by Charles Martin on 30/3/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTutorialStagenameScreenController: UIViewController {

    /// Text field for entering stage name.
    @IBOutlet weak var userNameTextField: UITextField!
    
    /// IBAction for pressing continue once stage name is set.
    @IBAction func userNameChoiceButtonPushed(_ sender: Any) {
        if let newName = userNameTextField.text {
            UserDefaults.standard.set(newName, forKey: SettingsKeys.performerKey)
            print("UserNameVC: Set Name to: ", newName)
        }
        // dismiss
        //dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self // UI TextFieldDelegate
        // Do any additional setup after loading the view.
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   // text field delegate method
        textField.resignFirstResponder()
        self.userNameChoiceButtonPushed(self) // accept the user name
        return true
    }
}
