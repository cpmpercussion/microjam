//
//  ViewController.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit

/// TODO: how to tell between loaded and saved and just loaded?

/// Modes for the ChirpJameViewController: either new, recording, loaded, or playing.
struct ChirpJamModes {
    static let new = 0
    static let recording = 1
    static let loadedAndUnsaved = 2
    static let loadedAndSaved = 3
    static let loaded = 4
    static let playing = 5
}

struct JamViewSegueIdentifiers {
    static let replyToSegue = "ReplyToPerformance"
    static let addNewSegue = "AddPerformance"
    static let showDetailSegue = "ShowDetail"
}

struct TabBarItemTitles {
    static let worldTab = "world"
    static let jamTab = "jam!"
    static let settingsTab = "settings"
}

class ChirpJamViewController: UIViewController, UIDocumentInteractionControllerDelegate {
    let RECORDING_TIME = 5.0
    var state = ChirpJamModes.new
    var newPerformance : Bool = true
    var jamming : Bool = false
    var progress = 0.0
    var progressTimer : Timer?
    var loadedPerformance : ChirpPerformance?
    var replyToPerformance : ChirpPerformance?
    var replyto : String = ""
    /// An array of timers for each note in the scheduled playback.
    var playbackTimers : [Timer]?
    /// App delegate - in case we need to upload a performance.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate


    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var jamButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var performerLabel: UILabel!
    @IBOutlet weak var instrumentLabel: UILabel!
    @IBOutlet weak var chirpeySquare: ChirpView!
    @IBOutlet weak var recordingProgress: UIProgressView!
    @IBOutlet weak var savePerformanceButton: UIBarButtonItem!
    
    /// MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("JAMVC: Preparing for Segue")
        print("State: ", state)
        // FIXME: save the performance if the timer hasn't run out.
        self.jamming = false // stop jamming.
        if state == ChirpJamModes.recording {stopRecording() }
        if state == ChirpJamModes.playing { stopPlayback() } // stop any possible playback.
        if let barButton = sender as? UIBarButtonItem {
            if savePerformanceButton === barButton {
                print("JAMVC: Save button segue!")
            } else {
                print("JAMVC: Not jam button segue!")
                self.loadedPerformance = nil
            }
        }
        
        // FIXME: make sure this works.
        // Handling Starting a Reply
        if segue.identifier == JamViewSegueIdentifiers.replyToSegue {
            print("JAMVC: Preparing for a replyto segue.")
            if segue.destination is ChirpJamViewController {
                let newJamViewController = segue.destination as! ChirpJamViewController
                if let newreplytoperf = self.loadedPerformance {
                    print("JAMVC: destination jam will be a reply to: ", newreplytoperf.title())
                    newJamViewController.replyto = newreplytoperf.title()
                    newJamViewController.replyToPerformance = newreplytoperf
                }
            }
        }
    }
    
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        let isPresentingInAddPerformanceMode = presentingViewController is UINavigationController
        let presentedVC = UIApplication.shared.delegate?.window??.rootViewController as! UITabBarController // get the root VC (tabbarcontroller)
        //print("CURRENT TAB: ", presentedVC.tabBar.selectedItem?.title ?? "none")
        
        // Stop current actions
        stopTimer() // Stopping all Timers
        //stopRecording()
        stopPlayback() // stop any possible playback timers
        let possiblePerf : ChirpPerformance? = self.loadedPerformance
        self.loadedPerformance = nil
        
        // If it's in a Jam tab, need to reset viewcontroller.
        if (presentedVC.tabBar.selectedItem?.title == TabBarItemTitles.jamTab) { // check if we're in the Jam! tab.
            print("JAMVC: Cancel pressed from jam tab so do Jam Actions")
            /// FIXME: Remove this after initial testing: uploads cancelled performances as well.
            if let perf = possiblePerf { // only runs if there is a loadedPerformance.
                print("JAMVC: There is a performance loaded... saving before cancelling.")
                appDelegate.upload(performance: perf)
            }
            self.new() // Just load with a new performance.
        }
        
        // Finally Dismissing the performance.
        if isPresentingInAddPerformanceMode {
            print("JAMVC: Dismissing")
            dismiss(animated: true, completion: nil)
        } else {
            print("JAMVC: Popping")
            navigationController!.popViewController(animated: true)
        }
    }
    
    /// TODO: I don't think this function is ever actually called.
    @IBAction func unwindToJamView(sender: UIStoryboardSegue) {
        if sender.source is SettingsTableViewController {
            // Unwinding from settings screen.
            print("JAMVC: unwinding from a settings screen.")
            print("JAMVC: state",self.state)
            if (self.state == ChirpJamModes.new) { // if it's still a new jam, update the sound scheme
                print("JAMVC: updating the Pd file.")
                self.updateUI()
                (UIApplication.shared.delegate as! AppDelegate).openPdFile()
            }
        }
    }
    
    /// MARK: - UI Interaction Functions
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if let loadedPerformance = loadedPerformance {
            if (!self.chirpeySquare!.playing) {
                print("JAMVC: Going to start playing")
                // Start Playback
                statusLabel.text = "Playing..."
                self.playButton.setTitle("stop", for: UIControlState.normal)
                chirpeySquare?.playing = true
                self.state = ChirpJamModes.playing
                startProgressBar()
                self.playbackTimers = loadedPerformance.playback(inView: self.chirpeySquare)
            } else {
                // Cancel Playback
                print("JAMVC: Going to stop playing")
                self.jamming = false
                self.playButton.setTitle("play", for: UIControlState.normal)
                self.state = ChirpJamModes.loaded
                self.stopTimer()
            }
        } else {
            print("JAMVC: No loaded performance to be played back.")
        }
    }
    

    @IBAction func replyButtonPressed(_ sender: Any) {
        /// TODO: Implement some kind of reply system.
    }
    
    
    /// IBAction for the Jam Button
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        /// TODO: implement some kind of generative performing here!
        if (self.jamming) {
            // Stop Jamming
            self.jamButton.setTitle("jam", for: UIControlState.normal)
            self.jamming = false
            if (self.chirpeySquare!.playing) {
                self.playButtonPressed(self.playButton) // stop playing if already playing.
            }
        } else {
            // Start Jamming
            self.jamButton.setTitle("no jam", for: UIControlState.normal)
            self.jamming = true
            if (!self.chirpeySquare!.playing) {
                self.playButtonPressed(self.playButton) // start playing if not already playing.
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        self.recordingProgress!.progress = 0.0 // need to initialise the recording progress at zero.
        //self.updateUI() // just update UI on view did appear.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("JAMVC: viewDidAppear.")
        // what tab is this view under? can I figure that out?
        if (tabBarItem.title == TabBarItemTitles.jamTab) { // onlyrun this stuff in the jam tab
            (UIApplication.shared.delegate as! AppDelegate).openPdFile() // Make sure the correct Pd File is open
        }
        self.updateUI()
    }
    
    /// Resets to a new performance state.
    func new() {
        if playbackTimers != nil {
            self.chirpeySquare.performance?.cancelPlayback(timers: playbackTimers!)
        }
        self.chirpeySquare.startNewPerformance() // throwing away the current performance (if any)
        self.recordingProgress!.progress = 0.0
        self.jamming = false
        self.progress = 0.0
        self.state = ChirpJamModes.new
        self.loadedPerformance = nil
        self.newPerformance = true
        (UIApplication.shared.delegate as! AppDelegate).openPdFile() // open pd file.
        self.updateUI()
    }
    
    /// Load a ChirpPerformance for playback and reaction (most processing is done in updateUI).
    func load(performance: ChirpPerformance) {
        self.loadedPerformance = performance
        self.state = ChirpJamModes.loaded
        self.updateUI()
    }
    
    /// Update the UI labels and image only if there is a valid performance loaded.
    func updateUI() {
        print("JAMVC: Updating UI.")
        switch self.state {
        case ChirpJamModes.new:
            self.navigationItem.title = "New Performance"
            if (self.replyto == "") {
                self.statusLabel.text = "new" // new performance only.
            } else {
                self.statusLabel.text = "reply to: " + self.replyto // setting reply to text
            }
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.playButton.isEnabled = false
            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.instrumentLabel.text = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]
            (UIApplication.shared.delegate as! AppDelegate).openPdFile()
        case ChirpJamModes.recording:
            self.navigationItem.title = "recording..."
            self.statusLabel.text = "recording..."
            self.playButton.isEnabled = false
            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentLabel.text = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]
        case ChirpJamModes.playing:
            if let loadedPerformance = loadedPerformance {
                self.navigationItem.title = loadedPerformance.dateString()
                self.statusLabel.text = "Playing..."
                self.performerLabel.text = loadedPerformance.performer
                self.instrumentLabel.text = loadedPerformance.instrument
                self.chirpeySquare.image = loadedPerformance.image
                self.playButton.isEnabled = true
                self.jamButton.isEnabled = true
                self.replyButton.isEnabled = true // reply button enabled in loaded jams.
            }
        case ChirpJamModes.loaded:
            if let loadedPerformance = loadedPerformance {
                self.navigationItem.title = loadedPerformance.dateString()
                if (!self.newPerformance) {
                    // disable the save button, only if it's a loaded performance (not a new one)
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    print("Not a new performance, so disabling the save button.")
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
                self.statusLabel.text = "Loaded: " + (loadedPerformance.dateString())
                self.performerLabel.text = loadedPerformance.performer
                self.instrumentLabel.text = loadedPerformance.instrument
                self.chirpeySquare.image = loadedPerformance.image
                self.playButton.isEnabled = true
                self.jamButton.isEnabled = true
                self.replyButton.isEnabled = true // reply button enabled in loaded jams.
                print("JAMVC: opening Pd file for loaded performance.")
                (UIApplication.shared.delegate as! AppDelegate).openPdFile(withName: loadedPerformance.instrument) // open Pd File.
            }
        default:
            self.navigationItem.title = "performance"
            self.statusLabel.text = "new"
            self.playButton.isEnabled = false
            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentLabel.text = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]
        }
    }

    ///
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Recording Functions
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        if (self.state == ChirpJamModes.new) {
            NSLog("JAMVC: Starting a recording.")
            self.startProgressBar()
            self.chirpeySquare?.recording = true
            self.state = ChirpJamModes.recording
            self.updateUI()
        }
    }
    
    /// Starts a recurring timer that increments the progress bar.
    func startProgressBar() {
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
    }
    
    /// Automatically triggered when recording time finishes.
    func stopTimer() {
        /// FIXME: Incorporate this method with stopPlayback?
        NSLog("JAMVC: Stop Timer Called (either finished or cancelled).")
        if (self.chirpeySquare!.recording) {
            self.stopRecording()
            self.chirpeySquare!.recording = false
        } else {
            self.stopPlayback()
            self.chirpeySquare!.playing = false
        }
        self.progressTimer?.invalidate()
        self.progress = 0.0
        self.recordingProgress?.progress = 0.0
        if (self.jamming) {
            // start the playback again!
            print("JAMVC: Restarting playback for the jam.")
            // Start Playback
            statusLabel.text = "Playing..."
            self.playButton.setTitle("stop", for: UIControlState.normal)
            chirpeySquare?.playing = true
            self.state = ChirpJamModes.playing
            startProgressBar()
            self.playbackTimers = loadedPerformance?.playback(inView: self.chirpeySquare)
        }
    }
    
    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping recording; now loading the recorded performance.")
        if let lastPerformance = self.chirpeySquare!.closeRecording() {
            lastPerformance.replyto = self.replyto
            self.load(performance: lastPerformance)
        }
    }
    
    /// Stop playback and cancel timers.
    func stopPlayback() {
        print("JAMVC: Stopping any requested playback")
        if playbackTimers != nil {
            print("JAMVC: Stopping the timers")
            self.chirpeySquare.performance?.cancelPlayback(timers: playbackTimers!)
        }
        self.playButton.setTitle("play", for: UIControlState.normal)
        self.state = ChirpJamModes.loaded
        self.updateUI()
    }
    
    /// Increment the recording progress bar by 10ms; called automatically by timers.
    func incrementRecordingProgress(_ : Timer) {
        self.progress += 0.01;
        self.recordingProgress?.progress = Float(self.progress / self.RECORDING_TIME)
        if (self.progress >= self.RECORDING_TIME) {self.stopTimer()}
    }
    
    // MARK: - Touch methods
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        let p = touches.first?.location(in: self.chirpeySquare);
        if (self.chirpeySquare!.bounds.contains(p!) && self.state == ChirpJamModes.new) {
                print("JAMVC: Starting a Recording")
                self.startRecording()
        }
    }
    
    /// Exports a loaded performance via share-sheets. Ultimately not very useful!
    @IBAction func exportLoadedPerformance() {
        // TODO: Delete this function if not used soon.
        if ((state == ChirpJamModes.loaded) || (state == ChirpJamModes.playing)) {
            print("JAMVC: Exporting the loaded performance")            
            if let csv = loadedPerformance?.csv() {
                print(loadedPerformance?.title() ?? "No Title!")
                let path = loadedPerformance?.writeToFile(csv: csv)
                let url = URL(fileURLWithPath: path!)
                let interactionController = UIDocumentInteractionController(url: url)
                interactionController.delegate = self
                let result = interactionController.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true)
                if result == false {
                    // Fall back to "options" view:
                    interactionController.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true)
                }
            }
        }
    }

}
