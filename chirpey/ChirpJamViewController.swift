//
//  ViewController.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit

class ChirpJamViewController: UIViewController, PdReceiverDelegate {
    let SOUND_OUTPUT_CHANNELS = 2
    let SAMPLE_RATE = 44100
    let TICKS_PER_BUFFER = 4
    let PATCH_NAME = "chirp.pd"
    
    var audioController : PdAudioController?
    var openFile : PdFile?
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
        self.startAudioEngine()
        self.recordingProgress!.progress = 0.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Pd Engine Functions
    func startAudioEngine() {
        NSLog("JAMVC: Starting Audio Engine");
        self.audioController = PdAudioController()
        self.audioController?.configurePlayback(withSampleRate: Int32(SAMPLE_RATE), numberChannels: Int32(SOUND_OUTPUT_CHANNELS), inputEnabled: false, mixingEnabled: true)
        self.audioController?.configureTicksPerBuffer(Int32(TICKS_PER_BUFFER))
        //    [self openPdPatch];
        PdBase.setDelegate(self)
        PdBase.subscribe("toGUI")
        PdBase.openFile(PATCH_NAME, path: Bundle.main.bundlePath)
        self.audioController?.isActive = true
        //[self.audioController setActive:YES];
        self.audioController?.print()
        NSLog("JAMVC: Ticks Per Buffer: %d",self.audioController?.ticksPerBuffer ?? "didn't work!");
    }
    
    /// Receives print messages from Pd for debugging
    func receivePrint(_ message: String!) {
        NSLog("Pd: %@", message)
    }

    // MARK: - Recording Functions
    func startRecording() {
        if (!self.chirpeySquare!.recording) {
            NSLog("JAMVC: Starting a recording.")
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.incrementRecordingProgress)
            self.chirpeySquare?.recording = true
        }
    }
    
    func stopTimer() {
        self.progressTimer?.invalidate()
        self.progress = 0.0
        self.recordingProgress?.progress = 0.0
        NSLog("JAMVC: Recording time finished, stopping recording. Now loading the recorded performance.")
        let lastPerformance = self.chirpeySquare!.reset()
        (UIApplication.shared.delegate as! AppDelegate).recordedPerformances.append(lastPerformance)
        (UIApplication.shared.delegate as! AppDelegate).savePerformances()
        self.load(performance: lastPerformance)
        //self.writeCSVToFile(csvString: lastPerformance.csv())
    }
    
    func incrementRecordingProgress(_ : Timer) {
        self.progress += 0.01;
        self.recordingProgress?.progress = Float(self.progress / 5.0)
        if (self.progress >= 5.0) {self.stopTimer()}
    }
    
    // MARK: - Touch methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        let p = touches.first?.location(in: self.chirpeySquare);
        if (self.chirpeySquare!.bounds.contains(p!) && !self.chirpeySquare!.recording) {
                self.startRecording()
        }
    }

    // MARK: - Loading Performances
    /// Load a ChirpPerformance for playback and reaction
    func load(performance: ChirpPerformance) {
        self.loadedPerformance = performance
        self.updateUI()
    }
    
    /// Update the UI Labels to reflect the loaded performance.
    func updateUI() {
        if (self.loadedPerformance != nil) {
            self.statusLabel.text = "Loaded: " + (self.loadedPerformance?.dateString())!
            self.performerLabel.text = "By: " + (self.loadedPerformance?.performer)!
            self.instrumentLabel.text = "With: " + (self.loadedPerformance?.instrument)!
            self.chirpeySquare.image = self.loadedPerformance?.image
        }
    }
}
