//
//  ViewController.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit
import DropDown

// TODO: how to tell between loaded and saved and just loaded?

class ChirpJamViewController: UIViewController, UIDocumentInteractionControllerDelegate {
    /// Maximum allowed recording time.
    let RECORDING_TIME = 5.0
    var state = ChirpJamModes.new
    var newPerformance : Bool = true
    var jamming : Bool = false
    var progress = 0.0
    /// Timer for progress in recording and playback.
    var progressTimer : Timer?
    /// Storage of the original performance for a reply.
    var performanceViews : [ChirpView] = [ChirpView]() // Previous performances, should be populated if this is a reply
    var recordView : ChirpView? //
    /// Addition ChirpView for storage of the original performance for a reply.
    var replyto : String?
    /// App delegate - in case we need to upload a performance.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    /// Dropdown menu for selecting SoundScheme
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme
    
    var loadedPerformance : ChirpPerformance?

    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var jamButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var performerLabel: UILabel!
    @IBOutlet weak var referenceView: ChirpView!
    @IBOutlet weak var recordingProgress: UIProgressView!
    @IBOutlet weak var savePerformanceButton: UIBarButtonItem!
    @IBOutlet weak var instrumentButton: UIButton!
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("JAMVC: Preparing for Segue. Current state:", self.state)
        // FIXME: save the performance if the timer hasn't run out.
        self.jamming = false // stop jamming.
        if state == ChirpJamModes.recording {stopRecording() }
        if state == ChirpJamModes.playing { stopPlayback() } // stop any possible playback.
        if let barButton = sender as? UIBarButtonItem {
            // TODO: Is this check actually used?
            if savePerformanceButton === barButton {
                print("JAMVC: Save button segue!")
                if let recordView = self.recordView {
                    if let performance = recordView.performance {
                        appDelegate.addNew(performance: performance)
                    }
                }
            } else {
                print("JAMVC: Not jam button segue!")
                // MARK: Put something here
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("JAMVC: viewDidAppear.")
        // Check what tab the VC exists under and re-open patch if necessary.
        if (tabBarItem.title == TabBarItemTitles.jamTab) { // onlyrun this stuff in the jam tab
            //self.recordView.openPdFile() // Make sure the correct Pd File is open
        }
        self.updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        self.recordingProgress!.progress = 0.0 // need to initialise the recording progress at zero.
        
        if !self.performanceViews.isEmpty {
            for view in self.performanceViews {
                view.frame = self.referenceView.frame
                self.add(chirpView: view)
            }
            
            self.replyto = self.performanceViews.first?.performance?.title()
            self.newPerformance = false
            self.state = ChirpJamModes.loaded
            self.updateUI()
        } else {
            self.newRecordView()
        }
        
        self.referenceView!.isUserInteractionEnabled = false
        
        // Soundscheme Dropdown initialisation.
        // FIXME: make sure dropdown is working.
        soundSchemeDropDown.anchorView = self.instrumentButton // anchor dropdown to intrument button
        soundSchemeDropDown.dataSource = Array(SoundSchemes.namesForKeys.values) // set dropdown datasource to available SoundSchemes
        soundSchemeDropDown.direction = .bottom
        
        // Action triggered on selection
        soundSchemeDropDown.selectionAction = {(index: Int, item: String) -> Void in
            print("DropDown selected:", index, item)
            UserDefaults.standard.set(SoundSchemes.keysForNames[item], forKey: SettingsKeys.soundSchemeKey)
            UserDefaults.standard.synchronize()
            self.updateUI()
        }
    }
    
    //    override func viewDidLayoutSubviews() {
    //        print("Laid Out Subviews.")
    //        print("JAMVC: Main ChirpView frame:", self.chirpeySquare.frame.size)
    //        print("JAMVC:Reply ChirpView frame:", self.replyToPerformanceView?.frame.size ?? "None Available")
    //        print("JAMVC:Reply ChirpView comod:", self.replyToPerformanceView?.contentMode ?? "None Available")
    //    }
    
    
    func newViewWith(performance : ChirpPerformance) {
        
        let newView = ChirpView(frame: CGRect.zero, performance: performance)
        newView.isUserInteractionEnabled = false // Not used for recording
        newView.backgroundColor = UIColor.clear
        self.performanceViews.append(newView)
    }
    
    /// Resets to a new performance state.
    func newRecordView() {
        
        if let recordView = self.recordView {
            // Creating a new ChirpView
            let newView = ChirpView(frame: self.referenceView!.frame)
            newView.isUserInteractionEnabled = true
            newView.backgroundColor = UIColor.clear
            newView.openPdFile()
            
            // Removing current ChirpView
            recordView.removeFromSuperview()
            
            // Adding new view to screen
            self.recordView = newView
            self.add(chirpView: newView)
        
        } else {
            self.recordView = ChirpView(frame: self.referenceView!.frame)
            self.recordView!.isUserInteractionEnabled = true
            self.recordView!.backgroundColor = UIColor.clear
            self.recordView!.openPdFile()
            
            self.add(chirpView: self.recordView!)
        }
        
        self.newPerformance = true
        self.jamming = false
        self.state = ChirpJamModes.new
        self.recordingProgress!.progress = 0.0
        self.progress = 0.0
        self.updateUI()
        
    }
    
    /// IBAction for Cancel (bar) button. stops playback/recording and dismisses present performance.
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        
        // Stop current actions
        stopTimer() // Stopping all Timers
        //stopRecording()
        stopPlayback() // stop any possible playback
        
        if let recordView = self.recordView {
            if self.performanceViews.isEmpty {
                // No loaded performances means we're in the jam tab, just reset to a new record view
                self.replyButton.setTitle("Reply", for: .normal)
                self.newRecordView()
            } else {
                // Reset back to the loaded performances
                recordView.removeFromSuperview()
                self.recordView = nil
                self.replyButton.setTitle("Reply", for: .normal)
                self.newPerformance = false
                self.state = ChirpJamModes.loaded
                self.jamming = false
                self.recordingProgress!.progress = 0.0
                self.progress = 0.0
                self.updateUI()
            }
        } else {
            // No record view means we have loaded performances, but haven't recorded anything yet. Just return to world table view
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func unwindToJamView(sender: UIStoryboardSegue) {
        // FIXME: I don't think this function is ever actually called. Find out and delete if necessary.
        if sender.source is SettingsTableViewController {
            // Unwinding from settings screen.
            print("JAMVC: unwinding from a settings screen. Current state:", self.state)
            if (self.state == ChirpJamModes.new) { // if it's still a new jam, update the sound scheme
                print("JAMVC: updating the Pd file.")
                self.updateUI()
                //self.recordView.reloadPatch() // could be openPdFile()
            }
        }
    }
    
    func playBackPerformances() {
        
        // Play every performance in the stack
        for view in self.performanceViews {
            if let performance = view.performance {
                performance.playback(inView: view)
            }
        }
        
        // Playback recorded performence
        if self.state != ChirpJamModes.recording {
            if let recordView = self.recordView {
                if let performance = recordView.performance {
                    performance.playback(inView: self.recordView!)
                }
            }
        }
    }
    
    // MARK: - UI Interaction Functions
    
    /// IBAction for the play button. Starts playback of performance and replies iff in loaded mode. Stops if already playing.
    @IBAction func playButtonPressed(_ sender: UIButton) {
        
        // TODO: Implement playbutton
        
        if self.state == ChirpJamModes.playing || self.state == ChirpJamModes.recording {
            self.playButton.setTitle("play", for: .normal)
            self.stopTimer()
        
        } else {
            if !self.jamming {
                self.playButton.setTitle("stop", for: .normal)
            }
            self.state = ChirpJamModes.playing
            self.updateUI()
            self.recordingProgress!.progress = 0.0
            self.progress = 0.0
            self.startProgressBar()
            self.playBackPerformances()
        }
    }

    /// IBAction for the SoundScheme label. Opens a dropdown menu for selection when in "new" state.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        // TODO: should there be some kind of change in loaded mode? Like changing the user's layer sound, or adjusting the previous performers' sound?
        if self.state == ChirpJamModes.new {
            soundSchemeDropDown.show()
        }
    }
    
    @IBAction func replyButtonPressed(_ sender: Any) {
        // TODO: Implement some kind of reply system.
        print("JAMVC: Reply button pressed");
        
        self.replyButton!.setTitle("Reset", for: .normal)
        self.stopTimer()
        self.newRecordView()
    }
    
    /// IBAction for the Jam Button
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        // TODO: implement some kind of generative performing here!
        if (self.jamming) {
            // Stop Jamming
            self.jamButton.setTitle("jam", for: UIControlState.normal)
            self.jamming = false
            if (self.state == ChirpJamModes.playing) {
                self.playButtonPressed(self.playButton) // stop playing if already playing.
            }
        } else {
            // Start Jamming
            self.jamButton.setTitle("no jam", for: UIControlState.normal)
            self.jamming = true
            if (self.state != ChirpJamModes.playing) {
                self.playButtonPressed(self.playButton) // start playing if not already playing.
            }
        }
    }
    
    // Adds the chirpView to superview, and adds constraints
    func add(chirpView : ChirpView) {
        
        self.view.addSubview(chirpView)
        let horizontalConstraint = NSLayoutConstraint(item: chirpView,
                                                      attribute: NSLayoutAttribute.centerX,
                                                      relatedBy: NSLayoutRelation.equal,
                                                      toItem: referenceView,
                                                      attribute: NSLayoutAttribute.centerX,
                                                      multiplier: 1,
                                                      constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: chirpView,
                                                    attribute: NSLayoutAttribute.centerY,
                                                    relatedBy: NSLayoutRelation.equal,
                                                    toItem: referenceView,
                                                    attribute: NSLayoutAttribute.centerY,
                                                    multiplier: 1,
                                                    constant: 0)
        let leftConstraint = NSLayoutConstraint(item: chirpView,
                                                attribute: NSLayoutAttribute.left,
                                                relatedBy: NSLayoutRelation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutAttribute.left,
                                                multiplier: 1,
                                                constant: 0)
        let rightConstraint = NSLayoutConstraint(item: chirpView,
                                                 attribute: NSLayoutAttribute.right,
                                                 relatedBy: NSLayoutRelation.equal,
                                                 toItem: referenceView,
                                                 attribute: NSLayoutAttribute.right,
                                                 multiplier: 1,
                                                 constant: 0)
        let topConstraint = NSLayoutConstraint(item: chirpView,
                                               attribute: NSLayoutAttribute.top,
                                               relatedBy: NSLayoutRelation.equal,
                                               toItem: referenceView,
                                               attribute: NSLayoutAttribute.top,
                                               multiplier: 1,
                                               constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: chirpView,
                                                  attribute: NSLayoutAttribute.bottom,
                                                  relatedBy: NSLayoutRelation.equal,
                                                  toItem: referenceView,
                                                  attribute: NSLayoutAttribute.bottom,
                                                  multiplier: 1,
                                                  constant: 0)
        let chirpHoriz = NSLayoutConstraint(item: referenceView,
                                            attribute: NSLayoutAttribute.centerX,
                                            relatedBy: NSLayoutRelation.equal,
                                            toItem: self.view,
                                            attribute: NSLayoutAttribute.centerX,
                                            multiplier: 1,
                                            constant: 0)
        self.view.addConstraints([horizontalConstraint,verticalConstraint,chirpHoriz,leftConstraint,rightConstraint,topConstraint,bottomConstraint])
        chirpView.contentMode = .scaleToFill
    }
    
    
    /// Update the UI labels and image only if there is a valid performance loaded.
    func updateUI() {
        print("JAMVC: Updating UI.")
        
        switch self.state {
            
        case ChirpJamModes.new:
            
            self.navigationItem.title = "New Performance"
            if let replytext = self.replyto {
                self.statusLabel.text = "reply to: " + replytext // setting reply to text
            } else {
                self.statusLabel.text = "new" // new performance only.
            }
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.playButton.isEnabled = false
            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.instrumentButton.setTitle(SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)], for: .normal)
            if let recordView = self.recordView {
                recordView.openPdFile()
            }
            
        case ChirpJamModes.recording:
            
            self.navigationItem.title = "recording..."
            self.statusLabel.text = "recording..."
            self.playButton.isEnabled = false
            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentButton.setTitle(SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)], for: .normal)
            
        case ChirpJamModes.playing:
            
            var loadedPerformance = self.performanceViews.last?.performance
            
            if let recordView = self.recordView {
                if let performance = recordView.performance {
                    loadedPerformance = performance
                }
            }
            
            self.navigationItem.title = loadedPerformance?.dateString()
            self.statusLabel.text = "Playing..."
            self.performerLabel.text = loadedPerformance?.performer
            self.instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)
            self.playButton.isEnabled = true
            self.jamButton.isEnabled = true
            
            if self.newPerformance {
                self.replyButton.isEnabled = false // Should not be able to reply to your own performance
            } else {
                self.replyButton.isEnabled = true // reply button enabled in loaded jams.
            }
            
        case ChirpJamModes.loaded:
            
            var loadedPerformance = self.performanceViews.last?.performance
            
            if let recordView = self.recordView {
                if let performance = recordView.performance {
                    loadedPerformance = performance
                }
            }
            
            self.navigationItem.title = loadedPerformance?.dateString()
            if (!self.newPerformance) {
                // disable the save button, only if it's a loaded performance (not a new one)
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                self.replyButton.isEnabled = true // reply button enabled in loaded jams.
                print("JAMVC: Not a new performance, so disabling the save button.")
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.replyButton.isEnabled = false // reply button enabled in loaded jams.

            }
            self.statusLabel.text = "Loaded: "
            self.performerLabel.text = loadedPerformance?.performer
            self.instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)
            // FIXME: Better way to reset images for ChirpViews
            for view in self.performanceViews {
                view.image = view.performance?.image
            }
            if let recordView = self.recordView {
                recordView.image = recordView.performance?.image
            }
            self.playButton.isEnabled = true
            self.jamButton.isEnabled = true
            print("JAMVC: opening Pd file for loaded performance.")
            //self.chirpeySquare.openPdFile(withName: loadedPerformance.instrument) // open Pd File.
            
        default:
            
            self.navigationItem.title = "performance"
            self.statusLabel.text = "new"
            self.playButton.isEnabled = false
            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentButton.setTitle(SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)], for: .normal)
        }
    }
    
    /// Stop playback and cancel timers.
    func stopPlayback() {
        print("JAMVC: Stopping any requested playback")
        for view in self.performanceViews {
            if let performance = view.performance {
                performance.cancelPlayback()
            }
        }
        if let recordView = self.recordView {
            if let performance = recordView.performance {
                performance.cancelPlayback()
            }
        }
    }
    
    /// Load a ChirpPerformance for playback and reaction (most processing is done in updateUI).
    func load(performance: ChirpPerformance) {
        self.state = ChirpJamModes.loaded
        self.recordView!.isUserInteractionEnabled = false
        self.updateUI()
    }
    
    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping recording; now loading the recorded performance.")
        if let lastPerformance = self.recordView!.closeRecording() {
            if let replytext = self.replyto {
                lastPerformance.replyto = replytext
            }
            self.load(performance: lastPerformance)
        }
    }
    
    /// Automatically triggered when recording time finishes.
    func stopTimer() {
        // FIXME: Incorporate this method with stopPlayback?
        // FIXME: Make sure that the reply performances are reset as well as the main performance.
        NSLog("JAMVC: Stop Timer Called (either finished or cancelled).")
        if let recordView = self.recordView {
            if recordView.recording {
                self.stopRecording()
                recordView.recording = false
            } else {
                self.stopPlayback()
                recordView.playing = false
            }
        } else {
            self.stopPlayback()
        }
        
        for view in self.performanceViews {
            view.playing = false
        }
        
        self.playButton.setTitle("play", for: UIControlState.normal)
        self.state = ChirpJamModes.loaded
        self.updateUI()
        
        self.progressTimer?.invalidate()
        self.progress = 0.0
        self.recordingProgress?.progress = 0.0
        
        // Restart Playback in Jam Mode.
        if (self.jamming) {
            print("JAMVC: Restarting playback for the jam.")
            if (self.state != ChirpJamModes.playing) {
                self.playButtonPressed(self.playButton) // start playing if not already playing.
            }
        }
    }
    
    /// Increment the recording progress bar by 10ms; called automatically by timers.
    func incrementRecordingProgress(_ : Timer) {
        self.progress += 0.01;
        self.recordingProgress?.progress = Float(self.progress / self.RECORDING_TIME)
        if (self.progress >= self.RECORDING_TIME) {self.stopTimer()}
    }
    
    /// Starts a recurring timer that increments the progress bar.
    func startProgressBar() {
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
    }
    
    // MARK: - Recording Functions
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        if (self.state == ChirpJamModes.new) {
            NSLog("JAMVC: Starting a recording.")
            self.recordView!.recording = true
            self.state = ChirpJamModes.recording
            self.jamming = false
            self.recordingProgress!.progress = 0.0
            self.progress = 0.0
            self.updateUI()
            self.startProgressBar()
            self.playBackPerformances()
        }
    }
    
    // MARK: - Touch methods
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        if let recordView = self.recordView {
            let p = touches.first?.location(in: recordView);
            if (recordView.bounds.contains(p!) && self.state == ChirpJamModes.new) {
                print("JAMVC: Starting a Recording")
                self.startRecording()
            }
        }
    }
    
    /// Memory warning.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
