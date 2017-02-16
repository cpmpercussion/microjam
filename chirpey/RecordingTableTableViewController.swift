//
//  RecordingTableTableViewController.swift
//  microjam
//
//  Created by Charles Martin on 24/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

class RecordingTableTableViewController: UITableViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let recordingCellIdentifier = "perfRecCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem // system provided edit button.
        self.tableView.rowHeight = 90
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
        return appDelegate.recordedPerformances.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: recordingCellIdentifier, for: indexPath) as! PerformanceTableCell
        
        // Configure the cell...
        let performance = appDelegate.recordedPerformances[indexPath.row]
        cell.title.text = performance.dateString()
        cell.performer.text = performance.performer
        cell.instrument.text = performance.instrument
        cell.previewImage.image = performance.image
        return cell
    }
    
    @IBAction func unwindToPerformanceList(sender: UIStoryboardSegue) {
        print("AD: unwinding from somewhere.")
        if let sourceViewController = sender.source as? ChirpJamViewController, let performance = sourceViewController.loadedPerformance {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update existing performance
                appDelegate.recordedPerformances[selectedIndexPath.row] = performance
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else {
                // Add a new performance
                let newIndexPath = NSIndexPath(row: appDelegate.recordedPerformances.count, section: 0)
                appDelegate.addNew(performance: performance)
                self.tableView.insertRows(at: [newIndexPath as IndexPath], with: .bottom)
            }
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            appDelegate.recordedPerformances.remove(at: indexPath.row) // delete from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
        
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == JamViewSegueIdentifiers.showDetailSegue {
            // load up current data into a JamViewController
            let jamDetailViewController = segue.destination as! ChirpJamViewController
            if let selectedJamCell = sender as? PerformanceTableCell {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = appDelegate.recordedPerformances[indexPath.row]
                jamDetailViewController.loadedPerformance = selectedJam
                jamDetailViewController.state = ChirpJamModes.loaded
                jamDetailViewController.newPerformance = false
            }
        } else if segue.identifier == JamViewSegueIdentifiers.addNewSegue {
            // load up a new JamViewController
            /// FIXME: get this working.
            print("Local Jam Table View: Setting up a new performance")
            let newJamController = segue.destination as! ChirpJamViewController
            newJamController.state = ChirpJamModes.new
            newJamController.newPerformance = true
        }
    }
}
