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
    /// Stores the currently open Pd file
    var openPatch : PdFile?
    /// Stores the $0 (id) value of the currently open Pd patch.
    var openPatchDollarZero : Int32?
    /// Stores the name of the currently open Pd patch.
    var openPatchName = ""
    
    // MARK: Initialisers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isMultipleTouchEnabled = true
        startNewPerformance()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        performance = ChirpPerformance()
        recordingColour = self.performance?.colour.cgColor
        image = UIImage()
    }
    
    /// Convenience Initialiser only used when loading performances for playback only. Touch is disabled!
    convenience init(frame: CGRect, performance: ChirpPerformance){
        self.init(frame: frame)
        print("ChirpView: Loading programmatically with frame: ", self.frame)
        isMultipleTouchEnabled = false // multitouch is disabled!
        isUserInteractionEnabled = false // user-interaction is disabled!
        loadPerformance(performance: performance)
        contentMode = .scaleToFill
    }
    
    // MARK: Lifecycle
    
    /// Initialise the ChirpView for a new performance
    func startNewPerformance() {
        print("ChirpView: New Performance")
        recording = false
        playing = false
        started = false
        lastPoint = CG_INIT_POINT
        swiped = false
        image = UIImage()
        performance = ChirpPerformance()
        recordingColour = performance?.colour.cgColor ?? defaultRecordingColour
        reloadPatch()
    }
    
    /// Initialise the ChirpView with a loaded performance
    func loadPerformance(performance: ChirpPerformance) {
        print("ChirpView: Loading existing performance")
        recording = false
        playing = false
        started = false
        lastPoint = CG_INIT_POINT
        swiped = false
        image = performance.image
        recordingColour = performance.colour.cgColor
        playbackColour = performance.colour.cgColor
        self.performance = performance
        reloadPatch()
    }
    
    /// Closes the recording and returns the performance.
    func closeRecording() -> ChirpPerformance? {
        recording = false
        if let output = self.performance,
            let image = self.image {
            output.image = image
            output.performer = UserProfile.shared.profile.stageName
            output.instrument = SoundSchemes.namesForKeys[UserProfile.shared.profile.soundScheme]!
            output.date = Date()
            return output
        }
        return nil
    }
    
    /// Resets the ChirpView for a new performance and returns the last performance.
    func reset() -> ChirpPerformance {
        print("ChirpView: Reset Called")
        self.performance?.image = self.image!
        self.performance?.date = Date() // stores the date when saved, not started.
        let output = self.performance
        self.startNewPerformance() // resets the view for a new performance.
        return output!
    }
    

    //MARK: - touch interaction
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
        if (!started) {
            startTime = Date()
            started = true
        }
        swiped = false
        lastPoint = touches.first?.location(in: superview!)
        let size = touches.first?.majorRadius
        drawDot(at: lastPoint!, withColour: recordingColour ?? defaultRecordingColour)
        makeSound(at: lastPoint!, withRadius: size!, thatWasMoving: false)
        recordTouch(at: lastPoint!, withRadius: size!, thatWasMoving:false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if recording {
            swiped = true
            let currentPoint = touches.first?.location(in: superview!)
            drawLine(from:self.lastPoint!, to:currentPoint!, withColour:recordingColour ?? defaultRecordingColour)
            lastPoint = currentPoint
            let size = touches.first?.majorRadius
            makeSound(at: currentPoint!, withRadius: size!, thatWasMoving: true)
            recordTouch(at: currentPoint!, withRadius: size!, thatWasMoving: true)
        }
    }
    
    /// Given a point in the UIImage, sends a touch point to Pd to process for sound.
    func makeSound(at point : CGPoint, withRadius radius : CGFloat, thatWasMoving moving: Bool) {
        let x = Double(point.x) / Double(frame.size.width)
        let y = Double(point.y) / Double(frame.size.width)
        let z = Double(radius)
        let m = moving ? 0.0 : 1.0
        let receiver : String = "\(openPatchDollarZero ?? Int32(0))" + PdConstants.receiverPostFix
        //let list = ["/x",x,"/y",y,"/z",z] as [Any]
        // FIXME: figure out how to get Pd to parse the list sequentially.
        PdBase.sendList(["/m",m], toReceiver: receiver)
        PdBase.sendList(["/z",z], toReceiver: receiver)
        PdBase.sendList(["/y",y], toReceiver: receiver)
        PdBase.sendList(["/x",x], toReceiver: receiver)
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
    
    // MARK: - drawing functions

    /// Draws a dot at a given point in the UIImage.
    func drawDot(at point : CGPoint, withColour color : CGColor) {
        UIGraphicsBeginImageContext(frame.size);
        let context = UIGraphicsGetCurrentContext();
        image?.draw(in: CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height))
        context!.setFillColor(color);
        context!.setBlendMode(CGBlendMode.normal)
        context!.fillEllipse(in: CGRect(x:point.x - 5, y:point.y - 5, width:10, height:10));
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    /// Draws a line between two points in the UIImage.
    func drawLine(from fromPoint : CGPoint, to toPoint : CGPoint, withColour color : CGColor) {
        UIGraphicsBeginImageContext(frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        image?.draw(in: CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height))
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        context.setLineCap(CGLineCap.round)
        context.setLineWidth(10.0)
        context.setStrokeColor(color)
        context.setBlendMode(CGBlendMode.normal)
        context.strokePath()
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    // MARK: - playback functions
    /**
     Mirrors touchesBegan for replayed performances.
    **/
    func playbackBegan(_ point : CGPoint, _ radius : CGFloat) {
        swiped = false
        lastPoint = point
        drawDot(at: point, withColour: playbackColour ?? defaultPlaybackColour)
        makeSound(at: point, withRadius: radius, thatWasMoving: false)
    }
    /**
     Mirrors touchesMoved for replayed performances.
    **/
    func playbackMoved(_ point : CGPoint, _ radius : CGFloat) {
        swiped = true
        if let lastPoint = self.lastPoint {
            drawLine(from: lastPoint, to: point, withColour: playbackColour ?? defaultPlaybackColour)
        }
        lastPoint = point
        makeSound(at: point, withRadius: radius, thatWasMoving: true)
    }
    
    /// Returns function for playing a `TouchRecord` at a certain time. Used for playing back touches.
    func makeTouchPlayerWith(touch: TouchRecord) -> ((Timer) -> Void) {
        let z = CGFloat(touch.z)
        let point = CGPoint(x: Double(frame.size.width) * touch.x, y: Double(frame.size.width) * touch.y)
        let playbackFunction : (CGPoint, CGFloat) -> Void = touch.moving ? playbackMoved : playbackBegan
        func playbackTouch(withTimer timer: Timer) {
            playbackFunction(point, z)
        }
        return playbackTouch
    }
    
    // MARK: - Pd Patch Managing Functions.
    
    /// Loads the Pd Patch for this ChirpView. If patch name is not set in the ChirpPerformance, the user settings are used.
    func reloadPatch() {
        // Opening the Pd File.
        if let performancePatchName = performance?.instrument, performancePatchName != "" {
            print("ChirpView: Loading a patch from performance: ", performancePatchName)
            openPdFile(withName: performancePatchName)
        } else {
            print("ChirpView: Loading the settings specified patch (i.e., new performance)")
            openPdFile()
        }
        // print("ChirpView: DollarZero is: ", self.openPatchDollarZero ?? "not available!")
    }
    
    /// Opens a Pd patch according the UserProfile, does nothing if the patch is already open.
    func openPdFile() {
        let userChoiceKey = UserProfile.shared.profile.soundScheme
        if let userChoiceFile = SoundSchemes.pdFilesForKeys[userChoiceKey] {
            openPd(file: userChoiceFile)
        }
    }
    
    /**
     Attempts to open a patch with a given name. Does nothing if the patch is already open.
     */
    func openPdFile(withName name: String) {
        print("ChirpView: Attemping to open the Pd File with name:", name)
        if let index = SoundSchemes.namesForKeys.values.index(of: name) {
            let fileToOpen = SoundSchemes.pdFilesForKeys[SoundSchemes.namesForKeys.keys[index]]! as String
            openPd(file: fileToOpen)
        }
    }
    
    func openPd(file fileToOpen: String) {
        if openPatchName != fileToOpen {
            print("ChirpView: Opening Pd File:", fileToOpen)
            openPatch?.close()
            openPatch = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
            openPatchName = fileToOpen
            openPatchDollarZero = openPatch?.dollarZero
        } else {
            print("ChirpView:", fileToOpen, "was already open.")
        }
    }
    
}
