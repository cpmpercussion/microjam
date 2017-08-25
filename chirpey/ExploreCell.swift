//
//  ExploreCell.swift
//  microjam
//
//  Created by Henrik Brustad on 25/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class ExploreCell: UICollectionViewCell {
    
    var player: Player?
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 32
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let performerLabel: UILabel = {
        let label = UILabel()
        label.text = "Performer name"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = "Just Now"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let shadowView: UIView = {
        let view = UIView()
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let performanceView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let chirpContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let bottomField: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let replyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "reply"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Performance Title"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let heartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    private func setupSubviews() {
        
        contentView.addSubview(shadowView)
        contentView.addSubview(imageView)
        contentView.addSubview(performerLabel)
        contentView.addSubview(dateLabel)
        
        imageView.bottomAnchor.constraint(equalTo: shadowView.topAnchor, constant: -8).isActive = true
        imageView.leftAnchor.constraint(equalTo: shadowView.leftAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        performerLabel.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 8).isActive = true
        performerLabel.bottomAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        performerLabel.rightAnchor.constraint(equalTo: shadowView.rightAnchor).isActive = true
        
        dateLabel.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 8).isActive = true
        dateLabel.topAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        dateLabel.rightAnchor.constraint(equalTo: shadowView.rightAnchor).isActive = true
        
        setupPerformanceView()
    }
    
    func setupPerformanceView() {
        
        shadowView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 32).isActive = true
        shadowView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32).isActive = true
        shadowView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 49).isActive = true
        shadowView.heightAnchor.constraint(equalTo: shadowView.widthAnchor, constant: 49).isActive = true
        
        shadowView.addSubview(performanceView)
        
        performanceView.leftAnchor.constraint(equalTo: shadowView.leftAnchor).isActive = true
        performanceView.rightAnchor.constraint(equalTo: shadowView.rightAnchor).isActive = true
        performanceView.topAnchor.constraint(equalTo: shadowView.topAnchor).isActive = true
        performanceView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor).isActive = true
        
        performanceView.addSubview(chirpContainer)
        
        chirpContainer.leftAnchor.constraint(equalTo: performanceView.leftAnchor).isActive = true
        chirpContainer.topAnchor.constraint(equalTo: performanceView.topAnchor).isActive = true
        chirpContainer.rightAnchor.constraint(equalTo: performanceView.rightAnchor).isActive = true
        chirpContainer.heightAnchor.constraint(equalTo: chirpContainer.widthAnchor).isActive = true
    
        performanceView.addSubview(bottomField)
        setupBottomView()
    }
    
    func setupBottomView() {
        
        bottomField.bottomAnchor.constraint(equalTo: performanceView.bottomAnchor).isActive = true
        bottomField.leftAnchor.constraint(equalTo: performanceView.leftAnchor).isActive = true
        bottomField.rightAnchor.constraint(equalTo: performanceView.rightAnchor).isActive = true
        bottomField.heightAnchor.constraint(equalToConstant: 49).isActive = true
    
        bottomField.addSubview(replyButton)
        
        replyButton.rightAnchor.constraint(equalTo: bottomField.rightAnchor).isActive = true
        replyButton.topAnchor.constraint(equalTo: bottomField.topAnchor).isActive = true
        replyButton.bottomAnchor.constraint(equalTo: bottomField.bottomAnchor).isActive = true
        replyButton.widthAnchor.constraint(equalTo: replyButton.heightAnchor).isActive = true
        
        bottomField.addSubview(heartButton)
        
        heartButton.leftAnchor.constraint(equalTo: bottomField.leftAnchor).isActive = true
        heartButton.topAnchor.constraint(equalTo: bottomField.topAnchor).isActive = true
        heartButton.bottomAnchor.constraint(equalTo: bottomField.bottomAnchor).isActive = true
        heartButton.widthAnchor.constraint(equalTo: heartButton.heightAnchor).isActive = true
        
        bottomField.addSubview(titleLabel)
        
        titleLabel.leftAnchor.constraint(equalTo: heartButton.rightAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: bottomField.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomField.bottomAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: replyButton.leftAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}



























