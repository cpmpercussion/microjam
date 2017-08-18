//
//  ViewController.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit
import DropDown

/// Maximum allowed recording time.
let RECORDING_TIME = 5.0

// TODO: how to tell between loaded and saved and just loaded?

// MARK: - BrowseControllerDelegate Extension

extension ChirpJamViewController: BrowseControllerDelegate {
    
    /// Adds a ChirpPerformance when chosen in the BrowseController
    func didSelect(performance: ChirpPerformance) {
        // TODO: Add this as a parent to the currently recording jam.
        self.navigationController?.popViewController(animated: true)
    }
}

class ChirpJamViewController: UIViewController {
    
    var recordingEnabled = true
    /// Storage of the present playback/recording state: playing, recording or idle
    var isRecording = false
    /// Tells us whether the recording has been added to the stack in the performance handler
    var recordingIsDone = false
    /// Enters composing mode if a performance is added from within the ChirpJamController
    var isComposing = false
    /// Stores the recording/playback progress.
    var progress = 0.0
    /// Timer for progress in recording and playback.
    var progressTimer : Timer?
    /// Stores the present jamming state
    var jamming : Bool = false
    
    var recordingView: ChirpRecordingView?
    var player: Player?
    
    /// Addition ChirpView for storage of the original performance for a reply.
    var replyto : String?
    /// App delegate - in case we need to upload a performance.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    /// Dropdown menu for selecting SoundScheme
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme

    /// Button to initiate a reply performance.
    @IBOutlet weak var replyButton: UIButton!
    /// Button to play performances.
    @IBOutlet weak var playButton: UIButton!
    /// Button to activate "jamming" mode.
    @IBOutlet weak var jamButton: UIButton!
    /// Label showing the recording/playback status
    @IBOutlet weak var statusLabel: UILabel!
    /// Label shoing the current performer.
    @IBOutlet weak var performerLabel: UILabel!
    /// Container view for the performance/recording views
    @IBOutlet weak var chirpViewContainer: UIView!
    /// Progress bar for playback and recording progress
    @IBOutlet weak var recordingProgress: UIProgressView!
    /// Button for saving recorded performance
    @IBOutlet weak var savePerformanceButton: UIBarButtonItem!
    /// Button for choosing/displaying soundscheme
    @IBOutlet weak var instrumentButton: UIButton!
    /// Button to add specific parent performances when composing a performance
    @IBOutlet weak var addJamButton: UIButton!

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("JAMVC: Preparing for Segue.")
        // FIXME: save the performance if the timer hasn't run out.
        
        jamming = false // stop jamming.
        
//        if state == ChirpJamModes.recording {stopRecording() }
//        if state == ChirpJamModes.playing { stopPlayback() } // stop any possible playback.
        
        if let barButton = sender as? UIBarButtonItem {
            // TODO: Is this check actually used?
            if savePerformanceButton === barButton {
                print("JAMVC: Save button segue!")

                if isComposing {
                    // TODO: Store composing performances
                    print("Need implementation for storing compositions...")

                    recordingView = nil
                    newRecordingView()

                    return
                }

                //appDelegate.performanceStore.addNew(performance: performance)

            } else {
                print("JAMVC: Not jam button segue!")
                // MARK: Put something here
            }

        }
    }
    
    /// IBAction for Cancel (bar) button. stops playback/recording and dismisses present performance.
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        
        // Stop any timers
        if isRecording {
            stopRecording()
        } else {
            stopPlayback()
        }
        
        if tabBarItem.title == TabBarItemTitles.jamTab {
            // In the jab tab
            if isComposing {
                // Remove the last added performance
                // If there are no more added performances ,return to the new performance state
            } else {
                // Just reset to a new recording
                newRecordingView()
            }
            
        } else {
            // In the world tab
            navigationController!.popViewController(animated: true)
        }
    }

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let player = player {
            print("Controller was loaded with ", player)
            
            for view in player.chirpViews {
                view.frame = chirpViewContainer.bounds
                chirpViewContainer.addSubview(view)
            }
            
            replyto = player.chirpViews.first?.performance?.title()
            statusLabel.text = "reply to: " + replyto!
        }

        newRecordingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        
        // need to initialise the recording progress at zero.
        recordingProgress!.progress = 0.0
        
        // Setting the correct instrument
        instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
        instrumentButton.isEnabled = true

        // Soundscheme Dropdown initialisation.
        soundSchemeDropDown.anchorView = instrumentButton // anchor dropdown to intrument button
        soundSchemeDropDown.dataSource = Array(SoundSchemes.namesForKeys.values) // set dropdown datasource to available SoundSchemes
        soundSchemeDropDown.direction = .bottom

        // Action triggered on selection
        soundSchemeDropDown.selectionAction = {(index: Int, item: String) -> Void in
            print("DropDown selected:", index, item)
            if let sound = SoundSchemes.keysForNames[item] {
                UserProfile.shared.profile.soundScheme = Int64(sound)
            }
        }
    }
    
    // MARK: - Creation of recording and playback views

    /// Resets to a new performance state.
    func newRecordingView() {
        
        if let recordingView = recordingView {
            recordingView.closePdFile()
            recordingView.removeFromSuperview()
        }
        
        recordingView = ChirpRecordingView(frame: chirpViewContainer.bounds)
        
        jamming = false

    }

    // MARK: - UI Interaction Functions

    /// Opens the composition screen for choosing parent jams.
    @IBAction func addJam(_ sender: UIButton) {

        // Displaying the browse view controller
        isComposing = true

        let layout = UICollectionViewFlowLayout()
        let controller = BrowseController(collectionViewLayout: layout)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }


    /// IBAction for the play button. Starts playback of performance and replies iff in loaded mode. Stops if already playing.
    @IBAction func playButtonPressed(_ sender: UIButton) {
        
    
    }

    /// IBAction for the SoundScheme label. Opens a dropdown menu for selection when in "new" state.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        // TODO: should there be some kind of change in loaded mode? Like changing the user's layer sound, or adjusting the previous performers' sound?
        soundSchemeDropDown.show()
    }

    @IBAction func replyButtonPressed(_ sender: Any) {
        print("JAMVC: Reply button pressed");
        // Reply button is only enabled if it is a new performance
        
        if isRecording {
            stopPlayback()
        }
    }

    /// IBAction for the Jam Button
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        // TODO: implement some kind of generative performing here!
        if (jamming) {
            // Stop Jamming
            jamButton.setTitle("jam", for: UIControlState.normal)
            jamming = false
        } else {
            // Start Jamming
            jamButton.setTitle("no jam", for: UIControlState.normal)
            jamming = true
        }
    }
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        let point = touches.first?.location(in: recordingView);
        
        if recordingEnabled {
            
            if (recordingView!.bounds.contains(point!) && !isRecording) {
                print("JAMVC: Starting a Recording")
                startRecording()
            }
        }
    }
}

// MARK: - Extension for Playback/Recording Control Methods.

extension ChirpJamViewController {
    
    /// Stopping the timer and resetting progress
    func stopProgressBar() {
        if let timer = progressTimer {
            timer.invalidate()
            progress = 0.0
            recordingProgress?.progress = 0.0
        }
    }
    
    /// Starts a recurring timer that increments the progress bar.
    func startProgressBar() {
        recordingProgress!.progress = 0.0
        progress = 0.0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
    }
    
    func progressTimerEnded() {
        
        // If jamming..
        
        if isRecording {
            completeRecording()
        } else {
            stopPlayback()
        }
    }
    
    /// Increment the recording progress bar by 10ms; called automatically by timers.
    func incrementRecordingProgress(_ : Timer) {
        progress += 0.01;
        recordingProgress?.progress = Float(progress / RECORDING_TIME)
        if (progress >= RECORDING_TIME) {
            progressTimerEnded()
        }
    }
    
    func startPlayback() {
        statusLabel.text = "Playing..."
        playButton.setTitle("Stop", for: .normal)
        startProgressBar()
    }

    /// Stop playback and cancel timers.
    func stopPlayback() {
        print("JAMVC: Stopping any requested playback")
        
        stopProgressBar()
        
        playButton.setTitle("Play", for: .normal)
    }
    
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        NSLog("JAMVC: Starting a recording.")
        
        statusLabel.text = "Recording..."
        
        isRecording = true
        jamming = false
        
        playButton.setTitle("Stop Rec", for: .normal)
        replyButton.isEnabled = false
        jamButton.isEnabled = false
    }
    
    func completeRecording() {
        
        isRecording = false
        recordingEnabled = false
        stopPlayback()
        
        playButton.isEnabled = true
        replyButton.isEnabled = true
        jamButton.isEnabled = true
        
        // Mark recording as done!
        recordingIsDone = true
    }
    
    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping recording")
        
        isRecording = false
        stopPlayback()
        
        // Throw away current recording
        newRecordingView()
    }
}

