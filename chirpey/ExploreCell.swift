//
//  ExploreCell.swift
//  microjam
//
//  Created by Henrik Brustad on 17/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class ExploreCell: UICollectionViewCell {
    
    var player: Player?
    
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

    let chirpContainer: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        contentView.addSubview(chirpContainer)
        setupChirpContainer()
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
    
    private func setupChirpContainer() {
        chirpContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        chirpContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -16).isActive = true
        chirpContainer.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 32).isActive = true
        chirpContainer.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32).isActive = true
        chirpContainer.heightAnchor.constraint(equalTo: chirpContainer.widthAnchor).isActive = true
    }
    
    private func setupAvatarImage() {
        avatarImageView.leftAnchor.constraint(equalTo: chirpContainer.leftAnchor, constant: 8).isActive = true
        avatarImageView.bottomAnchor.constraint(equalTo: chirpContainer.topAnchor, constant: -8).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    private func setupPerformerLabel() {
        performer.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 4).isActive = true
        performer.bottomAnchor.constraint(equalTo: avatarImageView.centerYAnchor).isActive = true
        performer.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        performer.rightAnchor.constraint(equalTo: chirpContainer.rightAnchor).isActive = true
    }
    
    private func setupTitleLabel() {
        title.topAnchor.constraint(equalTo: avatarImageView.centerYAnchor).isActive = true
        title.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 4).isActive = true
        title.rightAnchor.constraint(equalTo: chirpContainer.rightAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor).isActive = true
    }
    
    private func setupContextLabel() {
        context.leftAnchor.constraint(equalTo: chirpContainer.leftAnchor, constant: 8).isActive = true
        context.topAnchor.constraint(equalTo: chirpContainer.bottomAnchor, constant: 8).isActive = true
        context.rightAnchor.constraint(equalTo: chirpContainer.centerXAnchor).isActive = true
    }
    
    private func setupInstrumentLabel() {
        instrument.leftAnchor.constraint(equalTo: chirpContainer.centerXAnchor).isActive = true
        instrument.topAnchor.constraint(equalTo: chirpContainer.bottomAnchor, constant: 8).isActive = true
        instrument.rightAnchor.constraint(equalTo: chirpContainer.rightAnchor, constant: -8).isActive = true
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
