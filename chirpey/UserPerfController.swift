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
class UserPerfController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
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
    /// Performer to search for (must be set when instantiating this ViewController).
    var performerID: CKRecord.ID?
    /// Performances by performer
    var loadedPerformances = [ChirpPerformance]()
    /// Ref to a (single) currently playing cell
    var currentlyPlaying: UserPerfCollectionViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(PerformerInfoHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.register(UserPerfCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(updateDataFromStore), name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfileDisplay), name: NSNotification.Name(rawValue: performerProfileUpdatedKey), object: nil)


        // Set up long press gesture recogniser:
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        collectionView?.addGestureRecognizer(lpgr)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Attempt to load the data and display it.
        /// TODO: is there some reason not to call super here?
        super.viewWillAppear(animated)
        setColourTheme()
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
            DispatchQueue.main.async {
                self.loadedPerformances = self.performanceStore.performances(byPerformer: performerID)
                self.collectionView?.reloadData()
            }
        }
    }
    
    /// Updates the profile display if it has been updated in the profile
    @objc func updateProfileDisplay() {
        // Do something.
        if let suppViews = collectionView?.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader),
            let headerView = suppViews.first as? PerformerInfoHeader,
            let performerID = performerID,
            let profile = profilesStore.getProfile(forID: performerID) {
            headerView.avatarImageView.image = profile.avatar
            headerView.performerNameLabel.text = profile.stageName
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
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! PerformerInfoHeader
        headerView.frame.size.height = PerformerInfoHeader.headerHeight
        if let performerID = performerID,
            let profile = profilesStore.getProfile(forID: performerID) {
            headerView.avatarImageView.image = profile.avatar
            headerView.performerNameLabel.text = profile.stageName
        } else {
            headerView.avatarImageView.image = #imageLiteral(resourceName: "empty-profile-image") // set to placeholder image while loading.
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
        cell.menuButton.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
        return cell
    }
    
    //TODO: make this selection work properly by displaying a playback only ChirpJamView
    /// method called when an item is selected in the CollectionView - should open a non-recordable ChirpJamView to play back and show info.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        stopCurrentlyPlayingPerformance()
        // Get the cell, performance and a ChirpJamVC
        if let cell = collectionView.cellForItem(at: indexPath) as? UserPerfCollectionViewCell,
            let topPerformance = cell.performance {
            let allPerformances = performanceStore.getAllReplies(forPerformance: topPerformance)
            let controller = ChirpJamViewController.instantiateController(forArrayOfPerformances: allPerformances)
            navigationController?.pushViewController(controller, animated: true)
            // Set the navigation bar title
            controller.title = "View Performance"
        }
    }
    
    func openContextualMenu(forCell cell: UserPerfCollectionViewCell) {
        print("Detail menu for performance. Belongs to user:", cell.performance?.creatorID == UserProfile.shared.record?.creatorUserRecordID)
        // Make an alert controller
        let titleString = cell.performance?.humanTitle() ?? "Options"
        let alertActionCell = UIAlertController(title: titleString, message: nil, preferredStyle: .actionSheet)
        
        let shareAction = UIAlertAction(title: "Share", style: .default, handler: {action in
            print("Sharing the cell image") // just image
            if let image = cell.performance?.image {
                // Create solid color UIImage in background color
                let backgroundColorAsImage = UIImage.imageWithColor(color:cell.performanceImageView.backgroundColor!,size:CGSize(width: image.size.width, height: image.size.height))
                // Create new UIImage by layering background color image and image
                let imageWithBgc = UIImage.createImageFrom(images:[image, backgroundColorAsImage])
                // Share
                let activityViewController = UIActivityViewController(activityItems: [imageWithBgc!] , applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true, completion: nil)
            }
        })
        
        // delete action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            // Do the deleting.
            print("Cell ID was:", cell.performance?.performanceID ?? "not found!")
            if let recID = cell.performance?.performanceID {
                self.performanceStore.deleteUserPerformance(withID: recID)
            }
            print("Cell Removed")
            self.collectionView?.reloadData()
        })
        // Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            print("Cancel actionsheet")
        })
        alertActionCell.addAction(shareAction)
        if cell.performance?.creatorID == UserProfile.shared.record?.creatorUserRecordID {
            // Only add delete if it relates to the present user.
            alertActionCell.addAction(deleteAction)
        }
        alertActionCell.addAction(cancelAction)
        
        if let popoverPresentationController = alertActionCell.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverPresentationController.permittedArrowDirections = .init(rawValue: 0)
        }
        
        self.present(alertActionCell, animated: true, completion: nil)
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
            let controller = ChirpJamViewController.instantiateReplyController(forPlayer: player)
            // Push the VC to the navigation controller.
            navigationController?.pushViewController(controller, animated: true)
            controller.title = "Reply"
        }
    }
    
    // Action if the menu button is pressed in a cell
    @objc func menuButtonPressed(sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = collectionView?.cellForItem(at: indexPath) as? UserPerfCollectionViewCell {
            openContextualMenu(forCell: cell)
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizer.State.ended {return}
        // Delete selected Cell
        let point = gestureRecognizer.location(in: self.collectionView)
        if let indexPath = self.collectionView?.indexPathForItem(at: point),
            let cell = self.collectionView?.cellForItem(at: indexPath) as? UserPerfCollectionViewCell {
            openContextualMenu(forCell: cell)
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
    
    func progressTimerStarted() {
        // not used.
    }
    
    func progressTimerEnded() {
        stopCurrentlyPlayingPerformance()
    }
    
    func progressTimerStep() {
        // not used
    }
}



extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIImage {
    class func createImageFrom(images : [UIImage]) -> UIImage? {
    if let size = images.first?.size {
        UIGraphicsBeginImageContext(size)
        let areaSize = CGRect(x: 0, y: 0, width:size.width, height: size.height)
        for image in images.reversed() {
            image.draw(in: areaSize, blendMode: CGBlendMode.normal, alpha: 1.0)
        }
        let outImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return outImage
    }
    return nil
    }
}

/// Extension for Color Themes
extension UserPerfController {
    
    @objc func setColourTheme() {
        UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) ? setDarkMode() : setLightMode()
    }
    
    func setDarkMode() {
        view.backgroundColor = DarkMode.background
        collectionView.backgroundColor = DarkMode.background
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = DarkMode.highlight
        navigationController?.view.backgroundColor = DarkMode.background
    }
    
    func setLightMode() {
        view.backgroundColor = LightMode.background
        collectionView.backgroundColor = LightMode.background
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = LightMode.highlight
        navigationController?.view.backgroundColor = LightMode.background
    }
}
