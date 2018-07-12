//
//  WorldJamsTableViewController.swift
//  microjam
//
//  Created by Charles Martin on 3/2/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// A UITableViewController for displaying MicroJams downloaded from the CloudKit feed - first screen in the app!
class WorldJamsTableViewController: UITableViewController {
    /// Local reference to the performanceStore singleton.
    let performanceStore = PerformanceStore.shared
    /// Global ID for wordJamCells.
    let worldJamCellIdentifier = "worldJamCell"
    /// Local reference to the PerformerProfileStore.
    let profilesStore = PerformerProfileStore.shared
    /// UILabel as a header view for warning messages.
    let headerView = NoAccountWarningStackView()
    /// A list of currently playing ChirpPlayers.
    var players = [ChirpPlayer]()
    /// A record of the currently playing table cell.
    var currentlyPlaying: PerformanceTableCell?
    
    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 420 // iPhone 7 height
        performanceStore.delegate = self
        profilesStore.delegate = self
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100) // header view used to display iCloud errors
        // Initialise the refreshControl
        self.refreshControl?.addTarget(performanceStore, action: #selector(performanceStore.fetchWorldJamsFromCloud), for: UIControlEvents.valueChanged)
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tableViewTapped)))
    }

    // Action if a play button is pressed in a cell
    @objc func playButtonPressed(sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? PerformanceTableCell,
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

    // Action if a reply button is pressed in a cell
    @objc func replyButtonPressed(sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? PerformanceTableCell,
            let player = cell.player {
            if let current = currentlyPlaying {
                current.player!.stop()
                current.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                currentlyPlaying = nil
            }
            if let controller = ChirpJamViewController.storyboardInstance() {
                let recorder = ChirpRecorder(frame: CGRect.zero, player: player)
                controller.recorder = recorder
                navigationController?.pushViewController(controller, animated: true)
                controller.title = "Reply" // set the navigation bar title.
            }
        }
    }
    
    /// Action when the plus bar item button is pressed.
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        print("Add Button Pressed")
        tabBarController?.selectedIndex = 1 // go to the second tab (jam!)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return performanceStore.feed.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: worldJamCellIdentifier, for: indexPath) as! PerformanceTableCell
        let performance = performanceStore.feed[indexPath.row]
        cell.player = ChirpPlayer()
        cell.player!.delegate = self
        
        /// Get all replies and add them to the player and chirp container.
        let performanceChain = performanceStore.getAllReplies(forPerformance: performance)
        for perfItem in performanceChain {
            let chirpView = ChirpView(with: cell.chirpContainer.bounds, andPerformance: perfItem)
            cell.chirpContainer.backgroundColor = perfItem.backgroundColour.darkerColor
            cell.player!.chirpViews.append(chirpView)
            cell.chirpContainer.addSubview(chirpView)
        }

        // Add constraints for cell.chirpContainer's subviews.
        for view in cell.chirpContainer.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.constrainEdgesTo(cell.chirpContainer)
        }

        /// Setup the metadata area.
        if let profile = profilesStore.getProfile(forPerformance: performance) {
            cell.avatarImageView.image = profile.avatar
            cell.performer.text = profile.stageName
        } else {
            cell.avatarImageView.image = nil
            cell.performer.text = performance.performer
        }
        cell.title.text = performance.dateString
        cell.instrument.text = performance.instrument
        cell.context.text = nonCreditString()
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
            if let cell = tableView.cellForRow(at: indexPath) as? PerformanceTableCell {
                // get performance from that cell
                let performance = performanceStore.feed[indexPath.row]
                // Tapped the avatar imageview
                if cell.avatarImageView.frame.contains(sender.location(in: cell.avatarImageView)) {
                    // Show user performances
                    let layout = UICollectionViewFlowLayout()
                    let controller = UserPerfController(collectionViewLayout: layout)
                    controller.performer = performance.performer
                    controller.performerID = performance.creatorID
                    navigationController?.pushViewController(controller, animated: true)
                // Tapped the preview image
                }
            }
        }
    }

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

    /// Loads a string crediting the original performer
    func creditString(originalPerformer: String) -> String {
        let output = "replied to " + originalPerformer
        return output
    }

    /// Loads a credit string for a solo performance
    func nonCreditString() -> String {
        let ind : Int = Int(arc4random_uniform(UInt32(PerformanceLabels.solo.count)))
        return PerformanceLabels.solo[ind]
    }

    // MARK: - Navigation

    /// Segue to view loaded jams.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }

    /// Segue back to the World Jam Table
    @IBAction func unwindToJamList(sender: UIStoryboardSegue) {

    }

    /// Adds a new ChirpPerformance to the top of the list and saves it in the data source.
    func addNew(performance: ChirpPerformance) {
        let newIndexPath = NSIndexPath(row: 0, section: 0)
        performanceStore.addNew(performance: performance)
        self.tableView.insertRows(at: [newIndexPath as IndexPath], with: .top)
    }

}

extension WorldJamsTableViewController: PlayerDelegate {

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

// MARK: - Scroll view delegate methods

extension WorldJamsTableViewController {
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let cell = currentlyPlaying {
            cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            cell.player!.stop()
            currentlyPlaying = nil
        }
    }
}

// MARK: - ModelDelegate methods

extension WorldJamsTableViewController: ModelDelegate {

    /// Conforms to ModelDelegate Protocol
    func modelUpdated() {
        //print("WJTVC: Model updated, reloading data.")
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
        print("WJTVC: Model could not be updated.")
        refreshControl?.endRefreshing()
        tableView.tableHeaderView = headerView
        let message: String
        if error.code == 1 {
            message = ErrorDialogues.icloudNotLoggedIn
        } else {
            message = error.localizedDescription
        }
        headerView.warningLabel.text = message
        headerView.isHidden = false
    }

}
