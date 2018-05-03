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
            // print("UserPerfVC: Searching for data about:", performerID)
            loadedPerformances = performanceStore.performances(byPerformer: performerID)
            // print("UserPerfController: updated data, found: ", loadedPerformances.count, "performances")
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
        // Set up cell with performance data
        cell.performance = performance
        cell.performanceImageView.image = performance.image
        cell.performanceImageView.backgroundColor = performance.backgroundColour
        cell.listenButton.addTarget(self, action: #selector(previewPerformance(sender:)), for: .touchUpInside)
        return cell
    }
    
    /// method called when an item is selected in the CollectionView - should open a non-recordable ChirpJamView to play back and show info.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //TODO: make this selection work properly by displaying a playback only ChirpJamView
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "chirpJamController") as! ChirpJamViewController
        //controller.newViewWith(performance: loadedPerformances[indexPath.item], withFrame: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    /// Plays back the performance in each Browse Cell when the listen button is tapped.
    @objc func previewPerformance(sender: UIButton) {
        if let superView = sender.superview?.superview {
            let cell = superView as! UserPerfCollectionViewCell
            ChirpView.play(performance: cell.performance!)
        }
    }

}
