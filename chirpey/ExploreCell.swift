//
//  ExploreCell.swift
//  microjam
//
//  Created by Henrik Brustad on 17/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class ExploreCell: UICollectionViewCell {
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let performer: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "Performer"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let previewImage: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let title: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "date"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let context: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "context"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let instrument: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "instrument"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(white: 0.8, alpha: 1)
        button.layer.cornerRadius = 8
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Play", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let replyButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(white: 0.8, alpha: 1)
        button.layer.cornerRadius = 8
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Reply", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    private func initSubviews() {
        contentView.addSubview(previewImage)
        setupPreviewImage()
        contentView.addSubview(avatarImageView)
        setupAvatarImage()
        contentView.addSubview(performer)
        setupPerformerLabel()
        contentView.addSubview(title)
        setupTitleLabel()
        contentView.addSubview(context)
        setupContextLabel()
        contentView.addSubview(instrument)
        setupInstrumentLabel()
        contentView.addSubview(playButton)
        setupPlayButton()
        contentView.addSubview(replyButton)
        setupReplyButton()
    }
    
    private func setupPreviewImage() {
        previewImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        previewImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -16).isActive = true
        previewImage.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 32).isActive = true
        previewImage.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32).isActive = true
        previewImage.heightAnchor.constraint(equalTo: previewImage.widthAnchor).isActive = true
    }
    
    private func setupAvatarImage() {
        avatarImageView.leftAnchor.constraint(equalTo: previewImage.leftAnchor, constant: 8).isActive = true
        avatarImageView.bottomAnchor.constraint(equalTo: previewImage.topAnchor, constant: -8).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    private func setupPerformerLabel() {
        performer.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 4).isActive = true
        performer.bottomAnchor.constraint(equalTo: avatarImageView.centerYAnchor).isActive = true
        performer.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        performer.rightAnchor.constraint(equalTo: previewImage.rightAnchor).isActive = true
    }
    
    private func setupTitleLabel() {
        title.topAnchor.constraint(equalTo: avatarImageView.centerYAnchor).isActive = true
        title.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 4).isActive = true
        title.rightAnchor.constraint(equalTo: previewImage.rightAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor).isActive = true
    }
    
    private func setupContextLabel() {
        context.leftAnchor.constraint(equalTo: previewImage.leftAnchor, constant: 8).isActive = true
        context.topAnchor.constraint(equalTo: previewImage.bottomAnchor, constant: 8).isActive = true
        context.rightAnchor.constraint(equalTo: previewImage.centerXAnchor).isActive = true
    }
    
    private func setupInstrumentLabel() {
        instrument.leftAnchor.constraint(equalTo: previewImage.centerXAnchor).isActive = true
        instrument.topAnchor.constraint(equalTo: previewImage.bottomAnchor, constant: 8).isActive = true
        instrument.rightAnchor.constraint(equalTo: previewImage.rightAnchor, constant: -8).isActive = true
    }
    
    private func setupPlayButton() {
        playButton.topAnchor.constraint(equalTo: context.bottomAnchor, constant: 32).isActive = true
        playButton.rightAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -8).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    private func setupReplyButton() {
        replyButton.topAnchor.constraint(equalTo: context.bottomAnchor, constant: 32).isActive = true
        replyButton.leftAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8).isActive = true
        replyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        replyButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
