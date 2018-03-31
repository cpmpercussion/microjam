//
//  WorldJamsTableViewController.swift
//  microjam
//
//  Created by Charles Martin on 3/2/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

class WorldJamsTableViewController: UITableViewController {

    /// Local reference to the performanceStore singleton.
    let performanceStore = PerformanceStore.shared
    /// Global ID for wordJamCells.
    let worldJamCellIdentifier = "worldJamCell"
    /// Local reference to the PerformerProfileStore
    let profilesStore = PerformerProfileStore.shared

    var players = [ChirpPlayer]()
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

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 420 // iPhone 7 height
        performanceStore.delegate = self
        profilesStore.delegate = self
        self.refreshControl?.addTarget(performanceStore, action: #selector(performanceStore.fetchWorldJamsFromCloud), for: UIControlEvents.valueChanged)
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tableViewTapped)))
    }

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

    
    @objc func replyButtonPressed(sender: UIButton) {

        let indexPath = IndexPath(row: sender.tag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? PerformanceTableCell,
            let player = cell.player {
            
            if let current = currentlyPlaying {
                current.player!.stop()
                current.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                currentlyPlaying = nil
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: worldJamCellIdentifier, for: indexPath) as! PerformanceTableCell

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

                // Tapped the avatar imageview
                if cell.avatarImageView.frame.contains(sender.location(in: cell.avatarImageView)) {
                    // Show user performances
                    let layout = UICollectionViewFlowLayout()
                    let controller = UserPerfController(collectionViewLayout: layout)
                    controller.performer = performanceStore.storedPerformances[indexPath.row].performer
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

// MARK: - ModelDelegate methods

extension WorldJamsTableViewController: ModelDelegate {

    /// Conforms to ModelDelegate Protocol
    func modelUpdated() {
        print("WJTVC: Model updated, reloading data")
        refreshControl?.endRefreshing()
        
        if let cell = currentlyPlaying {
            cell.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            cell.player!.stop()
            currentlyPlaying = nil
        }
        
        tableView.reloadData()
    }

    /// Conforms to ModelDelegate Protocol
    func errorUpdating(error: NSError) {
        let message: String
        if error.code == 1 {
            message = ErrorDialogues.icloudNotLoggedIn
        } else {
            message = error.localizedDescription
        }
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

}
