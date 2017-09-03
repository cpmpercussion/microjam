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

    /// Image view for storing avatar image
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            // automagically clip bounds and round to a circle.
            avatarImageView.clipsToBounds = true
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.height / 2
        }
    }

    
    /// Button to clear the screen after a recording (rewind)
    @IBOutlet weak var rewindButton: UIButton!
    /// Button to enable recording
    @IBOutlet weak var recEnableButton: UIButton!
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
        
        if let recorder = recorder,
            let finishedPerformance = recorder.recordingView.performance {
            recorder.stop()
            
            if let barButton = sender as? UIBarButtonItem {
                // TODO: Is this check actually used?
                if savePerformanceButton === barButton {
                    print("JAMVC: Save button segue!")
                    
                    /// TODO: Store composing performances
                    if isComposing {
                        /// FIXME: hack to stop saving in composing mode
                        newRecordingView()
                    } else {
                        // actually save the performance
                        PerformanceStore.shared.addNew(performance: finishedPerformance)
                    }
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    /// IBAction for Cancel (bar) button. stops playback/recording and dismisses present performance.
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        
        // Stop any timers
        if let recorder = recorder {
            recorder.stop()

            if replyto != nil {
                // In the world tab
                navigationController!.popViewController(animated: true)
            
            } else {
                // In the jab tab
                if isComposing {
                    // Remove the last added performance
                    if let chirp = recorder.chirpViews.popLast() {
                        print("Shourld remove chirp")
                        chirp.removeFromSuperview()
                    }
                    
                } else {
                    // Just reset to a new recording
                    recorder.recordingEnabled = false
                    recorder.recordingIsDone = false
                    playButton.isEnabled = false
                    jamButton.isEnabled = false
                    replyButton.isEnabled = true
                    newRecordingView()
                }
            }
        }
    }

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // rewind
        rewindButton.imageView?.contentMode = .scaleAspectFit
        rewindButton.tintColor = UIColor.init("#7DCFB6")
        // rec enable
        recEnableButton.imageView?.contentMode = .scaleAspectFit
        recEnableButton.tintColor = UIColor.red.darkerColor

        // play
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.tintColor = UIColor.init("#F79256")
        // add layer
        addJamButton.imageView?.contentMode = .scaleAspectFit
        addJamButton.tintColor = UIColor.init("#7DCFB6")
        addJamButton.isHidden = true // hide the add layer button for now.
        
        // jam
        jamButton.imageView?.contentMode = .scaleAspectFit
        jamButton.tintColor = UIColor.init("#1D4E89")
        
        /// TODO: delete reply button
        // reply
        replyButton.imageView?.contentMode = .scaleAspectFit
        replyButton.isHidden = true // not using reply button in this view currently
        
        
        if let recorder = recorder {
            // Loaded with an existing recorder (i.e., to make a reply)
            print("JamVC: Loaded with ", recorder)
            
            if !isComposing && !recorder.viewsAreLoaded {
                
                for view in recorder.chirpViews {
                    view.frame = chirpViewContainer.bounds
                    chirpViewContainer.addSubview(view)
                }
                
                recorder.viewsAreLoaded = true // Make sure the views are not added to the chirp containter if they are already added
                recorder.delegate = self
                replyto = recorder.chirpViews.first?.performance?.title() // set reply
                
                if let last = recorder.chirpViews.last {
                    chirpViewContainer.backgroundColor = last.performance!.backgroundColour.darkerColor
                }
            }
            rewindButton.isEnabled = false
        
        } else {
            // Loaded with a new recorder. (i.e., in the jam tab)
            recorder = Recorder(frame: chirpViewContainer.bounds)
            recorder!.delegate = self
            chirpViewContainer.backgroundColor = UserProfile.shared.profile.backgroundColour.darkerColor
            // disable buttons that cannot be used in this state
            playButton.isEnabled = false
            jamButton.isEnabled = false
            rewindButton.isEnabled = false
            
        }

        newRecordingView()
        performerLabel.text = recorder!.recordingView.performance!.performer // set performer label to current user.
        avatarImageView.image = UserProfile.shared.profile.avatar // set performer avatar to be current user.
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
    
    /// IBAction for the rewind button
    @IBAction func rewindScreen(_ sender: UIButton) {
        print("JAMVC: Rewind pressed, clearing screen")
        if let recorder = recorder {
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
    
    /// IBAction for the record enable button
    @IBAction func recordEnablePressed(_ sender: UIButton) {
        print("JAMVC: Record enabled pressed, ready to record")
        if let recorder = recorder {
            if !recorder.recordingEnabled {
                // recording was not enabled.
                recEnableButton.tintColor = UIColor.red
                recorder.recordingEnabled = true
            } else {
                recEnableButton.tintColor = UIColor.red.darkerColor
                recorder.recordingEnabled = false
            }
        }
    }

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
                playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                playButton.tintColor = UIColor.init("#F79256")
                jamButton.isEnabled = true
                if recorder.isRecording {
                    replyButton.isEnabled = true
                }
                recordingProgress.progress = 0.0
                recorder.stop()
            
            } else {
                playButton.setTitle("Stop", for: .normal)
                playButton.setImage(#imageLiteral(resourceName: "microjam-pause"), for: .normal)
                playButton.tintColor = UIColor.init("#F79256").darkerColor
                jamButton.isEnabled = false
                recorder.play()
            }
        }
    }

    /// IBAction for the SoundScheme button. Opens a dropdown menu for selection when in "new" state.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        // TODO: should there be some kind of change in loaded mode? Like changing the user's layer sound, or adjusting the previous performers' sound?
        soundSchemeDropDown.show()
    }

    /// IBAction for the reply button. // shouldn't be currently used.
    @IBAction func replyButtonPressed(_ sender: Any) {
        print("JAMVC: Reply button pressed");
        // no actions right now.
    }

    /// IBAction for the Jam Button - this loops the presently loaded performance
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        // TODO: implement some kind of generative performing here!
        if (jamming) {
            // Stop Jamming
            jamButton.setTitle("jam", for: UIControlState.normal)
            jamButton.tintColor = UIColor.init("#1D4E89")
            jamming = false
            playButton.isEnabled = true
            recordingProgress.progress = 0.0
            if let recorder = recorder {
                recorder.stop()
            }
        } else {
            // Start Jamming
            jamButton.setTitle("no jam", for: UIControlState.normal)
            jamButton.tintColor = UIColor.init("#1D4E89").darkerColor
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
        
        if let recorder = recorder,
             let point = touches.first?.location(in: recorder.recordingView) {
            if (recorder.recordingView.bounds.contains(point)) {
                if recorder.record() { // Returns true if recording is starting
                    print("JAMVC: Starting a Recording")
                    playButton.isEnabled = true
                    playButton.setTitle("Stop", for: .normal)
                    playButton.setImage(#imageLiteral(resourceName: "microjam-stop"), for: .normal)
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

    /// Finished a recording or playback
    func progressTimerEnded() {
        recordingProgress.progress = 0.0
        recorder!.stop()
        
        // continue playing if jamming is enabled
        if jamming {
            recorder!.play()
            return
        }
        
        // enabled replying if recording is finished.
        if recorder!.recordingIsDone {
            replyButton.isEnabled = true
        }
        
        rewindButton.isEnabled = true
        jamButton.isEnabled = true
        playButton.isEnabled = true
        playButton.setTitle("Play", for: .normal)
        playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
    }
}

