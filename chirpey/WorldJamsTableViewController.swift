//
//  WorldJamsTableViewController.swift
//  microjam
//
//  Created by Charles Martin on 3/2/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class WorldJamsTableViewController: UITableViewController, ModelDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let worldJamCellIdentifier = "worldJamCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.tableView.rowHeight = 365
        self.appDelegate.delegate = self
        self.refreshControl?.addTarget(appDelegate, action: #selector(appDelegate.fetchWorldJamsFromCloud), for: UIControlEvents.valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // borrowed so far from https://www.raywenderlich.com/134694/cloudkit-tutorial-getting-started
    func modelUpdated() {
        refreshControl?.endRefreshing()
        tableView.reloadData()
    }

    // borrowed so far from https://www.raywenderlich.com/134694/cloudkit-tutorial-getting-started
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

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.storedPerformances.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: worldJamCellIdentifier, for: indexPath) as! PerformanceTableCell
        let performance = appDelegate.storedPerformances[indexPath.row]
        cell.title.text = performance.dateString()
        cell.performer.text = performance.performer
        cell.instrument.text = performance.instrument
        cell.previewImage.image = performance.image
        cell.context.text = nonCreditString()

        var temp = performance // used to store replies as we fetch them.
        var images = [performance.image] // the stack of reply images.

        // Get the image from every reply
        while temp.replyto != "" {
            if let replyPerf = appDelegate.fetchPerformanceFrom(title: temp.replyto) {
                cell.context.text = creditString(originalPerformer: replyPerf.performer)
                images.append(replyPerf.image)
                temp = replyPerf
            } else {
                // break if the replyPerf can't be found.
                // TODO: in this case, the performance should be fetched from the cloud. but there isn't functionality in the store for this yet.
                break
            }
            print("WJTVC: loaded a reply.")
        }

        // Sum all the images into one and display
        cell.previewImage.image = self.createImageFrom(images: images)
        return cell
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


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */


    // MARK: - Navigation

    /// Segue to view loaded jams.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == JamViewSegueIdentifiers.showDetailSegue { // view a performance.
            // load up current data into a JamViewController
            let jamDetailViewController = segue.destination as! ChirpJamViewController
            if let selectedJamCell = sender as? PerformanceTableCell {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                var selectedJam = appDelegate.storedPerformances[indexPath.row]
                jamDetailViewController.newViewWith(performance: selectedJam, withFrame: nil)

                while selectedJam.replyto != "" { // load up all replies.
                    // FIXME: fetching replies fails if they have not been downloaded from cloud.
                    if let reply = appDelegate.fetchPerformanceFrom(title: selectedJam.replyto) {
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
        appDelegate.addNew(performance: performance)
        self.tableView.insertRows(at: [newIndexPath as IndexPath], with: .top)
    }

}
