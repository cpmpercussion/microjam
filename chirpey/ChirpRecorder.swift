//
//  Recorder.swift
//  microjam
//
//  Created by Henrik Brustad on 21/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// A ChirpPlayerController with the ability to record a new ChirpPerformance
class ChirpRecorder: ChirpPlayer {
    /// The ChirpRecorder's ChirpRecordingView
    var recordingView: ChirpRecordingView
    /// Storage for whether the recorder is enabled or not, controls whether touches are stored and playback starts on touch.
    var recordingEnabled = false
    /// Storage of the present playback/recording state: playing, recording or idle
    var isRecording = false
    /// Tells us whether the recording has been added to the stack in the performance handler
    var recordingIsDone = false
    /// Description of the ChirpPlayer with it's first ChirpPerformance.
    override var description: String {
        guard let perfString = chirpViews.first?.performance?.description else {
            return "ChirpRecorder-NoPerformance"
        }
        return "ChirpRecorder-" + perfString
    }
    
    init(frame: CGRect) {
        recordingView = ChirpRecordingView(frame: frame)
        recordingView.clipsToBounds = true
        recordingView.contentMode = .scaleAspectFill
        super.init()
    }
    
    /// Convenience initialiser for creating a ChirpRecorder with the same performances as a given ChirpPlayer
    convenience init(frame: CGRect, player: ChirpPlayer) {
        self.init(frame: frame)
        chirpViews = player.chirpViews
    }
    
    /// Convenience initialiser for creating a ChirpRecorder with an array of backing ChirpPerformances
    convenience init(withArrayOfPerformances performanceArray: [ChirpPerformance]) {
        let dummyFrame = CGRect.zero
        self.init(frame: dummyFrame)
        for perf in performanceArray {
            let chirp = ChirpView(with: dummyFrame, andPerformance: perf)
            chirpViews.append(chirp)
        }
    }
    
    /// Starts a new recording if recordingEnabled, time is controlled by the superclass's progressTimer.
    func record() -> Bool {
        if recordingEnabled {
            if !isRecording {
                print("ChirpRecorder: Starting recording")
                isRecording = true
                recordingView.recording = true
                // Starting progresstimer and playback of performances if any
                play()
                return true
            }
        }
        return false
    }
    
    /// Override the superclass's play function to only playback once a recording is finished.
    override func play() {
        super.play()
        if recordingIsDone {
            play(chirp: recordingView)
        }
    }
    
    /// Override superclass's stop function to control recording state.
    override func stop() {
        super.stop()
        if isRecording {
            isRecording = false
            if self.recordingView.saveRecording() != nil {
                self.recordingIsDone = true
                self.recordingEnabled = false
            }
        }
        if recordingIsDone, let performance = recordingView.performance {
            // print("ChirpRecorder: Adding performance image as my display image: \(performance.title())")
            self.recordingView.setImage() // clear the animation layer and reset the saved image
        }
    }
}
