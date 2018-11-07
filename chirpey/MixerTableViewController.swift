//
//  MixerTableViewController.swift
//  microjam
//  A controller for mixing different jams in layers.
//
//  Created by Charles Martin on 6/11/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

let mixerTableReuseIdentifier = "mixerTableReuseIdentifier"

class MixerTableViewController: UITableViewController {
    
    /// The layered jams to mix here.
    var chirpsToMix: [ChirpView]?
    /// Local reference to the PerformerProfileStore.
    let profilesStore = PerformerProfileStore.shared
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setColourTheme() // set colours
    }
    
    convenience init(withChirps chirps: [ChirpView]) {
        self.init()
        chirpsToMix = chirps
        self.modalPresentationStyle = .pageSheet
        tableView.register(MixerTableViewCell.self, forCellReuseIdentifier: mixerTableReuseIdentifier)
        tableView.rowHeight = 80
        // do some more init.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let chirpsToMix = chirpsToMix else {
            return 0
        }
        print("Mixer: \(chirpsToMix.count) layers")
        return chirpsToMix.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: mixerTableReuseIdentifier, for: indexPath) as! MixerTableViewCell
        cell.chirp = chirpsToMix![indexPath.row]
        cell.instrumentLabel.text = cell.chirp?.performance?.instrument
        cell.volumeSlider.tintColor = cell.chirp?.performance?.colour
        cell.volumeSlider.thumbTintColor = cell.chirp?.performance?.colour
        cell.volumeSlider.value = Float(cell.chirp?.volume ?? 1.0)
        
        if let perf = cell.chirp?.performance,
            let profile = profilesStore.getProfile(forPerformance: perf) {
            cell.avatarView.image = profile.avatar
        } else {
            cell.avatarView.image = #imageLiteral(resourceName: "empty-profile-image")
        }
        
        cell.setColourTheme() // set colour theme if reloading.

        return cell
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

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// Set up dark and light mode.
extension MixerTableViewController {
    
    @objc func setColourTheme() {
        if UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) {
            setDarkMode()
        } else {
            setLightMode()
        }
    }
    
    func setDarkMode() {
        tableView.backgroundColor = DarkMode.background
    }
    
    func setLightMode() {
        tableView.backgroundColor = LightMode.background
    }
}
