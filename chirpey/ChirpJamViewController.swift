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

class ChirpJamViewController: UIViewController, UIDocumentInteractionControllerDelegate, SearchJamDelegate {
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

    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var jamButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var performerLabel: UILabel!
    @IBOutlet weak var chirpViewContainer: UIView!
    @IBOutlet weak var recordingProgress: UIProgressView!
    @IBOutlet weak var savePerformanceButton: UIBarButtonItem!
    @IBOutlet weak var instrumentButton: UIButton!

    // Views for adding single performances. Composing
    @IBOutlet weak var addJamButton: UIButton!

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
                
                if self.state == ChirpJamModes.composing {
                    
                    // TODO: Store composing performances
                    print("Need implementation for storing compositions...")
                    
                    while let perf = self.performanceViews.popLast() {
                        perf.removeFromSuperview()
                    }
                    
                    self.newRecordView()
                    
                    return
                }
                
                if let recordView = self.recordView {
                    if let performance = recordView.performance {
                        // Adding performance to clouad
                        appDelegate.performanceStore.addNew(performance: performance)
                        // Reset view controller
                        self.newRecordView()

                        // TODO: Maybe it is best to delete the view controller to save memory?

                    }
                }
            } else {
                print("JAMVC: Not jam button segue!")
                // MARK: Put something here
            }
        
        } else if let button = sender as? UIButton {
            
            if button == addJamButton {
                let controller = segue.destination as! SearchJamViewController
                controller.delegate = self
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("JAMVC: viewDidAppear.")
        // Check what tab the VC exists under and re-open patch if necessary.
        if (tabBarItem.title == TabBarItemTitles.jamTab) { // onlyrun this stuff in the jam tab
            //self.recordView.openPdFile() // Make sure the correct Pd File is open
        }

        if !self.performanceViews.isEmpty {
            
            if self.state != ChirpJamModes.composing {
                // If there are loaded performance from world controller, disable composing feature..
                self.addJamButton.isEnabled = false
                
                for view in self.performanceViews {
                    view.frame = self.chirpViewContainer.bounds
                    //view.contentMode = .scaleToFill
                    self.chirpViewContainer.addSubview(view)
                }
                
                self.replyto = self.performanceViews.first?.performance?.title()
                self.newPerformance = false
                self.state = ChirpJamModes.loaded
                self.updateUI()
            }
            
        } else {
            self.newRecordView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        self.recordingProgress!.progress = 0.0 // need to initialise the recording progress at zero.

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

    func newViewWith(performance : ChirpPerformance, withFrame frame : CGRect?) {

        var newView : ChirpView!

        if let f = frame {
            newView = ChirpView(frame: f, performance: performance)
            self.chirpViewContainer.addSubview(newView)
        } else {
            // This is the case if we add performances before the view is displayed. no reference!
            newView = ChirpView(frame: CGRect.zero, performance: performance)
        }

        newView.isUserInteractionEnabled = false // Not used for recording
        newView.backgroundColor = UIColor.clear
        self.performanceViews.append(newView)
    }

    /// Resets to a new performance state.
    func newRecordView() {

        if let recordView = self.recordView {
            // Removing current ChirpView
            recordView.removeFromSuperview()
        }

        // Creating a new ChirpView
        let newView = ChirpView(frame: self.chirpViewContainer!.bounds)
        newView.isUserInteractionEnabled = true
        newView.backgroundColor = UIColor.clear
        newView.openPdFile()

        self.recordView = newView
        self.chirpViewContainer.addSubview(newView)

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
        
        if self.state == ChirpJamModes.composing {
            if let perf = self.performanceViews.popLast() {
                perf.removeFromSuperview()
            }
            
            if self.performanceViews.isEmpty {
                self.state = ChirpJamModes.new
                self.updateUI()
                return
            }
            
            return
        }
        
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
                view.playing = true
            }
        }

        // Playback recorded performence
        if self.state != ChirpJamModes.recording {
            if let recordView = self.recordView {
                if let performance = recordView.performance {
                    performance.playback(inView: self.recordView!)
                    recordView.playing = true
                }
            }
        }
    }
    
    
    // MARK: SearchJamDelegate methods
    
    func didSelect(performance: ChirpPerformance) {
        self.newViewWith(performance: performance, withFrame: self.chirpViewContainer.bounds)
        self.updateUI()
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: AddJamDelegate methods
    
    func didReturnWithoutSelected() {
        
        if self.performanceViews.isEmpty {
            // No performances are loaded, just return to a new state
            self.state = ChirpJamModes.new
            self.updateUI()
        }
        
        // No change to the state of the app, just dismiss add jam controller
        self.dismiss(animated: true, completion: nil)
    }
    
    func didSelectJamAt(index : Int) {
        print("Delegate returned index: ", index)
        
        // Adding the selected jam to the view and dismissing the add jam controller
        
        let performance = appDelegate.performanceStore.storedPerformances[index]
        self.newViewWith(performance: performance, withFrame: self.chirpViewContainer.bounds)
        
        self.updateUI()
        
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - UI Interaction Functions

    @IBAction func addJam(_ sender: UIButton) {
        
        // Displaying the add jam view controller
        self.state = ChirpJamModes.composing
        
        let layout = UICollectionViewFlowLayout()
        let controller = BrowseController(collectionViewLayout: layout)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    /// IBAction for the play button. Starts playback of performance and replies iff in loaded mode. Stops if already playing.
    @IBAction func playButtonPressed(_ sender: UIButton) {

        // TODO: Implement playbutton

        if self.state == ChirpJamModes.playing || self.state == ChirpJamModes.recording {
            // Stop playback
            self.playButton.setTitle("play", for: .normal)
            self.stopTimer()

        } else {
            // Start playback
            if !self.jamming {
                self.playButton.setTitle("stop", for: .normal)
            }
            
            if self.state != ChirpJamModes.composing {
                self.state = ChirpJamModes.playing
            }
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

        // Reply button is only enabled if it is a new performance
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

    func resetPerformanceImages() {
        // FIXME: Better way to reset images for ChirpViews
        for view in self.performanceViews {
            view.image = view.performance?.image
        }
        if let recordView = self.recordView {
            recordView.image = recordView.performance?.image
        }
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

            if !self.performanceViews.isEmpty {
                self.playButton.isEnabled = true // Make sure we can play the performances. Used for composing

                // Reset images for the performances
                for view in self.performanceViews {
                    view.image = view.performance?.image
                }

            } else {
                self.playButton.isEnabled = false
            }

            self.jamButton.isEnabled = false
            self.replyButton.isEnabled = false
            self.instrumentButton.setTitle(SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)], for: .normal)
            if let recordView = self.recordView {
                // Updating the color of the performance based on the user defaults.
                recordView.performance?.colour = UIColor(hue: CGFloat(UserDefaults.standard.float(forKey: SettingsKeys.performerColourKey)), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                recordView.recordingColour = recordView.performance?.colour.cgColor
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
                self.replyButton.isEnabled = false // reply button disabled in loaded jams.

            }
            self.statusLabel.text = "Loaded: "
            self.performerLabel.text = loadedPerformance?.performer
            self.instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)

            self.resetPerformanceImages()

            self.playButton.isEnabled = true
            self.jamButton.isEnabled = true

            print("JAMVC: opening Pd file for loaded performance.")
            //self.chirpeySquare.openPdFile(withName: loadedPerformance.instrument) // open Pd File.
            
            
        case ChirpJamModes.composing:
            
            self.statusLabel.text = "Composing..."
            
            self.playButton.isEnabled = true
            self.jamButton.isEnabled = true
            
            self.resetPerformanceImages()
            
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
        self.recordView?.isUserInteractionEnabled = false
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
        
        if self.state != ChirpJamModes.composing {
            self.state = ChirpJamModes.loaded
        }
        
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
