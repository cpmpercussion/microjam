//
//  NoAccountWarningStackView.swift
//  microjam
//
//  Created by Charles Martin on 4/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

/// A simple stackview with a label and button, displayed as a header when iCloud is not logged in or fails.
class NoAccountWarningStackView: UIStackView {
    /// Warning label
    let warningLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.gray
        label.textColor = UIColor.white
        label.text = "MicroJam uses iCloud to store your performances."
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    /// A button that generally would send the user to the Settings app to log into iCloud.
    let loginButton : UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.darkGray
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Log into iCloud to save jams.", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.gray
        axis = NSLayoutConstraint.Axis.vertical
        alignment = UIStackView.Alignment.center
        addArrangedSubview(warningLabel)
        addArrangedSubview(loginButton)
        warningLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        warningLabel.leftAnchor.constraint(equalTo: rightAnchor).isActive = true
        loginButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        loginButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        loginButton.addTarget(self, action: #selector(openSettingsApp), for: .touchUpInside)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Used by login button, opens Settings app so that user can log into iCloud.
    @objc fileprivate func openSettingsApp() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
