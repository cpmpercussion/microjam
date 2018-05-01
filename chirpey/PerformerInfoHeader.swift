//
//  PerformerInfoHeader.swift
//  microjam
//
//  Created by Charles Martin on 1/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class PerformerInfoHeader: UICollectionReusableView {
    
    let avatarImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let performerNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //        backgroundColor = UIColor.white
        initSubviews()
    }
    
    private func initSubviews() {
        addSubview(avatarImageView)
        addSubview(performerNameLabel)
        
        avatarImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true
        
        performerNameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        performerNameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8).isActive = true
        performerNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
    
}
