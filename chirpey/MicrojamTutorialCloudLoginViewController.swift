//
//  MicrojamTutorialCloudLoginViewController.swift
//  microjam
//
//  Created by Charles Martin on 31/3/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTutorialCloudLoginViewController: UIViewController {
    /// Link to the users' profile data.
    let profile: PerformerProfile = UserProfile.shared.profile
    /// View shown if user is not logged into iCloud.
    @IBOutlet weak var noAccountView: UIView!
    /// View shown if the user is logged in
    @IBOutlet weak var loggedInView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }
    
    /// updates the profile screen's fields according to the present UserProfile data.
    func updateUI() {
        // Display appropriate views if user is not logged in.
        if UserProfile.shared.loggedIn {
            noAccountView.isHidden = true
            loggedInView.isHidden = false
        } else {
            noAccountView.isHidden = false
            loggedInView.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func skipTutorial(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    /// Used by login button, opens Settings app so that user can log into iCloud.
    @IBAction func logIn(_ sender: Any) {
        UIApplication.shared.open(URL(string: "App-Prefs:root=Settings")!, options: [:], completionHandler: nil)
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
