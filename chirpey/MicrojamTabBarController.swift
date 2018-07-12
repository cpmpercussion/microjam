//
//  MicrojamTabBarController.swift
//  microjam
//
//  Created by Charles Martin on 17/12/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

/// Subclass of UITabBarController to set up tabs programmatically in MicroJam.
class MicrojamTabBarController: UITabBarController {
    
    /// User Settings View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TABVC: Loaded main tab bar.")
        // setupWorldTab()
        setupJamTab() // FIXME test that this does actually work properly.
        setupProfileTab() // Set up the profile tab.
    }
    
    /// Setup the world tab
    func setupWorldTab() {
        // not implemented yet - still done in Main.storyboard
        //        let controller = ExploreController()
        //        controller.tabBarItem = UITabBarItem(title: "explore", image: #imageLiteral(resourceName: "remotejamsTabIcon"), selectedImage: nil)
        //        let navigation = UINavigationController(rootViewController: controller)
        //        viewControllers?.insert(navigation, at: 0)
    }
    
    /// Setup the jam screen
    func setupJamTab() {
        if let controller = ChirpJamViewController.storyboardInstance() {
            controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.jamTab, image: #imageLiteral(resourceName: "localjamsTabIcon"), selectedImage: nil)
            let navigation = UINavigationController(rootViewController: controller)
            viewControllers?.append(navigation)
            controller.title = "jam!"
        } else {
            print("TABVC: Jam tab could not be initialised.")
        }
    }
    
    /// Setup profile screen
    func setupProfileTabStackVersion() {
        if let controller = UserSettingsViewController.storyboardInstance() {
            controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.profileTab, image: #imageLiteral(resourceName: "profileTabIcon"), selectedImage: nil)
//            controller.view.translatesAutoresizingMaskIntoConstraints = false
            let navigation = UINavigationController(rootViewController: controller)
            viewControllers?.append(navigation)
        } else {
            print("TABVC: User Settings Tab could not be initialised.")
        }
    }
    
    /// Setup new profile screen
    func setupProfileTab() {
        if let controller = ProfileScreenController.storyboardInstance() {
            controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.profileTab, image: #imageLiteral(resourceName: "profileTabIcon"), selectedImage: nil)
            //            controller.view.translatesAutoresizingMaskIntoConstraints = false
            let navigation = UINavigationController(rootViewController: controller)
            viewControllers?.append(navigation)
        } else {
            print("TABVC: Profile Tab could not be initialised.")
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
