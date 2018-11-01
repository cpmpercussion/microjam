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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setColourTheme()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TABVC: Loaded main tab bar.")
        // setupWorldTab()
        setupJamTab() // FIXME test that this does actually work properly.
        setupProfileTab() // Set up the profile tab.
        NotificationCenter.default.addObserver(self, selector: #selector(setColourTheme), name: .setColourTheme, object: nil) // notification for colour theme.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .setColourTheme, object: nil)
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
        let controller = ChirpJamViewController.instantiateJamController()
        controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.jamTab, image: #imageLiteral(resourceName: "localjamsTabIcon"), selectedImage: nil)
        let navigation = UINavigationController(rootViewController: controller)
        viewControllers?.append(navigation)
        // Accessibility elements
        controller.isAccessibilityElement = true
        controller.accessibilityTraits = UIAccessibilityTraits.button
        controller.accessibilityLabel = "Jam button"
        controller.accessibilityHint = "Tap to create a new Jam"
        controller.title = "jam!"
    }
    
    /// Setup profile screen
    func setupProfileTabStackVersion() {
        if let controller = ProfileScreenController.storyboardInstance() {
            controller.tabBarItem = UITabBarItem(title: TabBarItemTitles.profileTab, image: #imageLiteral(resourceName: "profileTabIcon"), selectedImage: nil)
//            controller.view.translatesAutoresizingMaskIntoConstraints = false
            let navigation = UINavigationController(rootViewController: controller)
            viewControllers?.append(navigation)
            // Accessibility elements
            controller.isAccessibilityElement = true
            controller.accessibilityTraits = UIAccessibilityTraits.button
            controller.accessibilityLabel = "Profile button"
            controller.accessibilityHint = "Tap to access your user profile"
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
            // Accessibility elements
            controller.isAccessibilityElement = true
            controller.accessibilityTraits = UIAccessibilityTraits.button
            controller.accessibilityLabel = "Profile button"
            controller.accessibilityHint = "Tap to access your user profile"
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

// Set up dark and light mode.
extension MicrojamTabBarController {
    
    @objc func setColourTheme() {
        UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) ? setDarkMode() : setLightMode()
    }
    
    func setDarkMode() {
        self.tabBar.backgroundColor = DarkMode.background
        self.tabBar.barTintColor = DarkMode.background
        self.tabBar.tintColor = DarkMode.highlight
    }
    
    func setLightMode() {
        self.tabBar.backgroundColor = LightMode.background
        self.tabBar.barTintColor = LightMode.background
        self.tabBar.tintColor = LightMode.highlight
    }
}
