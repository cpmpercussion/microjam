//
//  Recorder.swift
//  microjam
//
//  Created by Henrik Brustad on 21/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class Recorder: Player {
    
    var recordingView: ChirpRecordingView
    
    var recordingEnabled = true
    /// Storage of the present playback/recording state: playing, recording or idle
    var isRecording = false
    /// Tells us whether the recording has been added to the stack in the performance handler
    var recordingIsDone = false
    
    init(frame: CGRect) {
        recordingView = ChirpRecordingView(frame: frame)
        super.init()
    }
    
    convenience init(frame: CGRect, player: Player) {
        self.init(frame: frame)
        chirpViews = player.chirpViews
    }
    
    func record() {
        if recordingEnabled {
            if !isRecording {
                isRecording = true
                recordingView.recording = true
                
                // Starting progresstimer and playback of performances if any
                play()
            }
        }
    }
    
    override func play() {
        super.play()
        
        if recordingIsDone {
            play(chirp: recordingView)
        }
    }
    
    override func stop() {
        super.stop()
        
        if isRecording {
            isRecording = false
            if recordingView.saveRecording() != nil {
                recordingIsDone = true
                recordingEnabled = false
            }
        }
        
        if recordingIsDone {
            recordingView.image = recordingView.performance!.image
        }
    }
}
