//
//  ChirpView.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

class ChirpView: UIImageView {
    
    var fingerSubLayer : CALayer?
    var lastPoint : CGPoint?
    var recording = false
    var swiped = false
    var started = false
    var startTime = Date()
    var recordData : NSMutableOrderedSet?
    let recordingColour : CGColor = UIColor.red.cgColor
    let playbackColour : CGColor = UIColor.green.cgColor
    let CG_INIT_POINT = CGPoint(x:0,y:0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.fingerSubLayer = CALayer()
        self.layer.addSublayer(self.fingerSubLayer!)
        self.isMultipleTouchEnabled = true
        self.lastPoint = CG_INIT_POINT
        self.swiped = false
        self.recordData = NSMutableOrderedSet()
        self.recording = false
    }
    
    /**/
    func reset() -> NSMutableOrderedSet {
        self.recording = false
        self.started = false
        self.lastPoint = CG_INIT_POINT
        self.swiped = false
        // spool out the recording data
        let output = self.recordData;
        self.recordData = NSMutableOrderedSet()
        self.image = UIImage()
        return output!
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
    
    /**
        Given a point in the UIImage, sends a touch point to Pd to process for sound.
    **/
    func makeSound(at point : CGPoint) {
        let x = point.x / 300.0
        let y = point.y / 300.0
        let z = 0.0
        PdBase.sendList(["/x",x,"/y",y,"/z",z], toReceiver: "input")
    }
    
    /**
        Adds a touch point to the recording data including whether it was moving
        and the current time.
     **/
    func recordTouch(at point : CGPoint, thatWasMoving moving : Bool) {
        let time = -1.0 * self.startTime.timeIntervalSinceNow;
        let x = point.x / 300.0
        let y = point.y / 300.0
        let z = 0.0
        self.recordData?.add(object: [time, x, y, z, moving])
    }
    
    // MARK: - drawing functions
    /**
     Draws a dot at a given point in the UIImage.
    **/
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

    /**
        Draws a line between two points in the UIImage.
    **/
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
    
    
    /**
        Starts playback in the UIImage of a previously recorded performance.
    **/
    func playback(recording record : NSMutableOrderedSet) {
        for touch in record.array as! [NSArray] {
            let time = touch[0] as! Double
            Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(processTimedTouch), userInfo: touch, repeats: false)
        }
    }
    
    /**
     Function passed to Timers instantiated in `playback` to action touches at their scheduled time.
    **/
    func processTimedTouch(withTimer timer : Timer) {
        let touch = timer.userInfo as! NSArray
        let x = 300.0 * (touch[1] as! NSNumber).doubleValue
        let y = 300.0 * (touch[2] as! NSNumber).doubleValue
        //float z = [(NSNumber *) touch[3] floatValue];
        let point = CGPoint(x:x, y:y)
        let moved = touch[4] as! Bool
        if (moved) {
            self.playbackMoved(point)
        } else {
            self.playbackBegan(point)
        }
    }

}