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
    
    init(frame: CGRect) {
        recordingView = ChirpRecordingView(frame: frame)
        super.init()
    }
    
    convenience init(frame: CGRect, player: ChirpPlayer) {
        self.init(frame: frame)
        chirpViews = player.chirpViews
    }
    
    /// Starts a new recording if recordingEnabled, time is controlled by the superclass's progressTimer.
    func record() -> Bool {
        if recordingEnabled {
            if !isRecording {
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
            if recordingView.saveRecording() != nil {
                recordingIsDone = true
                recordingEnabled = false
            }
        }
        if recordingIsDone, let performance = recordingView.performance {
            recordingView.image = performance.image
        }
    }
}
