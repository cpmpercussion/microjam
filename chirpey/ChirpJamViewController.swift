//
//  ViewController.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit
import DropDown

let RECORDING_TIME = 5.0

// TODO: how to tell between loaded and saved and just loaded?

class ChirpJamViewController: UIViewController, UIDocumentInteractionControllerDelegate, BrowseControllerDelegate {
    /// Maximum allowed recording time.
    var state = ChirpJamModes.idle
    var mode = ChirpJamModes.new
    var newPerformance : Bool = true
    var jamming : Bool = false
    var progress = 0.0
    /// Timer for progress in recording and playback.
    var progressTimer : Timer?
    /// Storage of the original performance for a reply.
    var performanceViews : [ChirpView] = [ChirpView]() // Previous performances, should be populated if this is a reply
    var recordingView : ChirpView? //
    /// Addition ChirpView for storage of the original performance for a reply.
    var replyto : String?
    /// App delegate - in case we need to upload a performance.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    /// Dropdown menu for selecting SoundScheme
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme

    // MARK: - Interface Outlets

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
        print("JAMVC: Preparing for Segue. Current state:", state)
        // FIXME: save the performance if the timer hasn't run out.
        jamming = false // stop jamming.
        if state == ChirpJamModes.recording {stopRecording() }
        if state == ChirpJamModes.playing { stopPlayback() } // stop any possible playback.
        if let barButton = sender as? UIBarButtonItem {
            // TODO: Is this check actually used?
            if savePerformanceButton === barButton {
                print("JAMVC: Save button segue!")

                if mode == ChirpJamModes.composing {

                    // TODO: Store composing performances
                    print("Need implementation for storing compositions...")

                    while let perf = self.performanceViews.popLast() {
                        perf.removeFromSuperview()
                    }

                    self.newRecordingView()

                    return
                }

                if let recordView = recordingView {
                    if let performance = recordView.performance {
                        // Adding performance to clouad
                        appDelegate.performanceStore.addNew(performance: performance)
                        // Reset view controller
                        self.newRecordingView()

                        // TODO: Maybe it is best to delete the view controller to save memory?

                    }
                }
            } else {
                print("JAMVC: Not jam button segue!")
                // MARK: Put something here
            }

        }
    }

    // MARK: - Lifecycle

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

        if !performanceViews.isEmpty {
            
            // If we are in a composing state, it means we have returned from browse view. No need to add subviews
            if mode != ChirpJamModes.composing {
                // If there are loaded performance from world controller, disable composing feature..
                addJamButton.isHidden = true

                for view in performanceViews {
                    view.frame = chirpViewContainer.bounds
                    chirpViewContainer.addSubview(view)
                }

                replyto = performanceViews.first?.performance?.title()
                newPerformance = false
                state = ChirpJamModes.idle
                mode = ChirpJamModes.loaded
                updateUI()
            }

        } else {
            // there are no performances to playback (i.e., this is a blank recording).
            newRecordingView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        recordingProgress!.progress = 0.0 // need to initialise the recording progress at zero.

        // Soundscheme Dropdown initialisation.
        soundSchemeDropDown.anchorView = instrumentButton // anchor dropdown to intrument button
        soundSchemeDropDown.dataSource = Array(SoundSchemes.namesForKeys.values) // set dropdown datasource to available SoundSchemes
        soundSchemeDropDown.direction = .bottom

        // Action triggered on selection
        soundSchemeDropDown.selectionAction = {(index: Int, item: String) -> Void in
            print("DropDown selected:", index, item)
            if let sound = SoundSchemes.keysForNames[item] {
                UserProfile.shared.profile.soundScheme = Int64(sound)
                self.updateUI()
            }
        }
    }

    // Only needed to debug view layouts.
    //    override func viewDidLayoutSubviews() {
    //        print("Laid Out Subviews.")
    //        print("JAMVC: Main ChirpView frame:", chirpeySquare.frame.size)
    //        print("JAMVC:Reply ChirpView frame:", replyToPerformanceView?.frame.size ?? "None Available")
    //        print("JAMVC:Reply ChirpView comod:", replyToPerformanceView?.contentMode ?? "None Available")
    //    }

    func newViewWith(performance : ChirpPerformance, withFrame frame : CGRect?) {

        var newView : ChirpView!

        if let f = frame {
            newView = ChirpView(with: f, andPerformance: performance)
            self.chirpViewContainer.addSubview(newView)
        } else {
            // This is the case if we add performances before the view is displayed. no reference!
            newView = ChirpView(with: CGRect.zero, andPerformance: performance)
        }

        newView.isUserInteractionEnabled = false // Not used for recording
        newView.backgroundColor = UIColor.clear
        performanceViews.append(newView)
    }

    /// Resets to a new performance state.
    func newRecordingView() {

        if let recordingView = self.recordingView {
            // Removing current ChirpView
            recordingView.removeFromSuperview()
        }

        // Creating a new Recording ChirpView
        let newView = ChirpView(frame: chirpViewContainer!.bounds)
        newView.isUserInteractionEnabled = true
        newView.backgroundColor = UIColor.clear
        newView.openPdFile()

        recordingView = newView
        chirpViewContainer.addSubview(newView)

        newPerformance = true
        mode = ChirpJamModes.new
        jamming = false
        recordingProgress!.progress = 0.0
        progress = 0.0
        updateUI()

    }


    /// IBAction for Cancel (bar) button. stops playback/recording and dismisses present performance.
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")

        // Stop current actions
        stopTimer() // Stopping all Timers
        //stopRecording()
        stopPlayback() // stop any possible playback

        if mode == ChirpJamModes.composing {
            
            if let perf = performanceViews.popLast() {
                perf.removeFromSuperview()
            }

            if performanceViews.isEmpty {
                newPerformance = true
                mode = ChirpJamModes.new
                updateUI()
            }
            
            return
        }

        if let recordingView = recordingView {
            if performanceViews.isEmpty {
                // No loaded performances means we're in the jam tab, just reset to a new record view
                replyButton.setTitle("Reply", for: .normal)
                newRecordingView()
            } else {
                // Reset back to the loaded performances
                recordingView.removeFromSuperview()
                self.recordingView = nil // this is a bit confusing, it means to set the VC's recordingView to nil, not the present unwrapped local variable.
                replyButton.setTitle("Reply", for: .normal)
                newPerformance = false
                mode = ChirpJamModes.loaded
                state = ChirpJamModes.idle
                jamming = false
                recordingProgress!.progress = 0.0
                progress = 0.0
                updateUI()
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
            print("JAMVC: unwinding from a settings screen. Current state:", state)
            if (state == ChirpJamModes.new) { // if it's still a new jam, update the sound scheme
                print("JAMVC: updating the Pd file.")
                updateUI()
            }
        }
    }

    /// Plays every performance that is loaded into performanceViews and in the recording view.
    func playBackPerformances() {
        // Play loaded performances
        for view in performanceViews {
            if let performance = view.performance {
                performance.playback(inView: view)
            }
        }

        // Playback recorded performence
        if state != ChirpJamModes.recording {
            if let recordingView = self.recordingView,
                let performance = recordingView.performance {
                    performance.playback(inView: recordingView)
            }
        }
    }


    // MARK: BrowseControllerDelegate methods

    func didSelect(performance: ChirpPerformance) {
        self.newViewWith(performance: performance, withFrame: self.chirpViewContainer.bounds)
        self.updateUI()
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - UI Interaction Functions

    @IBAction func addJam(_ sender: UIButton) {

        // Displaying the browse view controller
        mode = ChirpJamModes.composing

        let layout = UICollectionViewFlowLayout()
        let controller = BrowseController(collectionViewLayout: layout)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }


    /// IBAction for the play button. Starts playback of performance and replies iff in loaded mode. Stops if already playing.
    @IBAction func playButtonPressed(_ sender: UIButton) {

        if state == ChirpJamModes.idle {
            // Start playback
            if !jamming {
                playButton.setTitle("stop", for: .normal)
            }
            state = ChirpJamModes.playing
            updateUI()
            recordingProgress!.progress = 0.0
            progress = 0.0
            startProgressBar()
            playBackPerformances()

        } else {
            // Stop playback
            playButton.setTitle("play", for: .normal)
            stopTimer()
        }
    }

    /// IBAction for the SoundScheme label. Opens a dropdown menu for selection when in "new" state.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        // TODO: should there be some kind of change in loaded mode? Like changing the user's layer sound, or adjusting the previous performers' sound?
        if newPerformance {
            soundSchemeDropDown.show()
        }
    }

    @IBAction func replyButtonPressed(_ sender: Any) {
        print("JAMVC: Reply button pressed");
        // Reply button is only enabled if it is a new performance
        replyButton!.setTitle("Reset", for: .normal)
        stopTimer()
        newRecordingView()
    }

    /// IBAction for the Jam Button
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        // TODO: implement some kind of generative performing here!
        if (jamming) {
            // Stop Jamming
            jamButton.setTitle("jam", for: UIControlState.normal)
            jamming = false
            if (state == ChirpJamModes.playing) {
                playButtonPressed(playButton) // stop playing if already playing.
            }
        } else {
            // Start Jamming
            jamButton.setTitle("no jam", for: UIControlState.normal)
            jamming = true
            if (state != ChirpJamModes.playing) {
                playButtonPressed(playButton) // start playing if not already playing.
            }
        }
    }

    func resetPerformanceImages() {
        // FIXME: Better way to reset images for ChirpViews
        for view in self.performanceViews {
            view.image = view.performance?.image
        }
        if let recordView = recordingView {

            recordView.image = recordView.performance?.image
        }
    }

    /// Update the UI labels and image only if there is a valid performance loaded.
    func updateUI() {
        print("JAMVC: Updating UI.")

        switch state {

        case ChirpJamModes.recording:

            statusLabel.text = "recording..."
            playButton.isEnabled = false
            jamButton.isEnabled = false
            replyButton.isEnabled = false
            performerLabel.text = UserProfile.shared.profile.stageName
            instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)

        case ChirpJamModes.playing:

            var loadedPerformance = self.performanceViews.last?.performance

            if let recordingView = self.recordingView,
                let performance = recordingView.performance {
                loadedPerformance = performance
            }

            navigationItem.title = loadedPerformance?.dateString
            statusLabel.text = "Playing..."
            performerLabel.text = loadedPerformance?.performer
            instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)
            playButton.isEnabled = true
            jamButton.isEnabled = true

            if newPerformance {
                replyButton.isEnabled = false // Should not be able to reply to your own performance
            } else {
                replyButton.isEnabled = true // reply button enabled in loaded jams.
            }
            
        default:
            
            resetPerformanceImages()
            
            if mode == ChirpJamModes.new {
                navigationItem.title = "New Performance"
                if let replytext = self.replyto {
                    statusLabel.text = "reply to: " + replytext // setting reply to text
                } else {
                    statusLabel.text = "new" // new performance only.
                }
                performerLabel.text = UserProfile.shared.profile.stageName
                instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
                if let recordingView = self.recordingView {
                    // Updating the color of the performance based on the user defaults.
                    recordingView.performance?.colour = UserProfile.shared.profile.jamColour
                    recordingView.recordingColour = recordingView.performance?.colour.cgColor
                    recordingView.openPdFile()
                }
                playButton.isEnabled = true
                replyButton.isEnabled = false
                jamButton.isEnabled = true
            
            } else if mode == ChirpJamModes.composing {
                statusLabel.text = "composing..."
                performerLabel.text = UserProfile.shared.profile.stageName
                playButton.isEnabled = true
                replyButton.isEnabled = false
                jamButton.isEnabled = true
            
            } else {
                var loadedPerformance = self.performanceViews.last?.performance
                
                if let recordingView = self.recordingView,
                    let performance = recordingView.performance {
                    loadedPerformance = performance
                }
                
                navigationItem.title = loadedPerformance?.dateString
                statusLabel.text = "Loaded..."
                performerLabel.text = loadedPerformance?.performer
                instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)
                playButton.isEnabled = true
                replyButton.isEnabled = false
                jamButton.isEnabled = true
            }
        }
    }

    /// Stop playback and cancel timers.
    func stopPlayback() {
        print("JAMVC: Stopping any requested playback")
        for view in performanceViews {
            if let performance = view.performance {
                performance.cancelPlayback()
            }
        }
        if let recordingView = self.recordingView,
            let performance = recordingView.performance {
            performance.cancelPlayback()
        }
    }

    /// Load a ChirpPerformance for playback and reaction (most processing is done in updateUI).
    func load(performance: ChirpPerformance) {
        recordingView?.isUserInteractionEnabled = false
        updateUI()
    }

    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping recording; now loading the recorded performance.")
        if let lastPerformance = recordingView?.saveRecording(),
            let replyto = self.replyto {
            lastPerformance.replyto = replyto
            load(performance: lastPerformance)
        }
    }

    /// Automatically triggered when recording time finishes.
    func stopTimer() {
        // FIXME: Incorporate this method with stopPlayback?
        // FIXME: Make sure that the reply performances are reset as well as the main performance.
        NSLog("JAMVC: Stop Timer Called (either finished or cancelled).")
        if let recordingView = self.recordingView {
            if recordingView.recording {
                stopRecording()
                recordingView.recording = false
                mode = ChirpJamModes.loaded
            } else {
                stopPlayback()
            }
        } else {
            stopPlayback()
        }

        //for view in performanceViews {
            // FIXME: How do you tell the view to stop playing?
        //}

        playButton.setTitle("play", for: UIControlState.normal)
        state = ChirpJamModes.idle
        updateUI()

        progressTimer?.invalidate()
        progress = 0.0
        recordingProgress?.progress = 0.0

        // Restart Playback in Jam Mode.
        if (jamming) {
            print("JAMVC: Restarting playback for the jam.")
            if (state != ChirpJamModes.playing) {
                playButtonPressed(playButton) // start playing if not already playing.
            }
        }
    }

    /// Increment the recording progress bar by 10ms; called automatically by timers.
    func incrementRecordingProgress(_ : Timer) {
        progress += 0.01;
        recordingProgress?.progress = Float(progress / RECORDING_TIME)
        if (progress >= RECORDING_TIME) {
            stopTimer()
        }
    }

    /// Starts a recurring timer that increments the progress bar.
    func startProgressBar() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
    }

    // MARK: - Recording Functions
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        if (mode == ChirpJamModes.new) {
            NSLog("JAMVC: Starting a recording.")
            recordingView!.recording = true
            state = ChirpJamModes.recording
            jamming = false
            recordingProgress!.progress = 0.0
            progress = 0.0
            updateUI()
            startProgressBar()
            playBackPerformances()
        }
    }

    // MARK: - Touch methods

    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        if let recordingView = self.recordingView {
            let p = touches.first?.location(in: recordingView);
            if (recordingView.bounds.contains(p!) && mode == ChirpJamModes.new && state == ChirpJamModes.idle) {
                print("JAMVC: Starting a Recording")
                startRecording()
            }
        }
    }

    /// Memory warning.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
