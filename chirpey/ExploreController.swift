//
//  ExploreController.swift
//  microjam
//
//  Created by Henrik Brustad on 25/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

private let cellIdentifier = "exploreCell"

class ExploreController: UIViewController {
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.register(ExploreCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collection.backgroundColor = .clear
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let playbutton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(#imageLiteral(resourceName: "plus sign"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(#imageLiteral(resourceName: "profile_icon"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var players = [Player]()
    var currentPlayer: Player?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBackgroundGradient()
        
        navigationItem.title = "Explore"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(showUserProfile))
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        playbutton.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        
        setupSubviews()
        
        getPlayerData()
        print(players.count)
    }
    
    func getPlayerData() {
        
        let performances = PerformanceStore.shared.storedPerformances
        
        for perf in performances {
            let player = Player()
            player.delegate = self
            let chirp = ChirpView(performance: perf)
            player.chirpViews.append(chirp)
            
            var current = perf
            while current.replyto != "" {
                if let next = PerformanceStore.shared.fetchPerformanceFrom(title: current.replyto) {
                    let chirp = ChirpView(performance: next)
                    player.chirpViews.append(chirp)
                    current = next
                } else {
                    break
                }
            }
            
            players.append(player)
        }
    }
    
    func playButtonPressed() {
        
        guard let player = currentPlayer else { return }
        
        player.play()
    }
    
    func showUserProfile() {
        print("123592")
    }
    
}

extension ExploreController: PlayerDelegate {
    
    func progressTimerStep() {
        
    }
    
    func progressTimerEnded() {
        
        guard let player = currentPlayer else { return }
        
        player.stop()
    }
}

extension ExploreController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return players.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ExploreCell
        
        if let player = cell.player {
            for chirp in player.chirpViews {
                chirp.closePdFile()
                chirp.removeFromSuperview()
            }
        }
        
        let player = players[indexPath.item]
        cell.player = player
        
        if let profile = PerformerProfileStore.shared.getProfile(forPerformance: player.chirpViews.first!.performance!) {
            cell.imageView.image = profile.avatar
        } else {
            cell.imageView.image = nil
        }
        
        for chirp in player.chirpViews {
            chirp.frame = cell.chirpContainer.bounds
            chirp.openSoundScheme(withName: chirp.performance!.instrument)
            cell.chirpContainer.addSubview(chirp)
        }
        
        return cell
    }
}

extension ExploreController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let currentPlayer = currentPlayer {
            currentPlayer.stop()
        }
        
        let player = players[indexPath.item]
        currentPlayer = player
        
//        for chirp in player.chirpViews {
//            chirp.openSoundScheme(withName: chirp.performance!.instrument)
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
//        let player = players[indexPath.item]
//        
//        for chirp in player.chirpViews {
//            chirp.closePdFile()
//        }
    }
}

extension ExploreController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension ExploreController {
    
    func setBackgroundGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor(red: 148/255, green: 193/255, blue: 190/255, alpha: 1).cgColor, UIColor(red: 110/255, green: 155/255, blue: 153/255, alpha: 1).cgColor]
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    func setupSubviews() {
        
        view.addSubview(bottomView)
        view.addSubview(collectionView)
        setupBottomView()
        setupCollectionView()
        
    }
    
    func setupCollectionView() {
        
        collectionView.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
    
    
    func setupBottomView() {
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: 49).isActive = true
        
        bottomView.addSubview(profileButton)
        
        profileButton.leftAnchor.constraint(equalTo: bottomView.leftAnchor).isActive = true
        profileButton.topAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        profileButton.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor).isActive = true
        profileButton.widthAnchor.constraint(equalTo: bottomView.widthAnchor, multiplier: 1/3).isActive = true
        
        bottomView.addSubview(playbutton)
        
        playbutton.leftAnchor.constraint(equalTo: profileButton.rightAnchor).isActive = true
        playbutton.topAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        playbutton.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor).isActive = true
        playbutton.widthAnchor.constraint(equalTo: bottomView.widthAnchor, multiplier: 1/3).isActive = true
        
        bottomView.addSubview(addButton)
        
        addButton.leftAnchor.constraint(equalTo: playbutton.rightAnchor).isActive = true
        addButton.topAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        addButton.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor).isActive = true
        addButton.widthAnchor.constraint(equalTo: bottomView.widthAnchor, multiplier: 1/3).isActive = true
    }
    
}



































