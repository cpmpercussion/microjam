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

/// Colours for buttons in Jam Screen
struct ButtonColors {
    static let rewind = UIColor.init("#A10702")
    static let record = UIColor.init("#ED2D07")
    static let play = UIColor.init("#FAA613")
    static let layer = UIColor.init("#7DCFB6")
    static let jam = UIColor.init("#688E26")
    static let roboplay = UIColor.init("#550527")
}


// TODO: how to tell between loaded and saved and just loaded?

class ChirpJamViewController: UIViewController {
    /// Enters composing mode if a performance is added from within the ChirpJamController
    var isComposing = false
    /// Stores the present jamming state
    var jamming : Bool = false
    /// Stores the ChirpRecorder for recording a new performance
    var recorder: ChirpRecorder?
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
                replyto = recorder.chirpViews.first?.performance?.title() // set reply
                
                if let last = recorder.chirpViews.last {
                    chirpViewContainer.backgroundColor = last.performance!.backgroundColour.darkerColor
                }
            }
            rewindButton.isEnabled = false
            
            // enable the cancel button
            cancelPerformanceButton.isEnabled = true
            
        } else {
            // Loaded with a new recorder. (i.e., in the jam tab)
            recorder = ChirpRecorder(frame: chirpViewContainer.bounds)
            recorder?.delegate = self
            chirpViewContainer.backgroundColor = UserProfile.shared.profile.backgroundColour.darkerColor
            // disable buttons that cannot be used in this state
            playButton.isEnabled = false
            jamButton.isEnabled = false
            rewindButton.isEnabled = false
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
    
    /// Roboplay Button Pressed, request an AI response and add as a layer.
    @IBAction func roboplayPressed(_ sender: UIButton) {
        // nice shake animation
        //sender.shake()
        let roboResponseEndpoint: String = "http://138.197.179.234:5000/api/predict"
//        let roboResponseEndpoint: String = "http://0.0.0.0:5000/api/predict"
        guard let perfToRespond = self.recorder?.recordingView.saveRecording()?.csv() else {
            print("No perf to respond to.")
            return
        }
//        let perfToRespond = "time,x,y,z,moving\n0.002468, 0.106414, 0.122449, 20.000000, 0\n0.020841, 0.106414, 0.125364, 20.000000, 1\n0.043218, 0.107872, 0.137026, 20.000000, 1\n0.065484, 0.107872, 0.176385, 20.000000, 1\n0.090776, 0.107872, 0.231778, 20.000000, 1\n0.110590, 0.109329, 0.301749, 20.000000, 1\n0.133338, 0.115160, 0.357143, 20.000000, 1\n0.155677, 0.125364, 0.412536, 20.000000, 1\n0.178238, 0.134111, 0.432945, 20.000000, 1\n0.516467, 0.275510, 0.180758, 20.000000, 0\n0.542726, 0.274052, 0.205539, 20.000000, 1\n0.560772, 0.274052, 0.249271, 20.000000, 1\n0.583259, 0.282799, 0.316327, 20.000000, 1\n0.605750, 0.295918, 0.376093, 20.000000, 1\n0.628259, 0.309038, 0.415452, 20.000000, 1\n0.653835, 0.316327, 0.432945, 20.000000, 1\n0.673523, 0.325073, 0.440233, 20.000000, 1\n1.000294, 0.590379, 0.179300, 20.000000, 0\n1.022137, 0.593294, 0.183673, 20.000000, 1\n1.044706, 0.594752, 0.208455, 20.000000, 1\n1.067020, 0.606414, 0.279883, 20.000000, 1\n1.091137, 0.626822, 0.355685, 20.000000, 1\n1.111968, 0.647230, 0.425656, 20.000000, 1\n1.134535, 0.655977, 0.462099, 20.000000, 1\n1.156987, 0.657434, 0.485423, 20.000000, 1\n1.619212, 0.857143, 0.263848, 20.000000, 0\n1.642492, 0.854227, 0.281341, 20.000000, 1\n1.663123, 0.851312, 0.320700, 20.000000, 1\n1.685776, 0.846939, 0.413994, 20.000000, 1\n1.708192, 0.846939, 0.510204, 20.000000, 1\n1.730717, 0.858601, 0.591837, 20.000000, 1\n1.753953, 0.868805, 0.632653, 20.000000, 1\n1.775862, 0.876093, 0.660350, 20.000000, 1\n4.376275, 0.542274, 0.860058, 20.000000, 0\n4.419554, 0.543732, 0.860058, 20.000000, 1"
        print("found performance: \(perfToRespond)")
        guard let roboResponseURL = URL(string: roboResponseEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        print("have URL: \(roboResponseURL)")
        
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
            // let's just print it to prove we can access it
            print("The response is: " + responsePerfJSON.description)
            guard let responsePerfCSV = responsePerfJSON["response"] as? String else {
                print("Could not parse JSON")
                return
            }
            print("Response found!")
            //print("The response was: " + responsePerfCSV)
            if let responsePerf = ChirpPerformance(csv: responsePerfCSV, date: Date(), performer: "RoboJam", instrument: RoboJamPerfData.instrument, image: UIImage(), location: RoboJamPerfData.fakeLocation, colour: RoboJamPerfData.color, background: RoboJamPerfData.bg, replyto: "", performanceID: RoboJamPerfData.id, creatorID: RoboJamPerfData.creator) {
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
    
    // Add an extra jam from the RoboJam servers
    func addRoboJam(_ performance: ChirpPerformance) {
        if let recorder = recorder {
            let chirp = ChirpView(with: chirpViewContainer.bounds, andPerformance: performance)
            recorder.chirpViews.append(chirp)
            chirpViewContainer.addSubview(chirp)
        }
    }
}

/// Shake animation for a UIButton
extension UIButton {
    /// Shakes the button a little bit.
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-10.0, 10.0, -5.0, 5.0, -2.5, 2.5, -1, 1, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}
