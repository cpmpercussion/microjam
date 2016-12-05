//
//  ViewController.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit

class ChirpJamViewController: UIViewController {
    let RECORDING_TIME = 5.0
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
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if savePerformanceButton === sender {
            
//            (UIApplication.shared.delegate as! AppDelegate).recordedPerformances.append(loadedPerformance)
//            (UIApplication.shared.delegate as! AppDelegate).savePerformances()
        } else {
            self.loadedPerformance = nil
        }
    }
    
    @IBAction func cancelPerformance(_ sender: UIBarButtonItem) {
        print("JAMVC: Cancel Button Pressed.")
        let isPresentingInAddPerformanceMode = presentingViewController is UINavigationController
        if isPresentingInAddPerformanceMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    /// MARK: - UI Interaction Functions
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if (self.loadedPerformance != nil) {
            self.loadedPerformance?.playback(inView: self.chirpeySquare)
            self.statusLabel.text = "Playing back: " + (self.loadedPerformance?.dateString())!
        } else {
            self.statusLabel.text = "No loaded performance to be played back."
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
        self.recordingProgress!.progress = 0.0
        
        if loadedPerformance != nil {
            self.updateUI()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Recording Functions
    /// Sets into recording mode and starts the timer.
    func startRecording() {
        if (!self.chirpeySquare!.recording) {
            NSLog("JAMVC: Starting a recording.")
            self.startProgressBar()
            self.chirpeySquare?.recording = true
        }
    }
    
    
    func startPlayback() {
        if (!self.chirpeySquare!.playing) {
            NSLog("JAMVC: Starting playback.")
            self.startProgressBar()
            self.chirpeySquare?.playing = true
        }
    }
    
    func startProgressBar() {
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
    }
    
    /// Automatically triggered when recording time finishes.
    func stopTimer() {
        NSLog("JAMVC: Timer finished.")
        self.stopRecording()
        self.progressTimer?.invalidate()
        self.progress = 0.0
        self.recordingProgress?.progress = 0.0
    }
    
    /// Stops the current recording.
    func stopRecording() {
        print("JAMVC: Stopping Recording and loading the recorded performance.")
        let lastPerformance = self.chirpeySquare!.reset()
        self.load(performance: lastPerformance)
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
        if (self.chirpeySquare!.bounds.contains(p!) && !self.chirpeySquare!.recording) {
                self.startRecording()
        }
    }

    /// Load a ChirpPerformance for playback and reaction
    func load(performance: ChirpPerformance) {
        self.loadedPerformance = performance
        self.updateUI()
    }
    
    /// Update the UI labels and image only if there is a valid performance loaded.
    func updateUI() {
        if let loadedPerformance = loadedPerformance {
            self.navigationItem.title = loadedPerformance.dateString()
            self.statusLabel.text = "Loaded: " + (loadedPerformance.dateString())
            self.performerLabel.text = "By: " + (loadedPerformance.performer)
            self.instrumentLabel.text = "With: " + (loadedPerformance.instrument)
            self.chirpeySquare.image = loadedPerformance.image
        }
    }
}
