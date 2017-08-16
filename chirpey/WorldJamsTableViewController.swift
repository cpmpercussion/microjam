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

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.rowHeight = 365
        performanceStore.delegate = self
        profilesStore.delegate = self
        self.refreshControl?.addTarget(performanceStore, action: #selector(performanceStore.fetchWorldJamsFromCloud), for: UIControlEvents.valueChanged)
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tableViewTapped)))
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return performanceStore.storedPerformances.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: worldJamCellIdentifier, for: indexPath) as! PerformanceTableCell
        
        let performance = performanceStore.storedPerformances[indexPath.row]
        
        /// Update the avatar if available, otherwise, do nothing and it will update later.
        if let profile = profilesStore.getProfile(forPerformance: performance) {
            cell.avatarImageView.image = profile.avatar
        }
        
        cell.avatarImageView.backgroundColor = .lightGray
        cell.avatarImageView.contentMode = .scaleAspectFill
        cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.width / 2
        cell.avatarImageView.clipsToBounds = true
        
        cell.title.text = performance.dateString
        cell.performer.text = performance.performer
        cell.instrument.text = performance.instrument
        
        cell.previewImage.image = performance.image
        cell.previewImage.layer.borderWidth = 1
        cell.previewImage.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        cell.previewImage.layer.cornerRadius = 4
        cell.previewImage.clipsToBounds = true
        
        cell.context.text = nonCreditString()

        var temp = performance // used to store replies as we fetch them.
        var images = [performance.image] // the stack of reply images.

        // Get the image from every reply
        while temp.replyto != "" {
            if let replyPerf = performanceStore.fetchPerformanceFrom(title: temp.replyto) {
                cell.context.text = creditString(originalPerformer: replyPerf.performer)
                images.append(replyPerf.image)
                temp = replyPerf
            } else {
                // break if the replyPerf can't be found.
                // TODO: in this case, the performance should be fetched from the cloud. but there isn't functionality in the store for this yet.
                break
            }
        }

        // Sum all the images into one and display
        cell.previewImage.image = self.createImageFrom(images: images)
        return cell
    }
    
    // MARK: UI Methods
    
    func tableViewTapped(sender: UIGestureRecognizer) {
        
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
                } else if cell.previewImage.frame.contains(sender.location(in: cell.previewImage)) {
                    
                    // Show the performance in a new ChirpJamController
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "chirpJamController") as! ChirpJamViewController
                    controller.newViewWith(performance: performanceStore.storedPerformances[indexPath.row], withFrame: nil)
                    
                    var selectedJam = performanceStore.storedPerformances[indexPath.row]
                    
                    while selectedJam.replyto != "" { // load up all replies.
                        // FIXME: fetching replies fails if they have not been downloaded from cloud.
                        if let reply = performanceStore.fetchPerformanceFrom(title: selectedJam.replyto) {
                            controller.newViewWith(performance: reply, withFrame: nil)
                            selectedJam = reply
                            print("WJTVC: cued a reply")
                        } else {
                            break // if a reply can't be found, stop loading the thread.
                        }
                    }
                    
                    // Present the chirpViewController
                    navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // Width of the preview image
        let width = view.frame.width - 64
        
        //returning height of image, pluss all the text
        return width + 120
        
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
        if segue.identifier == JamViewSegueIdentifiers.showDetailSegue { // view a performance.
            // load up current data into a JamViewController
            let jamDetailViewController = segue.destination as! ChirpJamViewController
            if let selectedJamCell = sender as? PerformanceTableCell {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                var selectedJam = performanceStore.storedPerformances[indexPath.row]
                jamDetailViewController.newViewWith(performance: selectedJam, withFrame: nil)

                while selectedJam.replyto != "" { // load up all replies.
                    // FIXME: fetching replies fails if they have not been downloaded from cloud.
                    if let reply = performanceStore.fetchPerformanceFrom(title: selectedJam.replyto) {
                        jamDetailViewController.newViewWith(performance: reply, withFrame: nil)
                        selectedJam = reply
                        print("WJTVC: cued a reply")
                    } else {
                        break // if a reply can't be found, stop loading the thread.
                    }
                }
            }
        }
    }

    /// Segue back to the World Jam Table
    @IBAction func unwindToJamList(sender: UIStoryboardSegue) {
//        if let sourceViewController = sender.source as? ChirpJamViewController, let performance = sourceViewController.loadedPerformance {
//            print("WJTVC: Unwound, found a performance:", performance.title())
//            if let selectedIndexPath = tableView.indexPathForSelectedRow { // passes if a row had been selected.
//                // Update existing performance
//                print("WJTVC: Unwound to a selected row:",selectedIndexPath.description)
//
//                if (appDelegate.storedPerformances[selectedIndexPath.row].title() != performance.title()) { // check if it's actually a reply.
//                    print("WJTVC: Found a reply performance:", performance.title())
//                    self.addNew(performance: performance) // add it.
//                }
//            } else {
//                // Add a new performance
//                print("WJTVC: Unwound with a new performance:", performance.title())
//                self.addNew(performance: performance)
//                sourceViewController.new() // resets the performance after saving it.
//            }
//        }
    }

    /// Adds a new ChirpPerformance to the top of the list and saves it in the data source.
    func addNew(performance: ChirpPerformance) {
        let newIndexPath = NSIndexPath(row: 0, section: 0)
        performanceStore.addNew(performance: performance)
        self.tableView.insertRows(at: [newIndexPath as IndexPath], with: .top)
    }

}

// MARK: - ModelDelegate methods

extension WorldJamsTableViewController: ModelDelegate {
    
    /// Conforms to ModelDelegate Protocol
    func modelUpdated() {
        print("WJTVC: Model updated, reloading data")
        refreshControl?.endRefreshing()
        tableView.reloadData()
    }
    
    /// Conforms to ModelDelegate Protocol
    func errorUpdating(error: NSError) {
        let message: String
        if error.code == 1 {
            message = "Log into iCloud on your device and make sure the iCloud drive is turned on for this app."
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
