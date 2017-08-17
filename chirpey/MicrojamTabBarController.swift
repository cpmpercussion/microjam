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
        
        let controller = ExploreController()
        controller.tabBarItem = UITabBarItem(title: "explore", image: #imageLiteral(resourceName: "remotejamsTabIcon"), selectedImage: nil)
        
        let navigation = UINavigationController(rootViewController: controller)
        viewControllers?.insert(navigation, at: 0)
        
        // MARK: Initialise view controllers that exist as tabs.
        if let userSettingsViewController = UserSettingsViewController.storyboardInstance() {
        userSettingsViewController.tabBarItem = UITabBarItem(title: "profile", image: #imageLiteral(resourceName: "settingsTabIcon"), selectedImage: nil)
            viewControllers?.append(userSettingsViewController)
        } else {
            print("TABVC: User Settings Tab could not be initialised.")
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
