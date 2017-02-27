//
//  ChirpView.swift
//  microjam
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
    let defaultRecordingColour : CGColor = UIColor.red.cgColor
    var recordingColour : CGColor?
    let defaultPlaybackColour : CGColor = UIColor.green.cgColor
    var playbackColour : CGColor?
    let CG_INIT_POINT = CGPoint(x:0,y:0)
    let imageSize : Double = 300.0
    // Pd File Vars
    var openPatch : PdFile?
    var openPatchDollarZero : Int32?
    var openPatchName = ""
    
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
            output.instrument = SoundSchemes.namesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]!
            output.date = Date()
            return output
        }
        return nil
    }
    
    /// Resets the ChirpView for a new performance and returns the last performance.
    func reset() -> ChirpPerformance {
        print("ChirpView: Reset Called")
        self.performance?.image = self.image!
        // FIXME: overwrites the date each time a chirpview is reset.
        self.performance?.date = Date()
        let output = self.performance
        self.startNewPerformance()
        return output!
    }
    
    // Initialise the ChirpView for a new performance
    func startNewPerformance() {
        print("ChirpView: New Performance")
        self.recording = false
        self.playing = false
        self.started = false
        self.lastPoint = CG_INIT_POINT
        self.swiped = false
        self.image = UIImage()
        self.performance = ChirpPerformance()
        self.recordingColour = self.performance?.colour.cgColor ?? defaultRecordingColour
        
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
        let size = touches.first?.majorRadius
        self.drawDot(at: self.lastPoint!, withColour: self.recordingColour ?? self.defaultRecordingColour)
        self.makeSound(at: self.lastPoint!, withRadius: size!)
        self.recordTouch(at: self.lastPoint!, withRadius: size!, thatWasMoving:false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.swiped = true
        let currentPoint = touches.first?.location(in:self)
        self.drawLine(from:self.lastPoint!, to:currentPoint!, withColour:self.recordingColour ?? self.defaultRecordingColour)
        self.lastPoint = currentPoint
        let size = touches.first?.majorRadius
        self.makeSound(at: currentPoint!, withRadius: size!)
        self.recordTouch(at: currentPoint!, withRadius: size!, thatWasMoving: true)
    }
    
    /// Given a point in the UIImage, sends a touch point to Pd to process for sound.
    func makeSound(at point : CGPoint, withRadius radius : CGFloat) {
        let x = Double(point.x) / self.imageSize
        let y = Double(point.y) / self.imageSize
        let z = Double(radius)
        //let list = ["/x",x,"/y",y,"/z",z] as [Any]
        // FIXME: figure out how to get Pd to parse the list sequentially.
        PdBase.sendList(["/x",x], toReceiver: "input")
        PdBase.sendList(["/y",y], toReceiver: "input")
        PdBase.sendList(["/z",z], toReceiver: "input")
        // print("Sent to Pd: ", list)
    }
    
    /**
        Adds a touch point to the recording data including whether it was moving
        and the current time.
     **/
    func recordTouch(at point : CGPoint, withRadius radius : CGFloat, thatWasMoving moving : Bool) {
        let time = -1.0 * self.startTime.timeIntervalSinceNow
        let x = Double(point.x) / self.imageSize
        let y = Double(point.y) / self.imageSize
        let z = Double(radius)
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
    func playbackBegan(_ point : CGPoint, _ radius : CGFloat) {
        self.swiped = false
        self.lastPoint = point
        self.drawDot(at: point, withColour: self.playbackColour ?? self.defaultPlaybackColour)
        self.makeSound(at: point, withRadius: radius)
    }
    /**
     Mirrors touchesMoved for replayed performances.
    **/
    func playbackMoved(_ point : CGPoint, _ radius : CGFloat) {
        self.swiped = true;
        self.drawLine(from: self.lastPoint!, to: point, withColour: self.playbackColour ?? self.defaultPlaybackColour)
        self.lastPoint = point
        self.makeSound(at: point, withRadius: radius)
    }
    
    /// Returns function for playing a `TouchRecord` at a certain time. Used for playing back touches.
    func makeTouchPlayerWith(touch: TouchRecord) -> ((Timer) -> Void) {
        let z = CGFloat(touch.z)
        let point = CGPoint(x: self.imageSize * touch.x, y: self.imageSize * touch.y)
        let playbackFunction : (CGPoint, CGFloat) -> Void = touch.moving ? self.playbackMoved : self.playbackBegan
        func playbackTouch(withTimer timer: Timer) {
            playbackFunction(point, z)
        }
        return playbackTouch
    }
    
    // MARK: - Pd Patch Managing Functions.
    
    /// Loads the Pd Patch for this ChirpView. If patch name is not set in the ChirpPerformance, the user settings are used.
    func reloadPatch() {
        // Opening the Pd File.
        if let performancePatchName = self.performance?.instrument, performancePatchName != "" {
            print("ChirpView: Loading a patch from performance: ", performancePatchName)
            self.openPdFile(withName: performancePatchName)
        } else {
            print("ChirpView: Loading the settings specified patch (i.e., new performance)")
            self.openPdFile()
        }
    }
    
    /// Opens a Pd patch according the UserDefaults, does nothing if the patch is already open.
    func openPdFile() {
        let fileToOpen = SoundSchemes.pdFilesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]! as String
        if openPatchName != fileToOpen {
            self.openPatch?.close()
            print("ChirpView: Opening Pd File:", fileToOpen)
            self.openPatch = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
            self.openPatchDollarZero = self.openPatch?.dollarZero
            openPatchName = fileToOpen
        }
    }
    
    /**
     Attempts to open a patch with a given name. Does nothing if the patch is already open.
     */
    func openPdFile(withName name: String) {
        print("ChirpView: Attemping to open the Pd File with name:", name)
        if let index = SoundSchemes.namesForKeys.values.index(of: name) {
            let fileToOpen = SoundSchemes.pdFilesForKeys[SoundSchemes.namesForKeys.keys[index]]! as String
            if openPatchName != fileToOpen {
                print("ChirpView: Opening Pd File:", fileToOpen)
                self.openPatch?.close()
                self.openPatch = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
                self.openPatchName = fileToOpen
                self.openPatchDollarZero = self.openPatch?.dollarZero
            }
        }
    }
}
