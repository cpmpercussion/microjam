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
        if let recorder = recorder {
            let chirp = ChirpView(with: chirpViewContainer.bounds, andPerformance: performance)
            recorder.chirpViews.append(chirp)
            chirpViewContainer.addSubview(chirp)
            navigationController?.popViewController(animated: true)
        }
    }
}

class ChirpJamViewController: UIViewController {
    
    /// Enters composing mode if a performance is added from within the ChirpJamController
    var isComposing = false
    /// Stores the present jamming state
    var jamming : Bool = false
    
    var recorder: Recorder?
    
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
        
        if let recorder = recorder {
            recorder.stop()
        }
        
        if let barButton = sender as? UIBarButtonItem {
            // TODO: Is this check actually used?
            if savePerformanceButton === barButton {
                print("JAMVC: Save button segue!")

                if isComposing {
                    // TODO: Store composing performances
                    newRecordingView()
                
                } else {
                    appDelegate.performanceStore.addNew(performance: recorder!.recordingView.performance!)
                }
                
                navigationController?.popViewController(animated: true)
            
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
        if let recorder = recorder {
            recorder.stop()
        }

        if replyto != nil {
            // In the world tab
            navigationController!.popViewController(animated: true)
        
        } else {
            // In the jab tab
            if isComposing {
                // Remove the last added performance
                if let chirp = recorder!.chirpViews.popLast() {
                    print("Shourld remove chirp")
                    chirp.removeFromSuperview()
                }
                
            } else {
                // Just reset to a new recording
                recorder!.recordingEnabled = false
                recorder!.recordingIsDone = false
                playButton.isEnabled = false
                jamButton.isEnabled = false
                replyButton.isEnabled = true
                replyButton.setTitle("Enable rec", for: .normal)
                newRecordingView()
            }
        }
    }

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let recorder = recorder {
            print("Controller was loaded with ", recorder)
            
            if !isComposing && !recorder.viewsAreLoaded {
                
                for view in recorder.chirpViews {
                    view.frame = chirpViewContainer.bounds
                    chirpViewContainer.addSubview(view)
                }
                
                recorder.viewsAreLoaded = true // Make sure the views are not added to the chirp containter if they are already added
                recorder.delegate = self
                replyto = recorder.chirpViews.first?.performance?.title()
                
                if let last = recorder.chirpViews.last {
                    chirpViewContainer.backgroundColor = last.performance!.backgroundColour.darkerColor
                }
            }
        
        } else {
            recorder = Recorder(frame: chirpViewContainer.bounds)
            recorder!.delegate = self
            chirpViewContainer.backgroundColor = UserProfile.shared.profile.backgroundColour.darkerColor
            playButton.isEnabled = false
            jamButton.isEnabled = false
        }

        newRecordingView()
        performerLabel.text = recorder!.recordingView.performance!.performer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        
        // need to initialise the recording progress at zero.
        recordingProgress!.progress = 0.0
        
        replyButton.setTitle("Enable rec", for: .normal)
        replyButton.isEnabled = true
        
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
                self.instrumentChanged()
            }
        }
    }
    
    func instrumentChanged() {
        
        if let recorder = recorder {
            recorder.recordingView.openUserSoundScheme()
            instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
        }
    }
    
    // MARK: - Creation of recording and playback views

    /// Resets to a new performance state.
    func newRecordingView() {
        
        if let recorder = recorder {
            recorder.recordingView.closePdFile()
            recorder.recordingView.removeFromSuperview()
            recorder.recordingIsDone = false
            recorder.recordingView = ChirpRecordingView(frame: chirpViewContainer.bounds)
            recorder.recordingView.performance!.performer = UserProfile.shared.profile.stageName
            if let rep = replyto {
                recorder.recordingView.performance!.replyto = rep
            }
            chirpViewContainer.addSubview(recorder.recordingView)
        }
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
        
        if let recorder = recorder {
            if recorder.isPlaying {
                playButton.setTitle("Play", for: .normal)
                jamButton.isEnabled = true
                if recorder.isRecording {
                    replyButton.isEnabled = true
                }
                recordingProgress.progress = 0.0
                recorder.stop()
            
            } else {
                playButton.setTitle("Stop", for: .normal)
                jamButton.isEnabled = false
                recorder.play()
            }
        }
    }

    /// IBAction for the SoundScheme label. Opens a dropdown menu for selection when in "new" state.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        // TODO: should there be some kind of change in loaded mode? Like changing the user's layer sound, or adjusting the previous performers' sound?
        soundSchemeDropDown.show()
    }

    @IBAction func replyButtonPressed(_ sender: Any) {
        print("JAMVC: Reply button pressed");
        
        if let recorder = recorder {
            
            if !recorder.recordingEnabled {
                recorder.recordingEnabled = true
                replyButton.setTitle("Reset", for: .normal)
            }
            
            recordingProgress.progress = 0.0
            recorder.stop()
        
            newRecordingView()
            replyButton.isEnabled = false
            
            if !recorder.viewsAreLoaded {
                // There is nothing to be played or jammed
                playButton.isEnabled = false
                jamButton.isEnabled = false
            }
        }
    }

    /// IBAction for the Jam Button
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        // TODO: implement some kind of generative performing here!
        if (jamming) {
            // Stop Jamming
            jamButton.setTitle("jam", for: UIControlState.normal)
            jamming = false
            playButton.isEnabled = true
            recordingProgress.progress = 0.0
            if let recorder = recorder {
                recorder.stop()
            }
        } else {
            // Start Jamming
            jamButton.setTitle("no jam", for: UIControlState.normal)
            jamming = true
            playButton.isEnabled = false
            if let recorder = recorder {
                recorder.play()
            }
        }
    }
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        
        if let recorder = recorder {
            
            let point = touches.first?.location(in: recorder.recordingView);
            
            if (recorder.recordingView.bounds.contains(point!)) {
                print("JAMVC: Starting a Recording")
                if recorder.record() { // Returns true if recording is starting
                    playButton.isEnabled = true
                    playButton.setTitle("Stop", for: .normal)
                }
            }
        }
    }
}

// MARK: Player delegate methods

extension ChirpJamViewController: PlayerDelegate {
    
    func progressTimerStep() {
        recordingProgress.progress = Float(recorder!.progress / recorder!.maxPlayerTime)
    }

    func progressTimerEnded() {
        recordingProgress.progress = 0.0
        recorder!.stop()
        
        if jamming {
            recorder!.play()
            return
        }
        
        if recorder!.recordingIsDone {
            replyButton.isEnabled = true
        }
        
        jamButton.isEnabled = true
        playButton.isEnabled = true
        playButton.setTitle("Play", for: .normal)
    }
}

