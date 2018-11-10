//
//  ChirpRecordingView.swift
//  microjam
//
//  Created by Charles Martin on 11/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Storage for a single tail segment which consists of a touch location and a timer for removing it.
struct TailSegment {
    var touch: TouchRecord
    var timer: Timer
}

/// Subclass of ChirpView that enables recording and user interaction
class ChirpRecordingView: ChirpView {
    
    // Recording
    /// Storage for the date that a performance started recording for timing
    var startTime = Date()
    /// True if the view has started a recording (so touches should be recorded)
    var recording = false
    /// Colour to render touches as they are recorded.
    var recordingColour : CGColor?
    /// Animated tail segments for practice mode.
    var tailSegments = [TailSegment]()

    /// Programmatic init getting ready for recording.
    override init(frame: CGRect) {
        super.init(frame: frame)
        resetAnimationLayer()
        print("ChirpRecordingView: Loading programmatically with frame: ", self.frame)
        isMultipleTouchEnabled = true
        isUserInteractionEnabled = true
        clearForRecording() // gets view ready for recording.
    }
    
    /// Initialises view for recording, rather than playback.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        resetAnimationLayer()
        isMultipleTouchEnabled = true
        isUserInteractionEnabled = true
        clearForRecording() // gets view ready for recording.
    }
}

//MARK: - touch interaction

/// Contains touch interaction and recording functions for ChirpView
extension ChirpRecordingView {
    
    /// Responds to taps in the ChirpView, passes on to superviews and reacts.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
        lastPoint = touches.first?.location(in: superview!)
        let size = touches.first?.majorRadius
        
        if recording {
            // draw and record touch if recording
            if (!started) {
                startTime = Date()
                started = true
            }
            swiped = false
            drawDot(at: lastPoint!, withColour: recordingColour ?? DEFAULT_RECORDING_COLOUR)
            recordTouch(at: lastPoint!, withRadius: size!, thatWasMoving:false)
        } else {
            // not recording, add disappearing touches.
            addTailSegment(at: lastPoint!, withSize: size!, thatWasMoving: false)
            draw(tailSegments: tailSegments, withColor: recordingColour!)
        }
        // always make a sound.
        makeSound(at: lastPoint!, withRadius: size!, thatWasMoving: false)
    }

    /// Clips a CGPoint to the bounds of the ChirpRecordingView.
    func clipTouchLocationToBounds(_ point: CGPoint) -> CGPoint {
        let x = max(min(point.x, bounds.width), 0)
        let y = max(min(point.y, bounds.height), 0)
        return CGPoint.init(x: x, y: y)
    }
    
    /// Responds to moving touch signals, responds with sound and recordings.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesMoved(touches, with: event)
        let currentPoint = clipTouchLocationToBounds((touches.first?.location(in: superview!))!)
        let size = touches.first?.majorRadius

        if recording {
            // draw and record touch if recording
            swiped = true
            drawLine(from:self.lastPoint!, to:currentPoint, withColour:recordingColour ?? DEFAULT_RECORDING_COLOUR)
            lastPoint = currentPoint
            recordTouch(at: currentPoint, withRadius: size!, thatWasMoving: true)
        } else {
            // not recording, add disappearing touches.
            addTailSegment(at: currentPoint, withSize: size!, thatWasMoving: true)
            draw(tailSegments: tailSegments, withColor: recordingColour!)
            lastPoint = currentPoint
        }
        
        // Always make a sound.
        makeSound(at: currentPoint, withRadius: size!, thatWasMoving: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // touchesEnded in case needed.
        superview?.touchesEnded(touches, with: event)
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
        output.image = moveAnimationLayerToImage()
        output.performer = UserProfile.shared.profile.stageName
        output.instrument = SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme]!
        output.date = Date()
        return output
    }
    
    /// Initialise the ChirpView for a new recording
    func clearForRecording() {
        print("ChirpRecordingView: Clearing for a New Performance")
        recording = false
        started = false
        lastPoint = CG_INIT_POINT
        swiped = false
        image = UIImage()
        performance = ChirpPerformance()
        recordingColour = performance?.colour.cgColor ?? DEFAULT_RECORDING_COLOUR
        playbackColour = performance?.colour.brighterColor.cgColor ?? DEFAULT_PLAYBACK_COLOUR
        openUserSoundScheme()
    }
}

// MARK: Tail segment drawing functions

extension ChirpRecordingView {
    
    /// Add animated tail segment that removes itself after a certain time.
    private func addTailSegment(at point: CGPoint, withSize size: CGFloat, thatWasMoving moving: Bool) {
        let touch = TouchRecord(time: 0, x: Double(point.x), y: Double(point.y), z: Double(size), moving: moving)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (timer) in
            if !self.tailSegments.isEmpty {
                self.tailSegments.removeFirst()
                self.draw(tailSegments: self.tailSegments, withColor: self.recordingColour!)
            }
        }
        let tailSegment = TailSegment(touch: touch, timer: timer)
        tailSegments.append(tailSegment)
    }
    
    /// Draws all present tail segments. If there is a recorded image it should draw them on top of that, if not draw from nothing.
    func draw(tailSegments: [TailSegment], withColor color: CGColor) {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, (UIScreen.main).scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Get the present recorded image.
        if let presentPerf = performance,
            let image = presentPerf.image {
            image.draw(in: CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height))
        }

        // Now draw all the tail segments.
        context.setFillColor(color)
        context.setStrokeColor(color)
        context.setBlendMode(CGBlendMode.normal)
        context.setLineCap(CGLineCap.round)
        context.setLineWidth(10.0)
        context.beginPath()
        
        for (i, current) in tailSegments.enumerated() {
            if i == 0 || !current.touch.moving {
                context.move(to: CGPoint(x: current.touch.x, y: current.touch.y))
            }
            context.addLine(to: CGPoint(x: current.touch.x, y: current.touch.y))
        }
        
        context.strokePath()
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
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

// MARK : Gesture Recognition

extension ChirpRecordingView {
    /// Don't return gesture recognizer signals if the view is in an interactive state.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
