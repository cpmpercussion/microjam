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
    /// Stores the details of the last touch for animating strokes.
    var lastTouch : TouchRecord?
    /// A CALayer for doing animations
    var animationLayer : CALayer?
    
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
    /// Stores the previously set volume level
    var volume = 1.0
    /// Stores the mute state
    var muted = false
    
    // MARK: Initialisers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        resetAnimationLayer() // set up the animation layer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        resetAnimationLayer() // set up the animation layer
    }
    
    /// Convenience Initialiser only used when loading performances for playback only. Touch is disabled!
    convenience init(with frame: CGRect, andPerformance perf: ChirpPerformance){
        self.init(frame: frame)
        //        print("ChirpView: Loading programmatically with frame: ", self.frame) // runs too many times to be helpful...
        isMultipleTouchEnabled = false // multitouch is disabled!
        isUserInteractionEnabled = false // user-interaction is disabled!
        loadPerformance(perf)
        contentMode = .scaleAspectFit // make sure the image fits the frame
    }
    
    // MARK: Lifecycle
    
    /// load a new performance in the ChirpView for playback
    func loadPerformance(_ newPerf: ChirpPerformance) {
        // print("ChirpView: Loading existing performance") // Runs too many times to be helpful...
        performance = newPerf
        image = newPerf.image
        if newPerf.image == nil, let recID = newPerf.performanceID {
            // Fetch the image if it hasn't been downloaded yet.
            PerformanceStore.shared.fetchImageFor(performance: recID, andAssignTo: self)
        }
        playbackColour = newPerf.colour.brighterColor.cgColor
        started = false
        lastPoint = CG_INIT_POINT
        swiped = false
        // keep Pd file closed until needed.
        closePdFile()
        //openSoundScheme(withName: newPerf.instrument)
    }
    
    // MARK: - drawing functions
    
    /// Trying to maybe do faster UIImage drawing?
    func draw(image: UIImage, inContext context: CGContext, withRect rect: CGRect) {
        guard let im = image.cgImage else {
            return
        }
        context.saveGState()
        context.translateBy(x: 0.0, y: CGFloat(im.height))
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(im, in: rect)
        context.restoreGState()
    }

    /// Draws a dot at a given point in the UIImage.
    func drawDot(at point : CGPoint, withColour color : CGColor) {
        guard let animationLayer = animationLayer else {
            return
        }
        let ellipse = CAShapeLayer()
        let ellipseRect = CGRect(x:point.x - 5, y:point.y - 5, width:10, height:10)
        let ellipsePath = UIBezierPath(roundedRect: ellipseRect, cornerRadius: 5.0)
        ellipse.path = ellipsePath.cgPath
        ellipse.fillColor = color
        ellipse.opacity = 1.0
        ellipse.fillColor = color
        animationLayer.addSublayer(ellipse)
    }

    /// Draws a line between two points in the UIImage.
    func drawLine(from fromPoint : CGPoint, to toPoint : CGPoint, withColour color : CGColor) {
        guard let animationLayer = animationLayer else {
            return
        }
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: fromPoint)
        linePath.addLine(to: toPoint)
        line.path = linePath.cgPath
        line.lineCap = .round
        line.lineWidth = 10.0
        line.fillColor = nil
        line.opacity = 1.0
        line.strokeColor = color
        animationLayer.addSublayer(line)
    }
    
    func resetAnimationLayer() {
        animationLayer?.removeFromSuperlayer()
        animationLayer = CALayer(layer: layer)
        if let animationLayer = animationLayer {
            layer.addSublayer(animationLayer) // try out CALayers?
        }
    }
    
    /// Reset the Animation Layer and restore the performance image.
    func setImage() {
        resetAnimationLayer()
        if let performance = performance {
            image = performance.image
        }
    }

    /// Make an image out of the animationLayer CALayers
    func moveAnimationLayerToImage() -> UIImage? {
        print("Going to try to output the layers")
        UIGraphicsBeginImageContextWithOptions(frame.size, false, (UIScreen.main).scale)
        guard let context = UIGraphicsGetCurrentContext(),
            let animationLayer = animationLayer else {
            return UIImage()
        }
        animationLayer.render(in: context)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }

    // MARK: - playback functions
    /// Converts x and y points to frame context
    func touchRecordToFrameCoordinate(x: Double, y: Double) -> CGPoint {
        return CGPoint(x: Double(frame.size.width) * x, y: Double(frame.size.width) * y)
    }
    
    /// Mirrors touchesBegan for replayed performances.
    func playbackBegan(_ touch: TouchRecord) {
        swiped = false
        makeSound(at: touch)
        DispatchQueue.main.async {
            let p = self.touchRecordToFrameCoordinate(x: touch.x, y: touch.y)
            self.drawDot(at: p, withColour: self.playbackColour ?? DEFAULT_PLAYBACK_COLOUR)
        }
        lastTouch = touch
    }
    
    /// Mirrors touchesMoved for replayed performances.
    func playbackMoved(_ touch: TouchRecord) {
        swiped = true
        makeSound(at: touch)
        if let lastTouch = self.lastTouch {
            DispatchQueue.main.async {
                let p = self.touchRecordToFrameCoordinate(x: touch.x, y: touch.y)
                let lp = self.touchRecordToFrameCoordinate(x: lastTouch.x, y: lastTouch.y)
                self.drawLine(from: lp, to: p, withColour: self.playbackColour ?? DEFAULT_PLAYBACK_COLOUR)
            }
        }
        lastTouch = touch
    }
    
    /// Returns function for playing a `TouchRecord` at a certain time. Used for playing back touches.
    func makeTouchPlayerWith(touch: TouchRecord) -> ((Timer) -> Void) {
        let playbackFunction : (TouchRecord) -> Void = touch.moving ? playbackMoved : playbackBegan
        func playbackTouch(withTimer timer: Timer) {
            playbackFunction(touch)
        }
        return playbackTouch
    }
    
    /// Alternative function for playing back a touch record.
    func play(touch: TouchRecord) {
        let playbackFunction : (TouchRecord) -> Void = touch.moving ? playbackMoved : playbackBegan
        playbackFunction(touch)
    }
}

// MARK: - Pd Patch Managing Functions.

/// Contains Pd and libpd file management for ChirpView.
extension ChirpView {
    
    /// Given x, y, z, moving, send a touch point to Pd to process for sound.
    func makeSound(x: Double, y: Double, z: Double, moving: Bool) {
        guard openPatch != nil else {
            print("ChirpView: attempt to play without opening Pd file")
            return // could throw an exception here.
        }
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
    
    /// Given a point in the UIImage, sends a touch point to Pd to process for sound.
    func makeSound(at point : CGPoint, withRadius radius : CGFloat, thatWasMoving moving: Bool) {
        let x = Double(point.x) / Double(frame.size.width)
        let y = Double(point.y) / Double(frame.size.width)
        let z = Double(min(radius / 120.0, 1.0))
        // Dispatch makeSound to the touchPlayback queue to ensure safety wrt concurrent playback and performing.
        DispatchQueue(label: QueueLabels.touchPlayback).async {
            self.makeSound(x: x, y: y, z: z, moving: moving)
        }
    }
    
    /// Given a touch point, send it to Pd to process for sound.
    func makeSound(at touch : TouchRecord) {
        let z = Double(min(touch.z / 120.0, 1.0))
        makeSound(x: touch.x, y: touch.y, z: z, moving: touch.moving)
    }
    
    /// Prepare to play back sounds by loading the appropriate Pd file.
    func prepareToPlaySounds() {
        if let performance = performance {
            openSoundScheme(withName: performance.instrument)
        } else {
            print("ChirpView: No performance loaded.")
        }
    }
    
    /// Attempts to open a SoundScheme given its name.
    func openSoundScheme(withName name: String) {
        print("ChirpView: Attemping to open the Pd File with name:", name)
        if let index = SoundSchemes.namesForKeys.values.firstIndex(of: name),
            let fileToOpen = SoundSchemes.pdFilesForKeys[SoundSchemes.namesForKeys.keys[index]] {
            openPd(file: fileToOpen)
        }
    }
    
    /// Opens a Pd file given the filename (only if the file is not already open)
    func openPd(file fileToOpen: String) {
        // Only opens it if it's not already open.
        if openPatchName != fileToOpen {
            closePdFile() // close what was previously open
            openPatchDollarZero = PatchManager.shared.openPd(file: fileToOpen) // open the file
            openPatch = PatchManager.shared.zeroToPatch[openPatchDollarZero ?? 0] // set the $0
            openPatchName = fileToOpen // set the file
            // Set mute state.
            if muted {
                PdBase.send(0.0, toReceiver: "\(openPatchDollarZero ?? Int32(0))" + PdConstants.volumePostFix)
            } else {
                PdBase.send(Float(volume), toReceiver: "\(openPatchDollarZero ?? Int32(0))" + PdConstants.volumePostFix)
            }
        }
    }
    
    /// Closes whatever Pd file is open.
    func closePdFile() {
        guard let dZero = openPatchDollarZero else {
            return
        }
        PatchManager.shared.closePatch(dollarZero: dZero) // get the patch manager to close the file.
    }
    
    func muteOn() {
        muted = true
        if let dollarZero = openPatchDollarZero {
            PdBase.send(0.0, toReceiver: "\(dollarZero)" + PdConstants.volumePostFix)
        }
    }
    
    func muteOff() {
        muted = false
        if let dollarZero = openPatchDollarZero {
            PdBase.send(Float(volume), toReceiver: "\(dollarZero)" + PdConstants.volumePostFix)
        }
    }
    
    func setVolume(toLevel: Float){
        volume = Double(min(max(toLevel, 0.0), 1.0))
        if let dollarZero = openPatchDollarZero {
            PdBase.send(Float(volume), toReceiver: "\(dollarZero)" + PdConstants.volumePostFix)
        }
    }
    
    /// ChirpViews should be closed gracefully to avoid bad audio junk.
    func closeGracefully() {
        // TODO: is this still needed? should be taken care of by patchManager.
        closePdFile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.removeFromSuperview()
        })
    }
}

/// Extension to contain constraint and layout helpers.
extension UIView {
    
    /// Adds constraints to pin the edges of a UIView to a reference view which should be its superview.
    func constrainEdgesTo(_ referenceView: UIView) {
        /// FIXME - make this automatically fail if the referenceView is not an ancestor view of the current view.
        // Width and Height
        let widthConstraint = NSLayoutConstraint(item: self,
                                                attribute: NSLayoutConstraint.Attribute.width,
                                                relatedBy: NSLayoutConstraint.Relation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutConstraint.Attribute.width,
                                                multiplier: 1,
                                                constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self,
                                                attribute: NSLayoutConstraint.Attribute.height,
                                                relatedBy: NSLayoutConstraint.Relation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutConstraint.Attribute.height,
                                                multiplier: 1,
                                                constant: 0)
    
        // Edges
        let leftConstraint = NSLayoutConstraint(item: self,
                                                attribute: NSLayoutConstraint.Attribute.left,
                                                relatedBy: NSLayoutConstraint.Relation.equal,
                                                toItem: referenceView,
                                                attribute: NSLayoutConstraint.Attribute.left,
                                                multiplier: 1,
                                                constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self,
                                                 attribute: NSLayoutConstraint.Attribute.right,
                                                 relatedBy: NSLayoutConstraint.Relation.equal,
                                                 toItem: referenceView,
                                                 attribute: NSLayoutConstraint.Attribute.right,
                                                 multiplier: 1,
                                                 constant: 0)
        let topConstraint = NSLayoutConstraint(item: self,
                                               attribute: NSLayoutConstraint.Attribute.top,
                                               relatedBy: NSLayoutConstraint.Relation.equal,
                                               toItem: referenceView,
                                               attribute: NSLayoutConstraint.Attribute.top,
                                               multiplier: 1,
                                               constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self,
                                                  attribute: NSLayoutConstraint.Attribute.bottom,
                                                  relatedBy: NSLayoutConstraint.Relation.equal,
                                                  toItem: referenceView,
                                                  attribute: NSLayoutConstraint.Attribute.bottom,
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
