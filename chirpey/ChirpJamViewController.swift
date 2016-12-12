//
//  ViewController.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit

/// Modes for the ChirpJameViewController: either new, recording, loaded, or playing.
struct ChirpJamModes {
    static let new = 0
    static let recording = 1
    static let loaded = 2
    static let playing = 3
}

class ChirpJamViewController: UIViewController {
    let RECORDING_TIME = 5.0
    var state = ChirpJamModes.new
    var progress = 0.0
    var progressTimer : Timer?
    var loadedPerformance : ChirpPerformance?

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var jamButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var performerLabel: UILabel!
    @IBOutlet weak var instrumentLabel: UILabel!
    @IBOutlet weak var chirpeySquare: ChirpView!
    @IBOutlet weak var recordingProgress: UIProgressView!
    @IBOutlet weak var savePerformanceButton: UIBarButtonItem!
    
    /// MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("JAMVC: Preparing for Segue")
        // FIXME: save the performance if the timer hasn't run out.
        // stopRecording()
        if state == ChirpJamModes.recording {stopRecording() }
        if state == ChirpJamModes.playing { stopPlayback() } // stop any possible playback.
        if let barButton = sender as? UIBarButtonItem {
            if savePerformanceButton === barButton {
                print("JAMVC: Save button segue!")
            } else {
                print("JAMVC: Not jam button segue!")
                self.loadedPerformance = nil
            }
        }
    }
    
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        let isPresentingInAddPerformanceMode = presentingViewController is UINavigationController
        //stopRecording()
        // FIXME: need to stop recording/playback based on the current control state
        stopPlayback() // stop any possible playback timers
        self.loadedPerformance = nil
        if isPresentingInAddPerformanceMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func unwindToJamView(sender: UIStoryboardSegue) {
        if sender.source is SettingsTableViewController {
            // Unwinding from settings screen.
            print("JAMVC: unwinding from a settings screen.")
            print("JAMVC: state",self.state)
            if (self.state == ChirpJamModes.new) {
                print("JAMVC: unwinding to new state so updating the Pd file.")
                self.updateUI()
                (UIApplication.shared.delegate as! AppDelegate).openPdFile()
            }
        }
    }
    
    var playbackTimers : [Timer]?
    
    /// MARK: - UI Interaction Functions
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if let loadedPerformance = loadedPerformance {
            if (!self.chirpeySquare!.playing) {
                print("JAMVC: Going to start playing")
                // Start Playback
                self.playbackTimers = loadedPerformance.playback(inView: self.chirpeySquare)
                statusLabel.text = "Playing..."
                startProgressBar()
                chirpeySquare?.playing = true
                self.playButton.titleLabel?.text = "Stop"
            } else {
                // Cancel Playback
                print("JAMVC: Going to stop playing")
                self.stopTimer()
                self.playButton.titleLabel?.text = "Play"
            }
        } else {
            print("JAMVC: No loaded performance to be played back.")
        }
    }
    
    @IBAction func recButtonPressed(_ sender: UIButton) {
        self.startRecording()
    }
    
    @IBAction func jamButtonPressed(_ sender: UIButton) {
        /// TODO: implement some kind of generative performing here!
        self.statusLabel.text = "Doesn't work yet!"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("JAMVC: view loaded")
        self.recordingProgress!.progress = 0.0
        self.updateUI()
        if (state == ChirpJamModes.loaded) {
            print("JAMVC: opening Pd file for loaded performance.")
            (UIApplication.shared.delegate as! AppDelegate).openPdFile(withName: (loadedPerformance?.instrument)!)
        }
    }
    
    /// Load a ChirpPerformance for playback and reaction
    func load(performance: ChirpPerformance) {
        self.loadedPerformance = performance
        self.state = ChirpJamModes.loaded
        (UIApplication.shared.delegate as! AppDelegate).openPdFile(withName: performance.instrument)
        self.updateUI()
    }
    
    /// Update the UI labels and image only if there is a valid performance loaded.
    func updateUI() {
        print("JAMVC: Updating UI.")
//        print("Settings Data: ")
//        print("Performer: ", UserDefaults.standard.string(forKey: SettingsKeys.performerKey) ?? "name could not be loaded")
//        print("Instrument:", SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)] ?? "name could not be loaded")
        
        switch self.state {
        case ChirpJamModes.new:
            self.navigationItem.title = "New Performance"
            self.statusLabel.text = "new"
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentLabel.text = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]
        case ChirpJamModes.recording:
            self.navigationItem.title = "recording..."
            self.statusLabel.text = "recording..."
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentLabel.text = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]
        case ChirpJamModes.playing:
            if let loadedPerformance = loadedPerformance {
                self.navigationItem.title = loadedPerformance.dateString()
                self.statusLabel.text = "Playing..."
                self.performerLabel.text = "By: " + (loadedPerformance.performer)
                self.instrumentLabel.text = "With: " + (loadedPerformance.instrument)
                self.chirpeySquare.image = loadedPerformance.image
            }
        case ChirpJamModes.loaded:
            if let loadedPerformance = loadedPerformance {
                self.navigationItem.title = loadedPerformance.dateString()
                self.statusLabel.text = "Loaded: " + (loadedPerformance.dateString())
                self.performerLabel.text = "By: " + (loadedPerformance.performer)
                self.instrumentLabel.text = "With: " + (loadedPerformance.instrument)
                self.chirpeySquare.image = loadedPerformance.image
            }
        default:
            self.navigationItem.title = "performance"
            self.statusLabel.text = "new"
            self.performerLabel.text = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)
            self.instrumentLabel.text = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Recording Functions
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        if (self.state == ChirpJamModes.new) {
            NSLog("JAMVC: Starting a recording.")
            self.startProgressBar()
            self.chirpeySquare?.recording = true
            self.state = ChirpJamModes.recording
            self.updateUI()
        }
    }
    
    func startProgressBar() {
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
    }
    
    /// Automatically triggered when recording time finishes.
    func stopTimer() {
        NSLog("JAMVC: Timer finished.")
        if (self.chirpeySquare!.recording) {
            self.stopRecording()
            self.chirpeySquare!.recording = false
        } else {
            self.stopPlayback()
            self.chirpeySquare!.playing = false
        }
        self.progressTimer?.invalidate()
        self.progress = 0.0
        self.recordingProgress?.progress = 0.0
    }
    
    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping Recording and loading the recorded performance.")
        if let lastPerformance = self.chirpeySquare!.closeRecording() {
            self.load(performance: lastPerformance)
            self.state = ChirpJamModes.loaded
        }
        self.updateUI()
    }
    
    // StopPlayback
    func stopPlayback() {
        print("JAMVC: Stopping any requested playback")
        if playbackTimers != nil {
            print("JAMVC: Stopping the timers")
            self.chirpeySquare.performance?.cancelPlayback(timers: playbackTimers!)
        }
        self.playButton.titleLabel?.text = "Play"
        self.state = ChirpJamModes.loaded
        self.updateUI()
    }
    
    func incrementRecordingProgress(_ : Timer) {
        self.progress += 0.01;
        self.recordingProgress?.progress = Float(self.progress / self.RECORDING_TIME)
        if (self.progress >= self.RECORDING_TIME) {self.stopTimer()}
    }
    
    // MARK: - Touch methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        let p = touches.first?.location(in: self.chirpeySquare);
        if (self.chirpeySquare!.bounds.contains(p!) && self.state == ChirpJamModes.new) {
                self.startRecording()
        }
    }


}
