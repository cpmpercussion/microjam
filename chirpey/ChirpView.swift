//
//  ChirpView.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

let CG_INIT_POINT = CGPoint(x:0,y:0)
let DEFAULT_RECORDING_COLOUR : CGColor = UIColor.red.cgColor
let DEFAULT_PLAYBACK_COLOUR : CGColor = UIColor.green.cgColor



/// A View class for displaying and playing back ChirpPerformance objects. Subclass of UIImageView. Extensions add recording (and touch interaction) functionality.
class ChirpView: UIImageView {
    // Performance Data
    /// Storage for a performance to playback or record
    var performance : ChirpPerformance?
    /// Colour for drawing playing touches.
    var playbackColour : CGColor?
    
    // Drawing
    /// Stores the location of the last drawn point for animating strokes.
    var lastPoint : CGPoint?
    
    // Interaction
    /// True if the view is currently playing/recording a moving touch
    var swiped = false
    /// True if a recording/playback has started
    var started = false
    
    // Pure Data
    /// Stores the currently open Pd file
    var openPatch : PdFile?
    /// Stores the $0 (id) value of the currently open Pd patch.
    var openPatchDollarZero : Int32?
    /// Stores the name of the currently open Pd patch.
    var openPatchName = ""
    
    // MARK: Initialisers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// Convenience Initialiser only used when loading performances for playback only. Touch is disabled!
    convenience init(with frame: CGRect, andPerformance perf: ChirpPerformance){
        self.init(frame: frame)
        print("ChirpView: Loading programmatically with frame: ", self.frame)
        isMultipleTouchEnabled = false // multitouch is disabled!
        isUserInteractionEnabled = false // user-interaction is disabled!
        loadPerformance(perf)
        contentMode = .scaleAspectFit // make sure the image fits the frame
    }
    
    // MARK: Lifecycle
    
    /// load a new performance in the ChirpView for playback
    func loadPerformance(_ newPerf: ChirpPerformance) {
        print("ChirpView: Loading existing performance")
        performance = newPerf
        image = newPerf.image
        playbackColour = newPerf.colour.brighterColor.cgColor
        started = false
        lastPoint = CG_INIT_POINT
        swiped = false
        // keep Pd file closed until needed.
        closePdFile()
        //openSoundScheme(withName: newPerf.instrument)
    }
    
    // MARK: - drawing functions

    /// Draws a dot at a given point in the UIImage.
    func drawDot(at point : CGPoint, withColour color : CGColor) {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, (UIScreen.main).scale)
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
        UIGraphicsBeginImageContextWithOptions(frame.size, false, (UIScreen.main).scale)
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
        drawDot(at: point, withColour: playbackColour ?? DEFAULT_PLAYBACK_COLOUR)
        makeSound(at: point, withRadius: radius, thatWasMoving: false)
    }
    /**
     Mirrors touchesMoved for replayed performances.
    **/
    func playbackMoved(_ point : CGPoint, _ radius : CGFloat) {
        swiped = true
        if let lastPoint = self.lastPoint {
            drawLine(from: lastPoint, to: point, withColour: playbackColour ?? DEFAULT_PLAYBACK_COLOUR)
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

}

// MARK: - Pd Patch Managing Functions.

/// Contains Pd and libpd file management for ChirpView.
extension ChirpView {
    
    /// Prepare to play back sounds by loading the appropriate Pd file.
    func prepareToPlaySounds() {
        if let performance = performance {
            openSoundScheme(withName: performance.instrument)
        } else {
            print("ChirpView: No performance loaded.")
        }
    }
    
    /// Given a point in the UIImage, sends a touch point to Pd to process for sound.
    func makeSound(at point : CGPoint, withRadius radius : CGFloat, thatWasMoving moving: Bool) {
        // Pd file must be opened by chirp.prepareToPlaySounds() before sounds can be played.
        guard openPatch != nil else {
            print("ChirpView: attempt to play without opening Pd file")
            return // could throw and exception here.
        }
        
        let x = Double(point.x) / Double(frame.size.width)
        let y = Double(point.y) / Double(frame.size.width)
        let z = Double(min(radius / 120.0, 1.0))
        let m = moving ? 1 : 0
        let receiver : String = "\(openPatchDollarZero ?? Int32(0))" + PdConstants.receiverPostFix
        //let list = ["/x",x,"/y",y,"/z",z] as [Any]
        // FIXME: figure out how to get Pd to parse the list sequentially.
        PdBase.sendList(["/x",x], toReceiver: receiver)
        PdBase.sendList(["/y",y], toReceiver: receiver)
        PdBase.sendList(["/z",z], toReceiver: receiver)
        PdBase.sendList(["/m",m], toReceiver: receiver)
        //print("Radius: \(radius), Z: \(z)")
        //print("/x: \(x) /y: \(y) /z: \(z) /m: \(m)")
    }
    
    /// Attempts to open a SoundScheme given its name.
    func openSoundScheme(withName name: String) {
        print("ChirpView: Attemping to open the Pd File with name:", name)
        if let index = SoundSchemes.namesForKeys.values.index(of: name),
            let fileToOpen = SoundSchemes.pdFilesForKeys[SoundSchemes.namesForKeys.keys[index]] {
            openPd(file: fileToOpen)
        }
    }
    
    /// Opens a Pd file given the filename
    func openPd(file fileToOpen: String) {
        if openPatchName != fileToOpen {
            print("ChirpView: Opening Pd File:", fileToOpen)
            closePdFile()
            openPatch = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
            openPatchName = fileToOpen
            openPatchDollarZero = openPatch?.dollarZero
        } else {
            print("ChirpView:", fileToOpen, "was already open.")
        }
    }
    
    /// Closes whatever Pd file is open.
    func closePdFile() {
        openPatch?.close()
    }
    
}

/// Extension to contain constraint and layout helpers.
extension UIView {
    
    /// Adds constraints to pin the edges of a UIView to a reference view which should be its superview.
    func constrainEdgesTo(_ referenceView: UIView) {
        /// FIXME - make this automatically fail if the referenceView is not an ancestor view of the current view.
        // Width and Height
        let widthConstraint = NSLayoutConstraint(item: self,
                                                attribute: NSLayoutAttribute.width,
                                                relatedBy: NSLayoutRelation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutAttribute.width,
                                                multiplier: 1,
                                                constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self,
                                                attribute: NSLayoutAttribute.height,
                                                relatedBy: NSLayoutRelation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutAttribute.height,
                                                multiplier: 1,
                                                constant: 0)
    
        // Edges
        let leftConstraint = NSLayoutConstraint(item: self,
                                                attribute: NSLayoutAttribute.left,
                                                relatedBy: NSLayoutRelation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutAttribute.left,
                                                multiplier: 1,
                                                constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self,
                                                 attribute: NSLayoutAttribute.right,
                                                 relatedBy: NSLayoutRelation.equal,
                                                 toItem: referenceView,
                                                 attribute: NSLayoutAttribute.right,
                                                 multiplier: 1,
                                                 constant: 0)
        let topConstraint = NSLayoutConstraint(item: self,
                                               attribute: NSLayoutAttribute.top,
                                               relatedBy: NSLayoutRelation.equal,
                                               toItem: referenceView,
                                               attribute: NSLayoutAttribute.top,
                                               multiplier: 1,
                                               constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self,
                                                  attribute: NSLayoutAttribute.bottom,
                                                  relatedBy: NSLayoutRelation.equal,
                                                  toItem: referenceView,
                                                  attribute: NSLayoutAttribute.bottom,
                                                  multiplier: 1,
                                                  constant: 0)

        // Add the constraints
        //referenceView.addConstraints([horizontalConstraint,verticalConstraint])
        referenceView.addConstraints([leftConstraint,rightConstraint,topConstraint,bottomConstraint])
        referenceView.addConstraints([widthConstraint, heightConstraint])
        // Fix the content mode to scaleAspectFill
        contentMode = .scaleAspectFill
    }
}
