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
        setupSettingsTab()
        //setupProfileTab()
    }
    
    func exploreTab() {
        //        let controller = ExploreController()
        //        controller.tabBarItem = UITabBarItem(title: "explore", image: #imageLiteral(resourceName: "remotejamsTabIcon"), selectedImage: nil)
        //        let navigation = UINavigationController(rootViewController: controller)
        //        viewControllers?.insert(navigation, at: 0)
    }
    
    /// Setup settings screen
    func setupSettingsTab() {
        if let controller = UserSettingsViewController.storyboardInstance() {
            controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.profileTab, image: #imageLiteral(resourceName: "profileTabIcon"), selectedImage: nil)
//            controller.view.translatesAutoresizingMaskIntoConstraints = false
            let navigation = UINavigationController(rootViewController: controller)
            viewControllers?.append(navigation)
        } else {
            print("TABVC: User Settings Tab could not be initialised.")
        }
    }
    
//    /// Setup the profile screen
//    func setupProfileTab() {
//        print("setting up the profile screen")
//        // Setup the collection view
//        let layout = UICollectionViewFlowLayout()
//        let controller = ProfilePerfCollectionViewController(collectionViewLayout: layout)
//        controller.view.translatesAutoresizingMaskIntoConstraints = false
//        let navigation = UINavigationController(rootViewController: controller)
//        controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.profileTab, image: #imageLiteral(resourceName: "profileTabIcon"), selectedImage: nil)
//        viewControllers?.append(navigation)
//        print("TABVC: Profile Tab could not be initialised")
//    }

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
