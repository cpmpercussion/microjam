//
//  UserPerfCollectionViewCell.swift
//  microjam
//
//  Created by Charles Martin on 2/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class UserPerfCollectionViewCell: UICollectionViewCell {
    /// the margin from the performance image to the view edge
    let imageMargin : CGFloat = 0
    /// the margin to the image to the listen button.
    let listenButtonMargin : CGFloat = 5
    /// the size of the listen button.
    let listenButtonWidth : CGFloat = 20
    /// The performance to be displayed in this UserPerfCollectionViewCell
    var performance: ChirpPerformance?
    /// A UIImageView to display the performance image
    let performanceImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    /// Play Button
    let listenButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
        button.setTitleColor(UIColor(white: 0.1, alpha: 1), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.darkGray
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
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    /// Add subviews and constraints for the view.
    private func initSubviews() {
        contentView.addSubview(performanceImageView)
        contentView.addSubview(listenButton)
        contentView.addSubview(replyButton)
        
        // Contraints for the performance image
        performanceImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: imageMargin).isActive = true
        performanceImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: imageMargin).isActive = true
        performanceImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(imageMargin)).isActive = true
        performanceImageView.widthAnchor.constraint(equalTo: performanceImageView.heightAnchor).isActive = true
        
        // Constraints for the listen button
        listenButton.layer.cornerRadius = listenButtonWidth / 2
        listenButton.bottomAnchor.constraint(equalTo: performanceImageView.bottomAnchor, constant: -(listenButtonMargin)).isActive = true
        listenButton.leftAnchor.constraint(equalTo: performanceImageView.leftAnchor, constant: listenButtonMargin).isActive = true
        listenButton.widthAnchor.constraint(equalToConstant: listenButtonWidth).isActive = true
        listenButton.heightAnchor.constraint(equalTo: listenButton.widthAnchor).isActive = true
        
        // Constraints for the reply button
        replyButton.layer.cornerRadius = listenButtonWidth / 2
        replyButton.bottomAnchor.constraint(equalTo: performanceImageView.bottomAnchor, constant: -(listenButtonMargin)).isActive = true
        replyButton.rightAnchor.constraint(equalTo: performanceImageView.rightAnchor, constant: -(listenButtonMargin)).isActive = true
        replyButton.widthAnchor.constraint(equalToConstant: listenButtonWidth).isActive = true
        replyButton.heightAnchor.constraint(equalTo: listenButton.widthAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
}
