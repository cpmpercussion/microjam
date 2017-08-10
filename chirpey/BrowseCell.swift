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
    
    let performaceImageView : UIImageView = {
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
        addSubview(performaceImageView)
        addSubview(performerNameLabel)
        addSubview(listenButton)
        addSubview(separatorLine)
        
        let views = ["v0" : performaceImageView, "v1" : performerNameLabel, "v2" : listenButton, "v3" : separatorLine]
        
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]-8-[v1]-16-|", options: .alignAllTop, metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[v3]|", options: [], metrics: nil, views: views))

        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v0]-15-[v3(1)]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v1(33)]-4-[v2(44)]", options: .alignAllLeading, metrics: nil, views: views))
        
        constraints.append(NSLayoutConstraint(item: performaceImageView, attribute: .width, relatedBy: .equal, toItem: performaceImageView, attribute: .height, multiplier: 1.0, constant: 1.0))
        
        NSLayoutConstraint.activate(constraints)
        addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
}
