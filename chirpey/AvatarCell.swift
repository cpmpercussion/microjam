//
//  AvatarCell.swift
//  microjam
//
//  Created by Henrik Brustad on 24/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class AvatarCell: UICollectionViewCell {
    
    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Select your avatar"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    private func initSubviews() {
        contentView.addSubview(label)
        contentView.addSubview(imageView)
        
        imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 32).isActive = true
        label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32).isActive = true
        label.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -16).isActive = true
        label.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
