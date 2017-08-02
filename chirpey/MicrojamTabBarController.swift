//
//  MicrojamTabBarController.swift
//  microjam
//
//  Created by Charles Martin on 17/12/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTabBarController: UITabBarController {
    
    /// User Settings View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TABVC: Loaded main tab bar.")
        
        // MARK: Initialise view controllers that exist as tabs.
        if let userSettingsViewController = UserSettingsViewController.storyboardInstance() {
        userSettingsViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 2)
            viewControllers?.append(userSettingsViewController)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
