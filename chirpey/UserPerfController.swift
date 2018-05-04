//
//  UserPerfController.swift
//  microjam
//
//  Created by Henrik Brustad on 15/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

private let reuseIdentifier = "UserPerfCollectionViewCell"
private let headerReuseIdentifier = "headerView"

/// Displays all performances by a particular performer ID in a UICollectionView
class UserPerfController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    /// Local reference to the performanceStore singleton.
    let performanceStore = PerformanceStore.shared
    /// Local reference to the PerformerProfileStore.
    let profilesStore = PerformerProfileStore.shared
    /// The performer to be displayed.
    var performer: String? {
        didSet {
            navigationItem.title = performer
        }
    }
    /// Performer to search for (must be set when instantiating this ViewController.
    var performerID: CKRecordID?
    /// Performances by performer
    var loadedPerformances = [ChirpPerformance]()
    /// Ref to a (single) currently playing cell
    var currentlyPlaying: UserPerfCollectionViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(PerformerInfoHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(UserPerfCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(updateDataFromStore), name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Attempt to load the data and display it.
        updateDataFromStore()
        updateDataFromCloud()
    }
    
    /// Updates the CollectionView from the local performance store data.
    @objc func updateDataFromStore() {
        if let performerID = performerID {
            // Stop any playing performances
            if let cell = currentlyPlaying {
                cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                cell.player!.stop()
                currentlyPlaying = nil
            }
            // Reload data.
            loadedPerformances = performanceStore.performances(byPerformer: performerID)
            collectionView?.reloadData()
        }
    }
    
    /// Asks the performance store to fetch performances related to the current performerID from the cloud.
    func updateDataFromCloud() {
        if let performerID = performerID {
            performanceStore.fetchPerformances(byPerformer: performerID)
        }
    }
    
    
    /// method to set the height of the header section
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: PerformerInfoHeader.headerHeight)
    }

    /// method to set up the header view; displays the performer's avatar and stagename.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! PerformerInfoHeader
        headerView.frame.size.height = PerformerInfoHeader.headerHeight
        if let performerID = performerID,
            let profile = profilesStore.getProfile(forID: performerID) {
            headerView.avatarImageView.image = profile.avatar
            headerView.performerNameLabel.text = profile.stageName
        } else {
            headerView.avatarImageView.image = nil
            headerView.performerNameLabel.text = performer
        }
        return headerView
    }
    
    /// method to set the size of each item in the collection view; aiming for rows of three on a phone.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 3, height: view.frame.width / 3)
    }
    
    /// Set the inter-item spacing for the CollectionView to 0
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    /// Set the line spacing for the CollectionView to 0
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    /// method to decide how many items are in the CollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedPerformances.count
    }
    
    /// method to set up each cell in the CollectionView
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UserPerfCollectionViewCell
        let performance = loadedPerformances[indexPath.item]
        cell.playButton.tag = indexPath.item
        cell.replyButton.tag = indexPath.item
        
        cell.performance = performance
        cell.player = ChirpPlayer()
        cell.player!.delegate = self
        
        let chirpView = ChirpView(with: cell.performanceImageView.bounds, andPerformance: performance)
        cell.performanceImageView.backgroundColor = performance.backgroundColour.darkerColor
        cell.player!.chirpViews.append(chirpView)
        cell.performanceImageView.addSubview(chirpView)
        
        // Add constraints for cell.chirpContainer's subviews.
        for view in cell.performanceImageView.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.constrainEdgesTo(cell.performanceImageView)
        }

        // Set up cell with performance data
        cell.performanceImageView.image = performance.image
        cell.playButton.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        cell.replyButton.addTarget(self, action: #selector(replyButtonPressed), for: .touchUpInside)
        return cell
    }
    
    //TODO: make this selection work properly by displaying a playback only ChirpJamView
    /// method called when an item is selected in the CollectionView - should open a non-recordable ChirpJamView to play back and show info.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        stopCurrentlyPlayingPerformance()
        if let cell = collectionView.cellForItem(at: indexPath) as? UserPerfCollectionViewCell,
            let player = cell.player, let topPerformance = cell.performance {
            // Instantiate a ChirpJamViewController from storyboard
            let storyboard = UIStoryboard(name: "ChirpJamViewController", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "userPerfChirpJamController") as! ChirpJamViewController
            // Make a ChirpRecorder for the reply and set to the new ChirpJamViewController
            let allPerformances = performanceStore.getAllReplies(forPerformance: topPerformance)
            let recorder = ChirpRecorder(withArrayOfPerformances: allPerformances) // FIXME: This makes it a recorder, only want playback here.
            controller.recorder = recorder
            // FIXME: do something to make the ChirpJamViewController playback only.
            // Push the VC to the navigation controller.
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    /// Stop currently playing cell
    func stopCurrentlyPlayingPerformance() {
        if let cell = currentlyPlaying {
            cell.player!.stop()
            cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            currentlyPlaying = nil
        }
    }
    
    // Action if a play button is pressed in a cell
    @objc func playButtonPressed(sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = collectionView?.cellForItem(at: indexPath) as? UserPerfCollectionViewCell,
            let player = cell.player {
            if !player.isPlaying {
                stopCurrentlyPlayingPerformance() // Stop whatever other cell might be playing.
                currentlyPlaying = cell // Set this cell to start playing.
                player.play() // start playing playing
                cell.playButton.setImage(#imageLiteral(resourceName: "microjam-pause"), for: .normal) // set pause image
            } else {
                stopCurrentlyPlayingPerformance()
            }
        }
    }
    
    // Action if a reply button is pressed in a cell
    @objc func replyButtonPressed(sender: UIButton) {
        stopCurrentlyPlayingPerformance() // Stop whatever other cell might be playing.
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = collectionView?.cellForItem(at: indexPath) as? UserPerfCollectionViewCell,
            let player = cell.player {
            // Instantiate a ChirpJamViewController from storyboard
            let storyboard = UIStoryboard(name: "ChirpJamViewController", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "userPerfChirpJamController") as! ChirpJamViewController
            // Make a ChirpRecorder for the reply and set to the new ChirpJamViewController
            let recorder = ChirpRecorder(frame: CGRect.zero, player: player)
            controller.recorder = recorder
            // Push the VC to the navigation controller.
            navigationController?.pushViewController(controller, animated: true)
        }
    }

}

// MARK: Extension for scroll view delegate methods

extension UserPerfController {

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopCurrentlyPlayingPerformance()
    }
    
}

// MARK: Extension for PlayerDelegate methods

extension UserPerfController : PlayerDelegate {
    
    func progressTimerEnded() {
        stopCurrentlyPlayingPerformance()
    }
    
    func progressTimerStep() {
        // not used
    }
}
