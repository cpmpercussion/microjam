//
//  ViewController.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit
import DropDown
import CloudKit

var ALWAYS_SAVE_MODE: Bool = false /// set this to experiment mode for user studies, etc. - do not enable for archive or distribution!
var RECORDING_PARTICLES: Bool = false /// set this to enable recording particle system.
var OPEN_ON_RECORD_ENABLE: Bool = true /// set this to open the jam screen with recording already enabled.
var MIXER_AVAILABLE: Bool = true /// set this to enable access to the mixer screen.

// TODO: how to tell between loaded and saved and just loaded?

/// Main performance and playback ViewController for MicroJam
class ChirpJamViewController: UIViewController {
    /// Enters composing mode if a performance is added from within the ChirpJamController
    var isComposing = false
    /// Stores the present jamming state
    var jamming : Bool = false
    /// Stores the ChirpRecorder for recording a new performance
    var recorder: ChirpRecorder?
    /// Stores a robojamview
    var robojam: RoboJamView?
    /// String value of CKRecordID for storage of the original performance for a reply.
    var replyto : String?
    /// CKRecordID version of the above
    var replyParentID : CKRecord.ID?
    /// App delegate - in case we need to upload a performance.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    /// Dropdown menu for selecting SoundScheme
    let soundSchemeDropDown = DropDown() // dropdown menu for soundscheme
    /// Dropdown menu for deletion, sharing, export, etc.
    let menuDropDown = DropDown()
    /// Header Profile to be displayed at the top of the screen
    var headerProfile : PerformerProfile?

    /// Image view for storing avatar image
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            // automagically clip bounds and round to a circle.
            avatarImageView.clipsToBounds = true
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.height / 2
        }
    }

    /// Button for accessing contextual jam menu
    @IBOutlet weak var menuButton: UIButton!
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
    /// Right nav bar button for saving recorded performance
    @IBOutlet weak var savePerformanceButton: UIBarButtonItem!
    /// Left nav bar button for cancelling replies
    @IBOutlet weak var cancelPerformanceButton: UIBarButtonItem!
    /// Button for choosing/displaying soundscheme
    @IBOutlet weak var instrumentButton: UIButton!
    /// Button to add specific parent performances when composing a performance
    @IBOutlet weak var addJamButton: UIButton!
    /// Robojam button; requests an AI response performance
    @IBOutlet weak var robojamButton: UIButton!
    
    // MARK: - Navigation
    
    /// Prepare to segue - this is where the Jam screen actually saves performances! So it's an important check.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("JAMVC: Preparing for Segue.")
        
        /// Fixme this does nothing.
        if (sender as? MixerTableViewController) != nil {
            print("JAMVC: Preparing to segue to mixer, basically do nothing.")
            return
        }
        
        // FIXME: save the performance if the playback hasn't stopped.
        jamming = false // stop jamming.
        
        if let recorder = recorder,
            let finishedPerformance = recorder.recordingView.performance {
            /// FIXME: Save the robojam to a robo account as needed.
            
            /// TODO: make sure this doesn't stop when going to the mixer screen.
            recorder.stop()
            removeRobojam()
            
            if let barButton = sender as? UIBarButtonItem {
                if savePerformanceButton === barButton {
                    print("JAMVC: Save button segue!")
                    /// TODO: Store composing performances
                    if isComposing {
                        /// FIXME: hack to stop saving in composing mode
                        newRecordingView()
                    } else {
                        // save the performance and add to the world screen.
                        // this uploads, adds to the PerformanceStore and calls generateFeed so that
                        // feed will appear updated instantly.
                        PerformanceStore.shared.addNew(performance: finishedPerformance)
                    }
                    navigationController?.popViewController(animated: true)
                } else if ALWAYS_SAVE_MODE {
                    //let finishedPerformance = recorder.recordingView.performance
                    ///FIXME: only save a "significant" performance, i.e., including all data.
                    PerformanceStore.shared.addNew(performance: finishedPerformance) // save anyway.
                }
            }
        }
    }
    
    /// IBAction for Cancel (bar) button. stops playback/recording and dismisses present performance.
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        removeRobojam() // Throw away robojam if present.
        
        // Stop any chirps
        if let recorder = recorder {
            recorder.stop()
            
            // find out what tab we're in
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
                    recorder.recordingIsDone = false
                    playButton.isEnabled = false
                    robojamButton.isEnabled = false
                    jamButton.isEnabled = false
                    replyButton.isEnabled = true
                    newRecordingView()
                }
            }
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: viewDidLoad")
        
        // Setup particle emitter
        if RECORDING_PARTICLES {setupRecordingParticleEmitter()}
        
        // configuration for the chirpViewContainer
        chirpViewContainer.layer.cornerRadius = 8
        chirpViewContainer.layer.borderWidth = 1
        chirpViewContainer.clipsToBounds = true
        chirpViewContainer.contentMode = .scaleAspectFill
        
        // configure avatarImageView
        avatarImageView.contentMode = .scaleAspectFill // content mode for avatar.
        
        // rewind
        rewindButton.imageView?.contentMode = .scaleAspectFit
        rewindButton.tintColor = ButtonColors.rewind
        // rec enable
        recEnableButton.imageView?.contentMode = .scaleAspectFit
        recEnableButton.tintColor = ButtonColors.recordDisabled
        
        // play
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.tintColor = ButtonColors.play
        // add layer
        addJamButton.imageView?.contentMode = .scaleAspectFit
        addJamButton.tintColor = ButtonColors.layer
        if !MIXER_AVAILABLE {
            addJamButton.isHidden = true // hide the mixer button
        } else {
            addJamButton.isHidden = false // expose the mixer button
        }
        // jam
        jamButton.imageView?.contentMode = .scaleAspectFit
        jamButton.tintColor = ButtonColors.jam
        // robojam
        robojamButton.imageView?.contentMode = .scaleAspectFit
        robojamButton.tintColor = ButtonColors.robojam
        
        /// TODO: delete reply button
        // reply
        replyButton.imageView?.contentMode = .scaleAspectFit
        replyButton.isHidden = true // not using reply button in this view currently
        
        // need to initialise the recording progress at zero.
        recordingProgress!.progress = 0.0
        
        // Setting the correct instrument
        instrumentButton.setTitle(
            SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme],
            for: .normal)
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

        // Hide menu button!!
        menuButton.isHidden = true
        // FIXME: menu button is hidden for now, maybe unhide later when figured out?
        // Menu Dropdown initialisation
        menuDropDown.anchorView = menuButton
        menuDropDown.direction = .bottom
        menuDropDown.dataSource = ["share","export","delete"]
        menuDropDown.selectionAction = {(index: Int, item: String) -> Void in
            switch item {
            case "share":
                self.sharePerformance()
            case "export":
                self.exportPerformance()
            case "delete":
                self.deletePerformance()
            default:
                break
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(setColourTheme), name: .setColourTheme, object: nil) // notification for colour theme.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setColourTheme()
        
        if let recorder = recorder {
            // Loaded with an existing recorder (i.e., to make a reply)
            if !isComposing && !recorder.viewsAreLoaded {
                for view in recorder.chirpViews {
                    view.frame = chirpViewContainer.bounds
                    chirpViewContainer.addSubview(view)
                }
                
                recorder.viewsAreLoaded = true // Make sure the views are not added to the chirp container if they are already added
                recorder.delegate = self
                replyto = recorder.chirpViews.first?.performance?.title() // set reply parent title.
                replyParentID = recorder.chirpViews.first?.performance?.performanceID // set reply parent CKRecordID.
                
                if let last = recorder.chirpViews.last {
                    chirpViewContainer.backgroundColor = last.performance!.backgroundColour.darkerColor
                }
            }
            rewindButton.isEnabled = true
            cancelPerformanceButton.isEnabled = true
            
        } else {
            // Loaded with a new recorder. (i.e., in the jam tab)
            recorder = ChirpRecorder(frame: chirpViewContainer.bounds)
            recorder?.delegate = self
            chirpViewContainer.backgroundColor = UserProfile.shared.profile.backgroundColour.darkerColor
            // disable buttons that cannot be used in this state
            playButton.isEnabled = false
            robojamButton.isEnabled = false
            jamButton.isEnabled = false
            rewindButton.isEnabled = true
        }
        
        print("JamVC: Loaded with:", recorder ?? "nothing")
        
        newRecordingView()
        
        // Setup user data
        if let headerProfile = headerProfile {
            performerLabel.text = headerProfile.stageName
            avatarImageView.image = headerProfile.avatar
        } else {
            print("JAMVC: Failed to load headerProfile")
            performerLabel.text = UserProfile.shared.profile.stageName // set performer label to current user.
            avatarImageView.image = UserProfile.shared.profile.avatar // set performer avatar to be current user.
        }
        
        // Add constraints for chirpViewContainer's subviews.
        for view in chirpViewContainer.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.constrainEdgesTo(chirpViewContainer)
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeRobojam()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // disable cancel button in jam tab
        /// FIXME: This seems only possible _after_ the view appears?
        if tabBarController?.selectedViewController?.tabBarItem.title == TabBarItemTitles.jamTab {
            cancelPerformanceButton.isEnabled = false
        } else {
            cancelPerformanceButton.isEnabled = true
        }
        
        // disable/enable the save button
        if let rec = recorder, rec.recordingIsDone {
            savePerformanceButton.isEnabled = true
        } else {
            savePerformanceButton.isEnabled = false
            // Force recording on for demos and experiments
            if OPEN_ON_RECORD_ENABLE {
                setRecordingEnabled() // force recording to be enabled.
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .setColourTheme, object: nil)
    }
    
    /// Called if instrument is changed in the dropdown menu
    func instrumentChanged() {
        if let recorder = recorder {
            recorder.recordingView.openUserSoundScheme()
            instrumentButton.setTitle(SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme], for: .normal)
        }
    }
    
    // MARK: - Creation of recording and playback views

    /// Resets to a new performance state.
    func newRecordingView() {
        print("JAMVC: Reset to new recording view")
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
            savePerformanceButton.isEnabled = false // no saving a blank recording
            setRecordingDisabled() // set recording button to be disabled.
            recEnableButton.isEnabled = true // enable recording button.
        }
        
        // Force recording on for demos and experiments
        if OPEN_ON_RECORD_ENABLE {
            setRecordingEnabled() // force recording to be enabled.
        }
    }

    // MARK: - UI Interaction Functions
    
    /// Set the record enable state and pulse the record button
    func setRecordingEnabled() {
        recEnableButton.pulseGlow()
        recorder?.recordingEnabled = true
    }
    
    /// Set the record disabled state and deactivate the button glow.
    func setRecordingDisabled() {
        print("JAMVC: Recording disabled.")
        recEnableButton.deactivateGlowing()
        recorder?.recordingEnabled = false
    }
    
    /// IBAction for the rewind button
    @IBAction func rewindScreen(_ sender: UIButton) {
        print("JAMVC: Rewind pressed, clearing screen")
        if let recorder = recorder,
            let finishedPerformance = recorder.recordingView.performance {
            if ALWAYS_SAVE_MODE {
                PerformanceStore.shared.addNew(performance: finishedPerformance) // save anyway.
            }
            // Clean up the views.
            recordingProgress.progress = 0.0
            recorder.stop()
            newRecordingView()
            replyButton.isEnabled = false
            if !recorder.viewsAreLoaded {
                // There is nothing to be played or jammed
                playButton.isEnabled = false
                robojamButton.isEnabled = false
                jamButton.isEnabled = false
            }
        }
        removeRobojam()
    }
    
    /// IBAction for the record enable button
    @IBAction func recordEnablePressed(_ sender: UIButton) {
        if let recorder = recorder {
            if !recorder.recordingEnabled {
                setRecordingEnabled()
            } else {
                setRecordingDisabled()
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

    /// Open the mixer screen to experiment with performance methods.
    @IBAction func openMixer(_ sender: UIButton) {
        if let recorder = recorder {
            let controller = MixerTableViewController(withChirps: recorder.chirpViews)
            controller.controllerToMix = self
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    /// IBAction for the play button. Starts playback of performance and replies iff in loaded mode. Stops if already playing.
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if let recorder = recorder {
            if recorder.isPlaying {
                // pause
                playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                playButton.deactivateGlowing(withDeactivatedColour: ButtonColors.play)
                jamButton.isEnabled = true
                if recorder.isRecording {
                    replyButton.isEnabled = true
                }
                recordingProgress.progress = 0.0
                recorder.stop()
            } else {
                // play
                playButton.setImage(#imageLiteral(resourceName: "microjam-pause"), for: .normal)
                playButton.solidGlow(withColour: ButtonColors.play.brighterColor, andTint: ButtonColors.play)
                jamButton.isEnabled = false
                recorder.play()
            }
        }
    }

    /// IBAction for the SoundScheme button. Opens a dropdown menu for selection when in "new" state.
    @IBAction func soundSchemeTapped(_ sender: Any) {
        // TODO: should there be some kind of change in loaded mode? Like changing the user's layer sound, or adjusting the previous performers' sound?
        // IF new then, allow dropdown to show.
        soundSchemeDropDown.show()
    }

    /// Action triggered when the menu button is tapped. Opens a dropdown menu for selection
    @IBAction func menuButtonTapped(_ sender: UIButton) {
        menuDropDown.show()
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
            // stop looping
            jamButton.deactivateGlowing(withDeactivatedColour: ButtonColors.jam)
            jamming = false
            // set play button to pause icon and glow here, doesn't have to be disabled.
            playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
            playButton.deactivateGlowing(withDeactivatedColour: ButtonColors.play)
            playButton.isEnabled = true
            // set recording status.
            recordingProgress.progress = 0.0
            if let recorder = recorder {
                recorder.stop()
            }
        } else {
            // stop looping
            jamButton.solidGlow(withColour: ButtonColors.jam, andTint: ButtonColors.jam.brighterColor)
            jamming = true
            // set play button to pause icon and glow here, doesn't have to be disabled.
            playButton.setImage(#imageLiteral(resourceName: "microjam-pause"), for: .normal)
            playButton.solidGlow(withColour: ButtonColors.play.brighterColor, andTint: ButtonColors.play)
            playButton.isEnabled = false
            // set recording status.
            if let recorder = recorder {
                recorder.play()
            }
        }
    }
    
    // MARK: Robojam Methods
    
    /// Robojam Button Pressed, request an AI response and add as a layer.
    @IBAction func robojamPressed(_ sender: UIButton) {
        // guard let perf = self.recorder?.recordingView.saveRecording() else { }
        guard let perf = self.recorder?.recordingView.performance else {
            print("No perf to respond to.")
            return
        }
        RobojamMaker.requestRobojam(from: perf, for: self)
        robojamButton.startBopping()
    }
}

/// Extension for Touch User Interface Overrides
extension ChirpJamViewController {
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start recording if needed.
        if let recorder = recorder,
             let point = touches.first?.location(in: recorder.recordingView) {
            if (recorder.recordingView.bounds.contains(point)) {
                if recorder.record() { // Returns true if recording is starting
                    print("JAMVC: Starting a Recording")
                    playButton.isEnabled = true
                    playButton.setImage(#imageLiteral(resourceName: "microjam-stop"), for: .normal)
                }
                
                /// Set the particle emitter point
                if let pointInCJVCView = touches.first?.location(in: self.view) {
                    recordingParticleEmitter?.emitterPosition = pointInCJVCView // set the particle emitter point
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, chirpViewContainer.bounds.contains(touch.location(in: chirpViewContainer)) {
            //print("updating emitter point to", touch)
            recordingParticleEmitter?.emitterPosition = touch.location(in: self.view) // set the particle emitter point
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // no action right now.
    }
}

// MARK: Menu button action methods
extension ChirpJamViewController {

    func exportPerformance() {

    }

    func sharePerformance() {

    }

    func deletePerformance() {
        /// TODO: This code doesn't seem to do anything?
        print("Attempt to delete a performance")
        if let recorder = recorder {
            if let creator = recorder.recordingView.performance?.creatorID {
                print("rec view:", creator)
            }
            if let perfID = recorder.recordingView.performance?.performanceID {
                print("rec view:", perfID)
            }
            if let creator = recorder.chirpViews.first?.performance?.creatorID {
                print("perf view:",creator)
            }
            if let perfID = recorder.recordingView.performance?.performanceID {
                print("perf view:", perfID)
            }
        }
    }

}

// MARK: Player delegate methods
extension ChirpJamViewController: PlayerDelegate {
    
    /// Updated UI to reflect that recording or playback has started.
    func playbackStarted() {
        if let rec = recorder, rec.isRecording {
            print("Recording")
            recEnableButton.solidGlow() // solid recording light.
            createParticles()
        }
    }
    
    
    /// Updates the progress bar in response to steps from the ChirpPlayer
    func playbackStep(_ time: Double) {
        DispatchQueue.main.async { self.recordingProgress.progress = Float(time / 5.0) }
    }

    /// Updates UI when the ChirpPlayer reports playback/recording has finished.
    func playbackEnded() {
        self.stopParticles()
        self.recordingProgress.progress = 0.0
        self.recorder!.stop()
        
        // continue playing if jamming is enabled
        if self.jamming {
            self.recorder!.play()
            return
        }
        
        // enable saving and replying if recording is finished.
        if let rec = recorder, rec.recordingIsDone {
            self.setRecordingDisabled()
            self.replyButton.isEnabled = true
            self.savePerformanceButton.isEnabled = true
            self.robojamButton.isEnabled = true
            self.recEnableButton.isEnabled = false
        }
        self.rewindButton.isEnabled = true
        self.jamButton.isEnabled = true
        self.playButton.isEnabled = true
        self.playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
        self.playButton.deactivateGlowing(withDeactivatedColour: ButtonColors.play)
    }
}

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


/// Robojam Functions Extension for ChirpJam View Controller
extension ChirpJamViewController {
    
    /// Remove existing RoboJam
    func removeRobojam() {
        if let recorder = recorder, let existingRoboJam = self.robojam {
            existingRoboJam.closePdFile()
            if let index = recorder.chirpViews.index(of: existingRoboJam) {
                recorder.chirpViews.remove(at: index)
            }
            existingRoboJam.removeFromSuperview()
        }
    }
    
    // Add an extra jam from the RoboJam servers
    func addRobojam(_ performance: ChirpPerformance) {
        removeRobojam() // remove a robojam that might already be there.
        // change the robojam's instrument to be other than the previously recorded view.
        if let currentInstrument = recorder?.recordingView.performance?.instrument {
            performance.instrument = RobojamMaker.chooseOtherInstrument(currentInstrument)
        }
        // Add the robojam to the view hierarchy.
        if let recorder = recorder {
            self.robojam = RoboJamView(with: chirpViewContainer.bounds, andPerformance: performance)
            if let robojam = self.robojam {
                recorder.chirpViews.append(robojam)
                chirpViewContainer.addSubview(robojam)
                chirpViewContainer.bringSubviewToFront(recorder.recordingView)
                robojam.generateImage()
                print("Response added!")
                robojamButton.shake()
            }
        }
    }
    
    func robojamFailed() {
        /// Could not get a robojam
        robojamButton.stopBopping()
    }

}

/// Extension for static instantiation functions. Three options: jam, playback, and reply.
extension ChirpJamViewController {
    
    enum JamViewMode {
        case jamming
        case replying
        case playing
    }
    
    static func instantiateController(forArrayOfPerformances performanceArray: [ChirpPerformance]) -> ChirpJamViewController {
        // Instantiate a ChirpJamViewController from storyboard
        print("JAMVC: Initialising a playback controller from storyboard.")
        let storyboard = UIStoryboard(name: "ChirpJamViewController", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "userPerfChirpJamController") as! ChirpJamViewController
        
        // Make a ChirpRecorder for the reply and set to the new ChirpJamViewController
        let recorder = ChirpRecorder(withArrayOfPerformances: performanceArray) // FIXME: This makes it a recorder, only want playback here.
        controller.recorder = recorder
        
        if let playbackPerformerProfileID = performanceArray.first?.creatorID,
            let playbackPerformerProfile = PerformerProfileStore.shared.getProfile(forID: playbackPerformerProfileID) {
            controller.headerProfile = playbackPerformerProfile
            print("JAMVC: Setting header profile to: \(playbackPerformerProfile)")
        }
        // Setup the interface following "willAppear"
        //controller.mode = JamViewMode.playing
        return controller
        // TODO: still need to set the instrument label to the correct instrument.
    }
    
    static func instantiateReplyController(forPlayer player: ChirpPlayer) -> ChirpJamViewController {
        // Instantiate a ChirpJamViewController from storyboard
        print("JAMVC: Initialising a reply controller from storyboard.")
        let storyboard = UIStoryboard(name: "ChirpJamViewController", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "userPerfChirpJamController") as! ChirpJamViewController
        
        // Make a ChirpRecorder for the reply and set to the new ChirpJamViewController
        let recorder = ChirpRecorder(frame: CGRect.zero, player: player)
        controller.recorder = recorder
        
        // Setup the interface following "willAppear"
        //controller.mode = JamViewMode.replying
        controller.headerProfile = UserProfile.shared.profile
        return controller
    }
    
    /// Instantiate a jam controller.
    static func instantiateJamController() -> ChirpJamViewController {
        print("JAMVC: Initialising a jam controller from storyboard.")
        let storyboard = UIStoryboard(name:"ChirpJamViewController", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "userPerfChirpJamController") as! ChirpJamViewController
        
        // do more setup from "willAppear" function
        //controller.mode = JamViewMode.jamming
        controller.headerProfile = UserProfile.shared.profile
        return controller
    }
}

/// Particle Emitter Layer for pretty FX when recording.
var recordingParticleEmitter: CAEmitterLayer?
/// Extension for Particle Effects from Jam recording
extension ChirpJamViewController {

    /// Initial setup of the particle layer.
    func setupRecordingParticleEmitter() {
        print("JAMVC: setting up particle emitter")
        recordingParticleEmitter = CAEmitterLayer()
        if let recordingParticleEmitter = recordingParticleEmitter {
            recordingParticleEmitter.emitterPosition = CGPoint(x: view.center.x, y: view.center.y)
            recordingParticleEmitter.emitterShape = CAEmitterLayerEmitterShape.point
            
            let cell = CAEmitterCell()
            cell.name = "recording"
            cell.lifetime = 1.5
            cell.velocity = 200
            cell.velocityRange = 50
            cell.emissionLongitude = CGFloat.pi / 2
            cell.emissionRange = CGFloat.pi / 10
            cell.spin = 4
            cell.spinRange = 4
            cell.scale = 0.2
            cell.scaleRange = 0.5
            cell.scaleSpeed = -0.1
            cell.alphaRange = 0.20
            cell.alphaSpeed = -1.0
            cell.contents = UIImage(named: "tinystar")?.cgImage
            
            recordingParticleEmitter.emitterCells = [cell]
            view.layer.addSublayer(recordingParticleEmitter)
        }
    }
    
    /// Start generating particles.
    func createParticles() {
        // set color to current performance
        if let col = recorder?.recordingView.performance?.colour {
            recordingParticleEmitter?.setValue(col.cgColor, forKeyPath: "emitterCells.recording.color")
        }
        recordingParticleEmitter?.setValue(100, forKeyPath: "emitterCells.recording.birthRate")
    }
    
    /// Stop generating particles.
    func stopParticles() {
        recordingParticleEmitter?.setValue(0, forKeyPath: "emitterCells.recording.birthRate")
    }
}

// Set up dark and light mode.
extension ChirpJamViewController {
    
    @objc func setColourTheme() {
        UserDefaults.standard.bool(forKey: SettingsKeys.darkMode) ? setDarkMode() : setLightMode()
    }
    
    func setDarkMode() {
        view.backgroundColor = DarkMode.background
        //        tableView.backgroundColor = DarkMode.background
        performerLabel.textColor = DarkMode.text
        instrumentButton.setTitleColor(DarkMode.text, for: .normal)
        chirpViewContainer.layer.borderColor = DarkMode.midforeground.cgColor
        recordingProgress.backgroundColor = DarkMode.midbackground
        recordingProgress.progressTintColor = DarkMode.highlight
        menuButton.setTitleColor(DarkMode.text, for: .normal)
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = DarkMode.highlight
        navigationController?.view.backgroundColor = DarkMode.background
    }
    
    func setLightMode() {
        view.backgroundColor = LightMode.background
        //        tableView.backgroundColor = LightMode.background
        performerLabel.textColor = LightMode.text
        instrumentButton.setTitleColor(LightMode.text, for: .normal)
        chirpViewContainer.layer.borderColor = LightMode.midforeground.cgColor
        menuButton.setTitleColor(LightMode.text, for: .normal)
        recordingProgress.backgroundColor = LightMode.midbackground
        recordingProgress.progressTintColor = LightMode.highlight
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = LightMode.highlight
        navigationController?.view.backgroundColor = LightMode.background
    }
}

