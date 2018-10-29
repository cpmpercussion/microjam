//
//  ProfileFooterCollectionReusableView.swift
//  microjam
//
//  Created by Charles Martin on 11/7/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

/// A footer container for the Profile Screen
class ProfileFooterCollectionReusableView: UICollectionReusableView {
    @IBOutlet var profileFooterLabels: [UILabel]!
    @IBOutlet var profileFooterButtons: [UIButton]!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setColourTheme()
    }
}

// Set up dark and light mode.
extension ProfileFooterCollectionReusableView {
    
    @objc func setColourTheme() {
        if UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) {
            setDarkMode()
        } else {
            setLightMode()
        }
    }
    
    func setDarkMode() {
        backgroundColor = DarkMode.background
        for view in profileFooterLabels {
            view.textColor = DarkMode.text
        }
        for button in profileFooterButtons {
            button.setTitleColor(DarkMode.highlight, for: .normal)
        }
    }
    
    func setLightMode() {
        backgroundColor = LightMode.background
        for view in profileFooterLabels {
            view.textColor = LightMode.text
        }
        for button in profileFooterButtons {
            button.setTitleColor(LightMode.highlight, for: .normal)
        }
    }
}
