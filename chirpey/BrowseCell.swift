//
//  BrowseCell.swift
//  microjam
//
//  Created by Henrik Brustad on 10/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class BrowseCell: UICollectionViewCell {
    
    var performance: ChirpPerformance?
    
    let performanceImageView : UIImageView = {
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
    
    let listenButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Listen", for: .normal)
        button.setTitleColor(UIColor(white: 0.1, alpha: 1), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let separatorLine : UIView = {
        let line = UIView()
        line.backgroundColor = UIColor(white: 0.8, alpha: 1)
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        initSubviews()
    }
    
    private func initSubviews() {
        contentView.addSubview(performanceImageView)
        contentView.addSubview(performerNameLabel)
        contentView.addSubview(listenButton)
        contentView.addSubview(separatorLine)
        
        performanceImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        performanceImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        performanceImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        performanceImageView.widthAnchor.constraint(equalTo: performanceImageView.heightAnchor).isActive = true
        
        performerNameLabel.topAnchor.constraint(equalTo: performanceImageView.topAnchor).isActive = true
        performerNameLabel.leftAnchor.constraint(equalTo: performanceImageView.rightAnchor, constant: 8).isActive = true
        performerNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        
        listenButton.bottomAnchor.constraint(equalTo: performanceImageView.bottomAnchor).isActive = true
        listenButton.leftAnchor.constraint(equalTo: performanceImageView.rightAnchor, constant: 8).isActive = true
        listenButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        listenButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        separatorLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        separatorLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separatorLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
}
