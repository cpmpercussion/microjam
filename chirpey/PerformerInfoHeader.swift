//
//  PerformerInfoHeader.swift
//  microjam
//
//  Created by Charles Martin on 1/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

/// The header view for a UserPerfController screen. This header shows a user's avatar and stagename.
class PerformerInfoHeader: UICollectionReusableView {
    /// The assumed height for the header view.
    static let headerHeight : CGFloat = 100
    /// A UIImageView for the performer's avatar
    let avatarImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "empty-profile-image")
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = UIAccessibilityTraits.image
        imageView.accessibilityLabel = "Avatar image"
        imageView.accessibilityIdentifier = "Avatar image"
        imageView.accessibilityHint = "Displays the user's avatar image"
        return imageView
    }()
    /// A UILabel for the performer's stagename
    let performerNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    /// Set up the subviews and add constraints manually.
    private func initSubviews() {
        let avatarImageHeight : CGFloat = PerformerInfoHeader.headerHeight * 0.8
        let avatarTopMargin : CGFloat = (PerformerInfoHeader.headerHeight - avatarImageHeight) / 2
        let avatarSideMargin : CGFloat = 30
        let stagenameSideMargin : CGFloat = 20
        
        addSubview(avatarImageView)
        addSubview(performerNameLabel)
        
        avatarImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: avatarSideMargin).isActive = true
        avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: avatarTopMargin).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: avatarImageHeight).isActive = true
        avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -avatarTopMargin).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true
        
        performerNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        performerNameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: stagenameSideMargin).isActive = true
        performerNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -(stagenameSideMargin)).isActive = true
        
        avatarImageView.backgroundColor = .lightGray
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = avatarImageHeight / 2
        avatarImageView.clipsToBounds = true
        
        performerNameLabel.font = performerNameLabel.font.withSize(24)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
    
}
