//
//  ChirpView.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

/// View class for short touch-interaction musical performances.
class ChirpView: UIImageView {
    var lastPoint : CGPoint?
    var recording = false
    var playing = false
    var swiped = false
    var started = false
    var startTime = Date()
    var performance : ChirpPerformance?
    let recordingColour : CGColor = UIColor.red.cgColor
    let playbackColour : CGColor = UIColor.green.cgColor
    let CG_INIT_POINT = CGPoint(x:0,y:0)
    let imageSize : Double = 300.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isMultipleTouchEnabled = true
        self.startNewPerformance()
    }
    
    /// Closes the recording and returns the performance.
    func closeRecording() -> ChirpPerformance? {
        self.recording = false
        if let output = self.performance {
            output.image = self.image!
            output.performer = UserDefaults.standard.string(forKey: SettingsKeys.performerKey)!
            output.instrument = ScoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]!
            output.date = Date()
            return output
        }
        return nil
    }
    
    /// Resets the ChirpView for a new performance and returns the last performance.
    func reset() -> ChirpPerformance {
        self.performance?.image = self.image!
        // FIXME: overwrites the date each time a chirpview is reset.
        self.performance?.date = Date()
        let output = self.performance
        self.startNewPerformance()
        return output!
    }
    
    // Initialise the ChirpView for a new performance
    func startNewPerformance() {
        self.recording = false
        self.playing = false
        self.started = false
        self.lastPoint = CG_INIT_POINT
        self.swiped = false
        self.image = UIImage()
        self.performance = ChirpPerformance()
    }
    
    //MARK: - touch interaction
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.superview?.touchesBegan(touches, with: event)
        if (!self.started) {
            self.startTime = Date()
            self.started = true
        }
        self.swiped = false
        self.lastPoint = touches.first?.location(in: self)
        self.drawDot(at: self.lastPoint!, withColour: self.recordingColour)
        self.makeSound(at: self.lastPoint!)
        self.recordTouch(at: self.lastPoint!, thatWasMoving:false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.swiped = true
        let currentPoint = touches.first?.location(in:self)
        self.drawLine(from:self.lastPoint!, to:currentPoint!, withColour:self.recordingColour)
        self.lastPoint = currentPoint;
        self.makeSound(at: currentPoint!)
        self.recordTouch(at: currentPoint!, thatWasMoving: true)
    }
    
    /// Given a point in the UIImage, sends a touch point to Pd to process for sound.
    func makeSound(at point : CGPoint) {
        let x = Double(point.x) / self.imageSize
        let y = Double(point.y) / self.imageSize
        let z = 0.0
        PdBase.sendList(["/x",x,"/y",y,"/z",z], toReceiver: "input")
    }
    
    /**
        Adds a touch point to the recording data including whether it was moving
        and the current time.
     **/
    func recordTouch(at point : CGPoint, thatWasMoving moving : Bool) {
        let time = -1.0 * self.startTime.timeIntervalSinceNow
        let x = Double(point.x) / self.imageSize
        let y = Double(point.y) / self.imageSize
        let z : Double = 0.0
        self.performance?.recordTouchAt(time: time, x: x, y: y, z: z, moving: moving)
    }
    
    // MARK: - drawing functions

    /// Draws a dot at a given point in the UIImage.
    func drawDot(at point : CGPoint, withColour color : CGColor) {
        UIGraphicsBeginImageContext(self.frame.size);
        let context = UIGraphicsGetCurrentContext();
        self.image?.draw(in: CGRect(x:0, y:0, width:self.frame.size.width, height:self.frame.size.height))
        context!.setFillColor(color);
        context!.setBlendMode(CGBlendMode.normal)
        context!.fillEllipse(in: CGRect(x:point.x - 5, y:point.y - 5, width:10, height:10));
        self.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    /// Draws a line between two points in the UIImage.
    func drawLine(from fromPoint : CGPoint, to toPoint : CGPoint, withColour color : CGColor) {
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        self.image?.draw(in: CGRect(x:0, y:0, width:self.frame.size.width, height:self.frame.size.height))
        context!.move(to: fromPoint)
        context!.addLine(to: toPoint)
        context!.setLineCap(CGLineCap.round)
        context!.setLineWidth(10.0)
        context!.setStrokeColor(color)
        context!.setBlendMode(CGBlendMode.normal)
        context!.strokePath()
        self.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    // MARK: - playback functions
    /**
     Mirrors touchesBegan for replayed performances.
    **/
    func playbackBegan(_ point : CGPoint) {
        self.swiped = false;
        self.lastPoint = point;
        self.drawDot(at: point, withColour: self.playbackColour)
        self.makeSound(at: point)
    }
    /**
     Mirrors touchesMoved for replayed performances.
    **/
    func playbackMoved(_ point : CGPoint) {
        self.swiped = true;
        self.drawLine(from: self.lastPoint!, to: point, withColour: self.playbackColour)
        self.lastPoint = point;
        self.makeSound(at: point)
    }
    
    /// Returns function for playing a `TouchRecord` at a certain time. Used for playing back touches.
    func makeTouchPlayerWith(touch: TouchRecord) -> ((Timer) -> Void) {
        let z = touch.z
        let point = CGPoint(x: self.imageSize * touch.x, y: self.imageSize * touch.y)
        let playbackFunction : (CGPoint) -> Void = touch.moving ? self.playbackMoved : self.playbackBegan
        func playbackTouch(withTimer timer: Timer) {
            playbackFunction(point)
        }
        return playbackTouch
    }
    
}
