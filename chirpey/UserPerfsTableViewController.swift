//
//  UserPerfsTableViewController.swift
//  microjam
//
//  Created by Charles Martin on 30/4/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

class UserPerfsTableViewController: UITableViewController {
    
    /// Local reference to the performanceStore singleton.
    let performanceStore = PerformanceStore.shared
    /// Global ID for wordJamCells.
    let userJamCellIdentifier = "userJamCell"
    /// Local reference to the PerformerProfileStore.
    let profilesStore = PerformerProfileStore.shared
    /// UILabel as a header view for warning messages.
    let headerView: UILabel = UILabel()
    /// A list of currently playing ChirpPlayers.
    var players = [ChirpPlayer]()
    /// A record of the currently playing table cell.
    var currentlyPlaying: UserPerfTableViewCell?
    
    // MARK: - Lifecycle
    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> UserPerfsTableViewController? {
        print("UserPerfsVC: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"UserPerfsViewController", bundle: nil)
        let navController = storyboard.instantiateInitialViewController() as? UINavigationController
        return navController?.topViewController as? UserPerfsTableViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 336 // iPhone 8 height
        performanceStore.delegate = self
        profilesStore.delegate = self
        
        // Initialise the headerView (not used unless needed to display an error).
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100)
        headerView.backgroundColor = UIColor.gray
        headerView.text = "A world of jams awaits you."
        headerView.textColor = UIColor.white
        headerView.textAlignment = NSTextAlignment.center
        headerView.lineBreakMode = .byWordWrapping
        headerView.numberOfLines = 0
        
        // Initialise the refreshControl
        self.refreshControl?.addTarget(performanceStore, action: #selector(performanceStore.fetchWorldJamsFromCloud), for: UIControlEvents.valueChanged)
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tableViewTapped)))
    }

    @objc func playButtonPressed(sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? UserPerfTableViewCell,
            let player = cell.player {
            if !player.isPlaying {
                currentlyPlaying = cell
                player.play()
                cell.playButton.setImage(#imageLiteral(resourceName: "microjam-pause"), for: .normal)
            } else {
                currentlyPlaying = nil
                player.stop()
                cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            }
        }
    }
    

    @objc func replyButtonPressed(sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? UserPerfTableViewCell,
            let player = cell.player {
            
            if let current = currentlyPlaying {
                current.player!.stop()
                current.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                currentlyPlaying = nil
            }
            
            // TODO: fix this, need to change to the other storyboard.
            // TODO: test this out.
            let storyboard = UIStoryboard(name: "ChirpJamViewController", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "chirpJamController") as! ChirpJamViewController
            let recorder = ChirpRecorder(frame: CGRect.zero, player: player)
            controller.recorder = recorder
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: Scroll view delegate methods
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let cell = currentlyPlaying {
            cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            cell.player!.stop()
            currentlyPlaying = nil
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return performanceStore.feed.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: userJamCellIdentifier, for: indexPath) as! UserPerfTableViewCell
        
        if let player = cell.player {
            for chirp in player.chirpViews {
                chirp.closePdFile()
                chirp.removeFromSuperview()
            }
        }
        
        let performance = performanceStore.feed[indexPath.row]
        cell.player = ChirpPlayer()
        cell.player!.delegate = self
        let chirpView = ChirpView(with: cell.chirpContainer.bounds, andPerformance: performance)
        cell.chirpContainer.backgroundColor = performance.backgroundColour.darkerColor
        cell.player!.chirpViews.append(chirpView)
        cell.chirpContainer.addSubview(chirpView)
        
        var current = performance
        
        // TODO: maybe don't load too too many performances.
        while current.replyto != "" {
            if let next = performanceStore.getPerformance(forID: CKRecordID(recordName: current.replyto)) {
                cell.chirpContainer.backgroundColor = next.backgroundColour.darkerColor
                let chirp = ChirpView(with: cell.chirpContainer.bounds, andPerformance: next)
                cell.player!.chirpViews.append(chirp)
                cell.chirpContainer.addSubview(chirp)
                current = next
            } else {
                // try to fetch from cloud if the reply can't be found.
                // Try to find the relevant reply and add to the store. - this is low priority and will update later.
                performanceStore.fetchPerformance(forID: CKRecordID(recordName: current.replyto))
                // Break.
                break
            }
        }
        
        // Add constraints for cell.chirpContainer's subviews.
        for view in cell.chirpContainer.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.constrainEdgesTo(cell.chirpContainer)
        }
        
        cell.playButton.tag = indexPath.row
        cell.playButton.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        cell.replyButton.tag = indexPath.row
        cell.replyButton.addTarget(self, action: #selector(replyButtonPressed), for: .touchUpInside)
        
        return cell
    }
    
    // MARK: UI Methods
    @objc func tableViewTapped(sender: UIGestureRecognizer) {
        let location = sender.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: location) {
            // Find out which cell was tapped
            if let cell = tableView.cellForRow(at: indexPath) as? UserPerfTableViewCell {
                // do something with this information.
            }
        }
    }
    
    // TODO: Put this function in one place only.
    /// Adds multiple images on top of each other
    func createImageFrom(images : [UIImage]) -> UIImage? {
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

extension UserPerfsTableViewController: PlayerDelegate {
    
    func progressTimerStep() {
        
    }
    
    func progressTimerEnded() {
        
        if let cell = currentlyPlaying {
            cell.player!.stop()
            cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            currentlyPlaying = nil
        }
    }
}

// MARK: - ModelDelegate methods

extension UserPerfsTableViewController: ModelDelegate {
    
    /// Conforms to ModelDelegate Protocol
    func modelUpdated() {
        print("UserPerfsVC: Model updated, reloading data.")
        refreshControl?.endRefreshing()
        tableView.tableHeaderView = nil
        
        if let cell = currentlyPlaying {
            cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            cell.player!.stop()
            currentlyPlaying = nil
        }
        tableView.reloadData()
    }
    
    /// Conforms to ModelDelegate Protocol
    func errorUpdating(error: NSError) {
        print("UserPerfsVC: Model could not be updated.")
        refreshControl?.endRefreshing()
        tableView.tableHeaderView = headerView
        let message: String
        if error.code == 1 {
            message = ErrorDialogues.icloudNotLoggedIn
        } else {
            message = error.localizedDescription
        }
        headerView.text = message
        headerView.isHidden = false
    }
    
}
