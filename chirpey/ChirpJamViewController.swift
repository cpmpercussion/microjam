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
        self.newViewWith(performance: performance, withFrame: self.chirpViewContainer.bounds)
        self.navigationController?.popViewController(animated: true)
    }
}

class ChirpJamViewController: UIViewController {
    
    var recordingEnabled = true
    /// Storage of the present playback/recording state: playing, recording or idle
    var isRecording = false
    /// Enters composing mode if a performance is added from within the ChirpJamController
    var isComposing = false
    /// Whether it is a new performance or a reply to an existing performance
    var newPerformance = false
    /// Stores the recording/playback progress.
    var progress = 0.0
    /// Timer for progress in recording and playback.
    var progressTimer : Timer?
    /// Stores the present jamming state
    var jamming : Bool = false
    /// The ChirpRecordingView if this is a recordable ChirpJamViewController
    //var recordingView : ChirpRecordingView?
    /// Addition ChirpView for storage of the original performance for a reply.
    
    var startTime: Date?
    var performance: ChirpPerformance?
    var recordingView: UIImageView?
    var pdFile: PdFile?
    var previousPoint: CGPoint?
    
    var replyto : String?
    /// App delegate - in case we need to upload a performance.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    /// Dropdown menu for selecting SoundScheme
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme
    
    let performanceViewHandler = PerformanceViewHandler()

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

                    performanceViewHandler.removePerformances()
                    newRecordingView()

                    return
                }

                if let performance = performance {
                    // Adding performance to clouad
                    appDelegate.performanceStore.addNew(performance: performance)
                    // FIXME: This could potentially leave pd files open when not needed? In Jam tab it's fine as there's only one available.
                    newRecordingView() // Reset view controller
                    // TODO: Maybe it is best to delete the view controller to save memory?
                }
            } else {
                print("JAMVC: Not jam button segue!")
                // MARK: Put something here
            }

        }
    }
    
    /// IBAction for Cancel (bar) button. stops playback/recording and dismisses present performance.
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        
        // Stop current actions
        stopTimer() // Stopping all Timers
        //stopRecording()
        stopPlayback() // stop any possible playback
        
        if isComposing {
            
            _ = performanceViewHandler.removeLastPerformance()
            
            if performanceViewHandler.isEmpty() {
                newPerformance = true
                newRecordingView()
            }
            
            return
        }
        
        if let recordingView = recordingView {
            if performanceViewHandler.isEmpty() {
                // No loaded performances means we're in the jam tab, just reset to a new record view
                replyButton.setTitle("Reply", for: .normal)
                newRecordingView()
            } else {
                // Reset back to the loaded performances
                recordingView.removeFromSuperview()
                self.recordingView = nil // this is a bit confusing, it means to set the VC's recordingView to nil, not the present unwrapped local variable.
                replyButton.setTitle("Reply", for: .normal)
                newPerformance = false
                jamming = false
            }
        } else {
            // No record view means we have loaded performances, but haven't recorded anything yet. Just return to world table view
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func unwindToJamView(sender: UIStoryboardSegue) {
        // FIXME: I don't think this function is ever actually called. Find out and delete if necessary.
//        if sender.source is SettingsTableViewController {
//            // Unwinding from settings screen.
//            print("JAMVC: unwinding from a settings screen. Current state:", state)
//            if (state == ChirpJamModes.new) { // if it's still a new jam, update the sound scheme
//                print("JAMVC: updating the Pd file.")
//                updateUI()
//            }
//        }
    }

    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !performanceViewHandler.isEmpty() {
            
            // If we are in a composing state, it means we have returned from browse view. No need to add subviews
            if !isComposing {
                // If there are loaded performance from world controller, disable composing feature..
                addJamButton.isHidden = true
                statusLabel.text = "Loaded..."
                performerLabel.text = performanceViewHandler.performances.first?.performer
                navigationItem.title = performanceViewHandler.performances.first?.dateString
                replyto = performanceViewHandler.performances.first?.title()
                
                performanceViewHandler.displayImagesIn(view: chirpViewContainer)
                
            }
            
        } else {
            // there are no performances to playback (i.e., this is a blank recording).
            statusLabel.text = "New..."
            instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
            newPerformance = true
            newRecordingView()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("JAMVC: viewDidAppear.")
        
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
            }
        }
    }
    
    // MARK: - Creation of recording and playback views

    /// Creates a new ChirpView loaded with a ChirpPerformance and adds to the chirpViewContainer
    func newViewWith(performance: ChirpPerformance, withFrame frame: CGRect?) {

        if let _ = frame {
            performanceViewHandler.add(performance: performance, inView: chirpViewContainer)
        } else {
            // This is the case if we add performances before the view is displayed. No frame to reference
            performanceViewHandler.add(performance: performance)
        }
    }

    /// Resets to a new performance state.
    func newRecordingView() {

        if recordingView != nil {
            // Removing current performance and image view, pluss closing PdFile
            let _ = performanceViewHandler.removeLastPerformance()
        }
        
        // Creating a new performance
        performance = ChirpPerformance()
        performance!.performer = UserProfile.shared.profile.stageName
        performance!.instrument = SoundSchemes.namesForKeys[UserProfile.loadProfile().soundScheme]!
        // Creating a new imageView
        recordingView = UIImageView(frame: chirpViewContainer.bounds)
        recordingView!.image = UIImage()
        chirpViewContainer.addSubview(recordingView!) // Add image view to screen
        
        pdFile = performanceViewHandler.openUserSoundScheme()

        newPerformance = true
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
        
        if isRecording {
            stopRecording()
        } else {
            if performanceViewHandler.isPlaying {
                stopPlayback()
            } else {
                startPlayback()
            }
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
        replyButton.setTitle("Reset", for: .normal)
        
        stopPlayback()
        newRecordingView()
    }

    /// IBAction for the Jam Button
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        // TODO: implement some kind of generative performing here!
        if (jamming) {
            // Stop Jamming
            jamButton.setTitle("jam", for: UIControlState.normal)
            jamming = false
            if (performanceViewHandler.isPlaying) {
                performanceViewHandler.stopPerformances()
            }
        } else {
            // Start Jamming
            jamButton.setTitle("no jam", for: UIControlState.normal)
            jamming = true
            if (!performanceViewHandler.isPlaying) {
                playButtonPressed(playButton) // start playing if not already playing.
            }
        }
    }
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        let point = touches.first?.location(in: recordingView);
        
        if recordingEnabled {
            
            if (recordingView!.bounds.contains(point!) && !isRecording && newPerformance) {
                print("JAMVC: Starting a Recording")
                startRecording()
            }
            
            let size = touches.first?.majorRadius
            let touch = TouchRecord(time: -startTime!.timeIntervalSinceNow,
                                    x: Double(point!.x / view.frame.width),
                                    y: Double(point!.y / view.frame.height),
                                    z: Double(size!),
                                    moving: false)
            
            performanceViewHandler.drawDot(inImageView: recordingView!, atPoint: point!, withColor: performance!.colour.brighterColor.cgColor)
            performanceViewHandler.makeSound(withTouch: touch, andPdFile: pdFile!)
            performance!.performanceData.append(touch)
            
            previousPoint = point!
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if isRecording {
            
            let currentPoint = touches.first?.location(in: recordingView!)
            
            performanceViewHandler.drawLine(inImageView: recordingView!, fromPoint: previousPoint!, toPoint: currentPoint!, withColor: performance!.colour.brighterColor.cgColor)
            
            let size = touches.first?.majorRadius

            let touch = TouchRecord(time: -startTime!.timeIntervalSinceNow,
                                    x: Double(currentPoint!.x / view.frame.width),
                                    y: Double(currentPoint!.y / view.frame.height),
                                    z: Double(size!),
                                    moving: true)
            
            performanceViewHandler.makeSound(withTouch: touch, andPdFile: pdFile!)
            performance!.performanceData.append(touch)
            
            previousPoint = currentPoint

        }
    }
}

// MARK: - User Interface Updates

//extension ChirpJamViewController {
//    
//    /// Updates the image in each ChirpView/ChirpRecordingView with those referenced in their respective ChirpPerformances
//    func resetPerformanceImages() {
//        
//        if let recordView = recordingView {
//            recordView.image = recordView.performance?.image
//        }
//    }
//
//    /// Update the UI labels and image only if there is a valid performance loaded.
//    func updateUI() {
//        print("JAMVC: Updating UI.")
//
//        if isRecording {
//            statusLabel.text = "recording..."
//            playButton.isEnabled = false
//            jamButton.isEnabled = false
//            replyButton.isEnabled = false
//            performerLabel.text = UserProfile.shared.profile.stageName
//            instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
//        }
//
//        case ChirpJamModes.playing:
//
//            var loadedPerformance = self.performanceViews.last?.performance
//
//            if let recordingView = self.recordingView,
//                let performance = recordingView.performance {
//                loadedPerformance = performance
//            }
//
//            navigationItem.title = loadedPerformance?.dateString
//            performerLabel.text = loadedPerformance?.performer
//            instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)
//            playButton.isEnabled = true
//            jamButton.isEnabled = true
//
//            if newPerformance {
//                replyButton.isEnabled = false // Should not be able to reply to your own performance
//            } else {
//                replyButton.isEnabled = true // reply button enabled in loaded jams.
//            }
//            
//        default:
//            
//            if mode == ChirpJamModes.new {
//                navigationItem.title = "New Performance"
//                if let replytext = self.replyto {
//                    statusLabel.text = "reply to: " + replytext // setting reply to text
//                } else {
//                    statusLabel.text = "new" // new performance only.
//                }
//                performerLabel.text = UserProfile.shared.profile.stageName
//                instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
//                if let recordingView = self.recordingView {
//                    // Updating the color and soundscheme of the recording based on the user defaults.
//                    recordingView.performance?.colour = UserProfile.shared.profile.jamColour
//                    recordingView.recordingColour = recordingView.performance?.colour.cgColor
//                    recordingView.openUserSoundScheme()
//                }
//                playButton.isEnabled = true
//                replyButton.isEnabled = false
//                jamButton.isEnabled = true
//            
//            } else if mode == ChirpJamModes.composing {
//                statusLabel.text = "composing..."
//                performerLabel.text = UserProfile.shared.profile.stageName
//                playButton.isEnabled = true
//                replyButton.isEnabled = false
//                jamButton.isEnabled = true
//            
//            } else {
//                var loadedPerformance = self.performanceViews.last?.performance
//                
//                if let recordingView = self.recordingView,
//                    let performance = recordingView.performance {
//                    loadedPerformance = performance
//                }
//                
//                navigationItem.title = loadedPerformance?.dateString
//                statusLabel.text = "Loaded..."
//                performerLabel.text = loadedPerformance?.performer
//                instrumentButton.setTitle(loadedPerformance?.instrument, for: .normal)
//                playButton.isEnabled = true
//                replyButton.isEnabled = true
//                jamButton.isEnabled = true
//            }
//        }
//    }
//}

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
        startProgressBar()
        performanceViewHandler.playPerformances()
    }

    /// Stop playback and cancel timers.
    func stopPlayback() {
        print("JAMVC: Stopping any requested playback")
        
        performanceViewHandler.stopPerformances()
        stopProgressBar()
        performanceViewHandler.resetPerformanceImages()
        
        if newPerformance {
            statusLabel.text = "New..."
        } else {
            statusLabel.text = "Loaded..."
        }
    }
    
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        if newPerformance {
            NSLog("JAMVC: Starting a recording.")
            
            statusLabel.text = "Recording..."
            
            isRecording = true
            jamming = false
            
            playButton.setTitle("Stop", for: .normal)
            replyButton.isEnabled = false
            jamButton.isEnabled = false
            
            startTime = Date()
            startProgressBar()
            performanceViewHandler.playPerformances()
        }
    }
    
    func completeRecording() {
        
        isRecording = false
        stopPlayback()
        
        playButton.setTitle("Play", for: .normal)
        playButton.isEnabled = true
        replyButton.setTitle("Reset", for: .normal)
        replyButton.isEnabled = true
        jamButton.isEnabled = true
        
        // Put current recording in stack of performances
        performance!.image = recordingView!.image!
        performanceViewHandler.add(performance: performance!, withPdFile: pdFile!, andImageView: recordingView!)
    }
    
    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping recording; now loading the recorded performance.")
        
        isRecording = false
        stopPlayback()
        
        // Throw away current recording
        newRecordingView()
    }

    /// Automatically triggered when recording time finishes.
    func stopTimer() {
        // FIXME: Incorporate this method with stopPlayback?
        // FIXME: Make sure that the reply performances are reset as well as the main performance.
        NSLog("JAMVC: Stop Timer Called (either finished or cancelled).")

        stopProgressBar()

        // Restart Playback in Jam Mode.
        if (jamming) {
            print("JAMVC: Restarting playback for the jam.")
            if (!performanceViewHandler.isPlaying) {
                playButtonPressed(playButton) // start playing if not already playing.
            }
        }
    }
}

