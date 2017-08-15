//
//  ChirpRecordingView.swift
//  microjam
//
//  Created by Charles Martin on 11/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Subclass of ChirpView that enables recording and user interaction
class ChirpRecordingView: ChirpView {
    
    // Recording
    /// Storage for the date that a performance started recording for timing
    var startTime = Date()
    /// True if the view has started a recording (so touches should be recorded)
    var recording = false
    /// Colour to render touches as they are recorded.
    var recordingColour : CGColor?

    /// Programmatic init getting ready for recording.
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        clearForRecording() // gets view ready for recording.
    }
    
    /// Initialises view for recording, rather than playback.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isMultipleTouchEnabled = true
        clearForRecording() // gets view ready for recording.
    }
    
    

}

//MARK: - touch interaction

/// Contains touch interaction and recording functions for ChirpView
extension ChirpRecordingView {
    
    /// Responds to taps in the ChirpView, passes on to superviews and reacts.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
        if (!started) {
            startTime = Date()
            started = true
        }
        swiped = false
        lastPoint = touches.first?.location(in: superview!)
        let size = touches.first?.majorRadius
        drawDot(at: lastPoint!, withColour: recordingColour ?? DEFAULT_RECORDING_COLOUR)
        makeSound(at: lastPoint!, withRadius: size!, thatWasMoving: false)
        recordTouch(at: lastPoint!, withRadius: size!, thatWasMoving:false)
    }
    
    /// Responds to moving touch signals, responds with sound and recordings.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if recording {
            swiped = true
            let currentPoint = touches.first?.location(in: superview!)
            drawLine(from:self.lastPoint!, to:currentPoint!, withColour:recordingColour ?? DEFAULT_RECORDING_COLOUR)
            lastPoint = currentPoint
            let size = touches.first?.majorRadius
            makeSound(at: currentPoint!, withRadius: size!, thatWasMoving: true)
            recordTouch(at: currentPoint!, withRadius: size!, thatWasMoving: true)
        }
    }
    
    /**
     Adds a touch point to the recording data including whether it was moving
     and the current time.
     **/
    func recordTouch(at point : CGPoint, withRadius radius : CGFloat, thatWasMoving moving : Bool) {
        let time = -1.0 * startTime.timeIntervalSinceNow
        let x = Double(point.x) / Double(frame.size.width)
        let y = Double(point.y) / Double(frame.size.width)
        let z = Double(radius)
        if recording { // only record when recording.
            performance?.recordTouchAt(time: time, x: x, y: y, z: z, moving: moving)
        }
    }
    
    /// Closes the recording and returns the performance.
    func saveRecording() -> ChirpPerformance? {
        recording = false
        guard let output = self.performance,
            let image = self.image else {
                return nil
        }
        output.image = image
        output.performer = UserProfile.shared.profile.stageName
        output.instrument = SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme]!
        output.date = Date()
        return output
    }
    
    /// Initialise the ChirpView for a new recording
    func clearForRecording() {
        print("ChirpView: New Performance")
        recording = false
        started = false
        lastPoint = CG_INIT_POINT
        swiped = false
        image = UIImage()
        performance = ChirpPerformance()
        recordingColour = performance?.colour.cgColor ?? DEFAULT_RECORDING_COLOUR
        openUserSoundScheme()
    }
}

// MARK: Pd (Sound) Functions

extension ChirpRecordingView {
    
    /// Opens the SoundScheme specified in the user's profile.
    func openUserSoundScheme() {
        let userChoiceKey = UserProfile.shared.profile.soundScheme
        if let userChoiceFile = SoundSchemes.pdFilesForKeys[userChoiceKey] {
            openPd(file: userChoiceFile)
        }
    }

}
