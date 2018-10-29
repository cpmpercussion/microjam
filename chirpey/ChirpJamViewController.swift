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
    /// Roboplay button; requests an AI response performance
    @IBOutlet weak var roboplayButton: UIButton!
    
    // MARK: - Navigation
    
    /// Prepare to segue - this is where the Jam screen actually saves performances! So it's an important check.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("JAMVC: Preparing for Segue.")
        // FIXME: save the performance if the timer hasn't run out.
        jamming = false // stop jamming.
        
        if let recorder = recorder,
            let finishedPerformance = recorder.recordingView.performance {
            /// FIXME: Save the robojam to a robo account as needed.
            recorder.stop()
            removeRoboJam()
            
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
        removeRoboJam() // Throw away robojam if present.
        
        // Stop any timers
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
                    roboplayButton.isEnabled = false
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
        chirpViewContainer.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        chirpViewContainer.clipsToBounds = true
        chirpViewContainer.contentMode = .scaleAspectFill
        
        // configure avatarImageView
        avatarImageView.contentMode = .scaleAspectFill // content mode for avatar.
        
        // rewind
        rewindButton.imageView?.contentMode = .scaleAspectFit
        rewindButton.tintColor = ButtonColors.rewind
        // rec enable
        recEnableButton.imageView?.contentMode = .scaleAspectFit
        recEnableButton.tintColor = ButtonColors.record.darkerColor
        
        // play
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.tintColor = ButtonColors.play
        // add layer
        addJamButton.imageView?.contentMode = .scaleAspectFit
        addJamButton.tintColor = ButtonColors.layer
        addJamButton.isHidden = true // hide the add layer button for now.
        // jam
        jamButton.imageView?.contentMode = .scaleAspectFit
        jamButton.tintColor = ButtonColors.jam
        // roboplay
        roboplayButton.imageView?.contentMode = .scaleAspectFit
        roboplayButton.tintColor = ButtonColors.roboplay
        
        /// TODO: delete reply button
        // reply
        replyButton.imageView?.contentMode = .scaleAspectFit
        replyButton.isHidden = true // not using reply button in this view currently
        
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
            roboplayButton.isEnabled = false
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
        removeRoboJam()
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
    
    func setRecordingEnabled() {
        // recording was not enabled.
        //TODO: make blinking light for record enable.
        print("JAMVC: Recording enabled.")
        recEnableButton.pulseGlow()
        recorder?.recordingEnabled = true
    }
    
    func setRecordingDisabled() {
        print("JAMVC: Recording disabled.")
        // stop recEnableGlowing
        recEnableButton.deactivateGlowing()
        recEnableButton.tintColor = UIColor.red.darkerColor
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
                roboplayButton.isEnabled = false
                jamButton.isEnabled = false
            }
        }
        removeRoboJam()
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


    /// IBAction for the play button. Starts playback of performance and replies iff in loaded mode. Stops if already playing.
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if let recorder = recorder {
            if recorder.isPlaying {
                playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
                playButton.tintColor = UIColor.init("#F79256")
                jamButton.isEnabled = true
                if recorder.isRecording {
                    replyButton.isEnabled = true
                }
                recordingProgress.progress = 0.0
                recorder.stop()
            
            } else {
                playButton.setImage(#imageLiteral(resourceName: "microjam-pause"), for: .normal)
                playButton.tintColor = UIColor.init("#F79256").brighterColor
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
            // Stop Jamming
            jamButton.tintColor = UIColor.init("#1D4E89")
            jamming = false
            playButton.isEnabled = true
            recordingProgress.progress = 0.0
            if let recorder = recorder {
                recorder.stop()
            }
        } else {
            // Start Jamming
            jamButton.tintColor = UIColor.init("#1D4E89").brighterColor
            jamming = true
            playButton.isEnabled = false
            if let recorder = recorder {
                recorder.play()
            }
        }
    }
    
    // MARK: Robojam Methods
    
    let roboResponseEndpoint: String = "https://138.197.179.234:5000/api/predict"
    // let roboResponseEndpoint: String = "https://0.0.0.0:5000/api/predict" // for local testing.
    
    /// Roboplay Button Pressed, request an AI response and add as a layer.
    @IBAction func roboplayPressed(_ sender: UIButton) {
        // nice shake animation
        //sender.shake()

        guard let perfToRespond = self.recorder?.recordingView.saveRecording()?.csv() else {
            print("No perf to respond to.")
            return
        }
        // print("found performance: \(perfToRespond)")
        guard let roboResponseURL = URL(string: roboResponseEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        // print("have URL: \(roboResponseURL)")
        
        var roboResponseUrlRequest = URLRequest(url: roboResponseURL)
        roboResponseUrlRequest.httpMethod = "POST"
        
        let perfRequest: [String: Any] = ["perf": perfToRespond]
        let jsonPerfRequest: Data
        do {
            jsonPerfRequest = try JSONSerialization.data(withJSONObject: perfRequest, options: [])
            roboResponseUrlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            roboResponseUrlRequest.httpBody = jsonPerfRequest
        } catch {
            print("Error: cannot create JSON")
            return
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: RobojamCertificatePinningDelegate(), delegateQueue: nil)
        let task = session.dataTask(with: roboResponseUrlRequest) { data, response, error in
            // do stuff with response, data & error here
            DispatchQueue.main.async{
                self.roboplayButton.stopBopping() // first stop the bopping.
            }
            guard error == nil else {
                print("error calling POST on /api/predict")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON, since that's what the API provides
            self.roboplayResponseHandler(responseData)
        }
        roboplayButton.startBopping()
        task.resume()
    }
    
    /// Parses Responses from the Roboplay server.
    func roboplayResponseHandler(_ data: Data) {
        print("Roboplay: Parsing response.")
        do {
            guard let responsePerfJSON = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any] else {
                    print("error trying to convert data to JSON")
                    return
            }
            // print("The response is: " + responsePerfJSON.description)
            guard let responsePerfCSV = responsePerfJSON["response"] as? String else {
                print("Could not parse JSON")
                return
            }
            // print("Response found!")
            // print("The response was: " + responsePerfCSV)
            if let responsePerf = createRoboJam(responsePerfCSV) {
                DispatchQueue.main.async{
                    self.addRoboJam(responsePerf)
                    print("Response added!")
                    self.roboplayButton.shake()
                }
            }
            // do something with it.
        } catch  {
            print("error trying to convert data to JSON")
            return
        }
    }
}

/// Extension for Touch User Interface Overrides
extension ChirpJamViewController {
    
    /// touchesBegan method starts a recording if this is the first touch in a new microjam.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
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
    func progressTimerStarted() {
    print("Progress Timer started")
        if let rec = recorder, rec.isRecording {
            print("Recorder is recording")
            recEnableButton.solidGlow() // solid recording light.
            createParticles()
        }
    }
    
    
    /// Updates the progress bar in response to steps from the ChirpPlayer
    func progressTimerStep() {
        recordingProgress.progress = Float(recorder!.progress / recorder!.maxPlayerTime)
    }

    /// Updates UI when the ChirpPlayer reports playback/recording has finished.
    func progressTimerEnded() {
        stopParticles()
        recordingProgress.progress = 0.0
        recorder!.stop()
        
        // continue playing if jamming is enabled
        if jamming {
            recorder!.play()
            return
        }
        
        // enable saving and replying if recording is finished.
        if let rec = recorder, rec.recordingIsDone {
            replyButton.isEnabled = true
            savePerformanceButton.isEnabled = true
            roboplayButton.isEnabled = true
            
            setRecordingDisabled() //
            recEnableButton.isEnabled = false
            // do other things to make sure recording is preserved properly.
        }
        
        rewindButton.isEnabled = true
        jamButton.isEnabled = true
        playButton.isEnabled = true
        playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
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

// MARK: - Robojam HTTPS Certificate Pinning URLSession delegate
// adapted from lifeisfoo https://stackoverflow.com/a/34223292/1646138
class RobojamCertificatePinningDelegate: NSObject, URLSessionDelegate {
    
    /// Robojam server certificate file
    private let robojamCertificateFile = "robojamCertificate"
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        // Adapted from OWASP https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning#iOS
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust),
            let serverTrust = challenge.protectionSpace.serverTrust {
                var secresult = SecTrustResultType.invalid
                let status = SecTrustEvaluate(serverTrust, &secresult)
                
                if (errSecSuccess == status), let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                        let serverCertificateData = SecCertificateCopyData(serverCertificate)
                        let data = CFDataGetBytePtr(serverCertificateData);
                        let size = CFDataGetLength(serverCertificateData);
                        let cert1 = NSData(bytes: data, length: size)
                        let file_der = Bundle.main.path(forResource: robojamCertificateFile, ofType: "der")
                        
                        if let file = file_der, let cert2 = NSData(contentsOfFile: file), cert1.isEqual(to: cert2 as Data) {
                                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
                                    return
                        }
                }
        }
        // Pinning failed
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }
    
}

// MARK: - Robojam Functions Extension

extension ChirpJamViewController {
    
    /// Remove existing RoboJam
    func removeRoboJam() {
        if let recorder = recorder, let existingRoboJam = self.robojam {
            existingRoboJam.closePdFile()
            if let index = recorder.chirpViews.index(of: existingRoboJam) {
                recorder.chirpViews.remove(at: index)
            }
            existingRoboJam.removeFromSuperview()
        }
    }
    
    // Add an extra jam from the RoboJam servers
    func addRoboJam(_ performance: ChirpPerformance) {
        removeRoboJam() // remove a robojam that might already be there.
        if let recorder = recorder {
            self.robojam = RoboJamView(with: chirpViewContainer.bounds, andPerformance: performance)
            if let robojam = self.robojam {
                recorder.chirpViews.append(robojam)
                chirpViewContainer.addSubview(robojam)
                chirpViewContainer.bringSubviewToFront(recorder.recordingView)
                robojam.generateImage()
            }
        }
    }
    
    /// Transform a RoboJam response into ChirpPerformance for playback.
    func createRoboJam(_ perfCSV: String) -> ChirpPerformance? {
        var instrument = RoboJamPerfData.instrument
        if let currentInstrument = recorder?.recordingView.performance?.instrument {
            instrument = chooseOtherInstrument(currentInstrument)
        }
        
        return ChirpPerformance(csv: perfCSV, date: Date(), performer: RoboJamPerfData.performer, instrument: instrument, image: UIImage(), location: RoboJamPerfData.fakeLocation, colour: RoboJamPerfData.color, background: RoboJamPerfData.bg, replyto: "", performanceID: RoboJamPerfData.id, creatorID: RoboJamPerfData.creator)
    }
    
    func chooseOtherInstrument(_ inst: String) -> String {
        var instChoices = SoundSchemes.keysForNames.keys.filter { $0 != inst } as [String]
        let choice = instChoices[Int(arc4random_uniform(UInt32(instChoices.count)))]
        print("RoboJam is playing: \(choice)")
        return choice
    }
}

/// Shake animation for a UIButton
extension UIButton {
    /// Shakes the button a little bit.
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 1.0
        animation.values = [-10.0, 10.0, -5.0, 5.0, -2.5, 2.5, -1, 1, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    func stopBopping() {
        layer.removeAnimation(forKey: "bop")
    }
    
    func startBopping() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.2
        animation.values = [-2.5,2.5,0]
        animation.repeatCount = 100
        layer.add(animation, forKey: "bop")
    }
    
    func startSwirling() {
        let animationX = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animationX.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animationX.duration = 0.2
        animationX.values = [0,-2.5,2.5,0]
        animationX.repeatCount = 100
        let animationY = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animationY.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animationY.duration = 0.2
        animationY.values = [-2.5,0,0,2.5]
        animationY.repeatCount = 100
        layer.add(animationX, forKey: "swirl_x")
        layer.add(animationY, forKey: "swirl_y")
    }
    
    func stopSwirling() {
        layer.removeAnimation(forKey: "swirl_x")
        layer.removeAnimation(forKey: "swirl_y")
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

/// Constant for the maximum glow opacity for record pulse animations.
let maximumGlowOpacity: Float = 0.9

/// UIView Animation Extensions
extension UIButton{
    
    func setupGlowShadow() {
        self.layer.shadowOffset = .zero
        self.layer.shadowColor = UIColor.init("#E5470D").cgColor
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = maximumGlowOpacity
        //        recEnableButton.layer.shadowPath = UIBezierPath(rect: recEnableButton.bounds).cgPath
        let glowWidth = self.bounds.height
        let glowOffset = 0.5 * (self.bounds.width - glowWidth)
        self.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: glowOffset,
                                                            y:0,
                                                            width: glowWidth,
                                                            height: glowWidth)).cgPath
    }
    
    func pulseGlow() {
        setupGlowShadow()
        // Tint Color Animation
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: {self.tintColor = UIColor.red}, completion: nil)
        self.tintColor = UIColor.red.darkerColor

        // Shadow animation
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.05
        animation.toValue = maximumGlowOpacity
        animation.duration = 0.25
        animation.repeatCount = 100000
        animation.autoreverses = true
        self.layer.add(animation, forKey: animation.keyPath)
        self.layer.shadowOpacity = 0.05
    }
    
    func deactivateGlowing() {
        //print(self.layer.animationKeys())
        self.layer.removeAllAnimations()
        //print(self.imageView?.layer.animationKeys())
        self.imageView?.layer.removeAllAnimations()
        self.layer.shadowOpacity = 0.0
        self.tintColor = UIColor.red.darkerColor
    }
    
    func solidGlow() {
        self.layer.removeAllAnimations()
        self.imageView?.layer.removeAllAnimations()
        setupGlowShadow()
        self.layer.shadowOpacity = maximumGlowOpacity
        self.tintColor = UIColor.red
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
            //cell.color = UIColor.red.cgColor
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
        //        tableView.backgroundColor = UIColor.black
        performerLabel.textColor = DarkMode.text
        instrumentButton.setTitleColor(DarkMode.text, for: .normal)
        recordingProgress.backgroundColor = DarkMode.midbackground
        recordingProgress.progressTintColor = DarkMode.highlight
        menuButton.setTitleColor(DarkMode.text, for: .normal)
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = DarkMode.highlight
        navigationController?.view.backgroundColor = DarkMode.background
    }
    
    func setLightMode() {
        view.backgroundColor = LightMode.background
        //        tableView.backgroundColor = UIColor.black
        performerLabel.textColor = LightMode.text
        instrumentButton.setTitleColor(LightMode.text, for: .normal)
        menuButton.setTitleColor(LightMode.text, for: .normal)
        recordingProgress.backgroundColor = LightMode.midbackground
        recordingProgress.progressTintColor = LightMode.highlight
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = LightMode.highlight
        navigationController?.view.backgroundColor = LightMode.background
    }
}
