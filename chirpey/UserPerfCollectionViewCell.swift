//
//  UserPerfCollectionViewCell.swift
//  microjam
//
//  Created by Charles Martin on 2/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class UserPerfCollectionViewCell: UICollectionViewCell {
    /// The performance to be displayed in this UserPerfCollectionViewCell
    var performance: ChirpPerformance?
    /// A player controller for the ChirpView in the present cell
    var player: ChirpPlayer?
    /// the margin from the performance image to the view edge
    let imageMargin : CGFloat = 0
    /// the margin to the image to the listen button.
    let listenButtonMargin : CGFloat = 5
    /// the size of the listen button.
    let listenButtonWidth : CGFloat = 20
    /// A UIImageView to display the performance image
    
    let performanceImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        /// Accessibility elements
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = UIAccessibilityTraitButton
        imageView.accessibilityLabel = "performance"
        imageView.accessibilityHint = "Tap to access this performance"
        imageView.accessibilityIdentifier = "performance"
        
        return imageView
    }()
    /// Play Button
    let playButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
        button.setTitleColor(UIColor(white: 0.1, alpha: 1), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.darkGray
        /// Accessibility elements
        button.isAccessibilityElement = true
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityLabel = "Play button"
        button.accessibilityHint = "Tap to play performance"
        button.accessibilityIdentifier = "Play button"
        
        return button
    }()
    /// Reply Button
    let replyButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "microjam-reply"), for: .normal)
        button.setTitleColor(UIColor(white: 0.1, alpha: 1), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10 // Button size is 36
        button.tintColor = UIColor.darkGray
        /// Accessibility elements
        button.isAccessibilityElement = true
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityLabel = "Reply button"
        button.accessibilityHint = "Tap to reply"
        button.accessibilityIdentifier = "Reply button"

        return button
    }()
    let menuButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "settingsTabIcon"), for: .normal)
        button.setTitleColor(UIColor(white: 0.1, alpha: 1), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        button.tintColor = UIColor.darkGray
        /// Accessibility elements
        button.isAccessibilityElement = true
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityLabel = "Menu button"
        button.accessibilityHint = "Tap to access menu"
        button.accessibilityIdentifier = "Menu button"

        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    /// Prepare the cell for reuse by closing all Pd files.
    override func prepareForReuse() {
        /// Close ChirpViews in the cell's player (if they exist)
        if let player = player {
            for chirp in player.chirpViews {
                chirp.closePdFile()
                chirp.removeFromSuperview()
            }
        }
    }
    
    /// Add subviews and constraints for the view.
    private func initSubviews() {
        contentView.addSubview(performanceImageView)
        contentView.addSubview(playButton)
        contentView.addSubview(replyButton)
        contentView.addSubview(menuButton)
        
        // Contraints for the performance image
        performanceImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: imageMargin).isActive = true
        performanceImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: imageMargin).isActive = true
        performanceImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(imageMargin)).isActive = true
        performanceImageView.widthAnchor.constraint(equalTo: performanceImageView.heightAnchor).isActive = true
        
        // Constraints for the listen button
        playButton.layer.cornerRadius = listenButtonWidth / 2
        playButton.bottomAnchor.constraint(equalTo: performanceImageView.bottomAnchor, constant: -(listenButtonMargin)).isActive = true
        playButton.leftAnchor.constraint(equalTo: performanceImageView.leftAnchor, constant: listenButtonMargin).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: listenButtonWidth).isActive = true
        playButton.heightAnchor.constraint(equalTo: playButton.widthAnchor).isActive = true
        
        // Constraints for the reply button
        replyButton.layer.cornerRadius = listenButtonWidth / 2
        replyButton.bottomAnchor.constraint(equalTo: performanceImageView.bottomAnchor, constant: -(listenButtonMargin)).isActive = true
        replyButton.rightAnchor.constraint(equalTo: performanceImageView.rightAnchor, constant: -(listenButtonMargin)).isActive = true
        replyButton.widthAnchor.constraint(equalToConstant: listenButtonWidth).isActive = true
        replyButton.heightAnchor.constraint(equalTo: playButton.widthAnchor).isActive = true
        
        // Constraints for the menu button
        menuButton.layer.cornerRadius = listenButtonWidth / 2
        menuButton.topAnchor.constraint(equalTo: performanceImageView.topAnchor, constant: listenButtonMargin).isActive = true
        menuButton.rightAnchor.constraint(equalTo: performanceImageView.rightAnchor, constant: -(listenButtonMargin)).isActive = true
        menuButton.widthAnchor.constraint(equalToConstant: listenButtonWidth).isActive = true
        menuButton.heightAnchor.constraint(equalToConstant: listenButtonWidth).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
}
