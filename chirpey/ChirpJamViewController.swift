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
    var replyParentID : CKRecordID?
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
    
    /// Initialises ViewController directly from the storyboard with the same name. Used to instantiate programmatically.
    static func storyboardInstance() -> ChirpJamViewController? {
        print("JAMVC: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"ChirpJamViewController", bundle: nil)
        //        let controller = storyboard.instantiateViewController(withIdentifier: "chirpJamController") as? ChirpJamViewController
        let controller = storyboard.instantiateViewController(withIdentifier: "userPerfChirpJamController") as? ChirpJamViewController
        //        let controller = storyboard.instantiateInitialViewController() as? ChirpJamViewController
        return controller
    }

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
                    recorder.recordingEnabled = false
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            
            // enable the cancel button
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
        performerLabel.text = recorder!.recordingView.performance!.performer // set performer label to current user.
        avatarImageView.image = UserProfile.shared.profile.avatar // set performer avatar to be current user.
        
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
        }
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
                roboplayButton.isEnabled = false
                jamButton.isEnabled = false
                // and recording is disabled.
                recEnableButton.tintColor = UIColor.red.darkerColor
            }
        }
        removeRoboJam()
    }
    
    /// IBAction for the record enable button
    @IBAction func recordEnablePressed(_ sender: UIButton) {
        if let recorder = recorder {
            if !recorder.recordingEnabled {
                // recording was not enabled.
                print("JAMVC: Record pressed; enabled.")

                recEnableButton.tintColor = UIColor.red
                recorder.recordingEnabled = true
            } else {
                print("JAMVC: Record pressed; disabled.")

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
    
    let roboResponseEndpoint: String = "http://138.197.179.234:5000/api/predict"    // TODO: Change this to https
    //let roboResponseEndpoint: String = "https://0.0.0.0:5000/api/predict"
    
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
        
        let session = URLSession.shared
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
            }
        }
    }
}

// MARK: Player delegate methods

extension ChirpJamViewController: PlayerDelegate {
    
    /// Updates the progress bar in response to steps from the ChirpPlayer
    func progressTimerStep() {
        recordingProgress.progress = Float(recorder!.progress / recorder!.maxPlayerTime)
    }

    /// Updates UI when the ChirpPlayer reports playback/recording has finished.
    func progressTimerEnded() {
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
                chirpViewContainer.bringSubview(toFront: recorder.recordingView)
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
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 1.0
        animation.values = [-10.0, 10.0, -5.0, 5.0, -2.5, 2.5, -1, 1, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    func stopBopping() {
        layer.removeAnimation(forKey: "bop")
    }
    
    func startBopping() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.2
        animation.values = [-2.5,2.5,0]
        animation.repeatCount = 100
        layer.add(animation, forKey: "bop")
    }
    
    func startSwirling() {
        let animationX = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animationX.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animationX.duration = 0.2
        animationX.values = [0,-2.5,2.5,0]
        animationX.repeatCount = 100
        let animationY = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animationY.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
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
