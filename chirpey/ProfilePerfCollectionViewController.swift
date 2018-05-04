//
//  ProfilePerfCollectionViewController.swift
//  microjam
//
//  Created by Charles Martin on 2/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit
import DropDown

private let reuseIdentifier = "ProfilePerfCollectionViewCell"

/// Displays a profile screen including settings, user data and a collection of all previous performances.
class ProfilePerfCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    /// Local reference to the performanceStore singleton.
    let performanceStore = PerformanceStore.shared
    /// Local reference to the PerformerProfileStore.
    let profilesStore = PerformerProfileStore.shared
    /// Local reference to the userProfile
    let userProfile = UserProfile.shared
    /// Link to the users' profile data.
    let profile: PerformerProfile = UserProfile.shared.profile
    /// Performer to search for (must be set when instantiating this ViewController.
    var performerID: CKRecordID = CKRecordID(recordName: "__defaultOwner__")
    /// Performances by performer
    var loadedPerformances = [ChirpPerformance]()
    
    /// updates the profile screen's fields according to the present UserProfile data.
    func updateUI() {
        // Display appropriate views if user is not logged in.
        if userProfile.loggedIn {
            updateDataFromStore()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(UserPerfCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.backgroundColor = .white
        updateDataFromStore()
        
        // Subscribe to notification centre updates.
        NotificationCenter.default.addObserver(self, selector: #selector(updateDataFromStore), name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
        updateDataFromCloud()
    }
    
    /// Called by a notification when the UserProfile successfully loads a record.
    @objc func userProfileDataUpdated() {
        //print("ProfileVC: UserProfile updated, updating UI.")
        updateUI()
    }
    
    /// Updates the CollectionView from the local performance store data.
    @objc func updateDataFromStore() {
        //print("ProfileVC: Updating data from store")
        //print("ProfileVC: Searching for data about:", performerID)
        loadedPerformances = performanceStore.performances(byPerformer: performerID)
        //print("ProfileVC: updated data, found: ", loadedPerformances.count, "performances")
        collectionView?.reloadData()
    }
    
    /// Asks the performance store to fetch performances related to the current performerID from the cloud.
    func updateDataFromCloud() {
        print("ProfileVC: Updating data from cloud")
        performanceStore.fetchPerformances(byPerformer: performerID)
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
        cell.performanceImageView.backgroundColor = performance.backgroundColour.darkerColor
        cell.playButton.addTarget(self, action: #selector(previewPerformance(sender:)), for: .touchUpInside)
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
            // ChirpView.play(performance: cell.performance!)
            // FIXME: revise this statement to use a ChirpPlayer object.
        }
    }
    
}
