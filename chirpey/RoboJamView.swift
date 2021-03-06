//
//  RoboJamView.swift
//  microjam
//
//  Created by Charles Martin on 20/9/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Subclass of ChirpView for a robojam performance to be loaded.
class RoboJamView: ChirpView {
    /// Array of timers used for currently playing performance.
    var timers = [Timer]()
    
    // MARK: - silent reply functions
    
    /**
     Mirrors touchesBegan for replayed performances.
     **/
    func silentPlaybackBegan(_ point : CGPoint, _ radius : CGFloat) {
        swiped = false
        lastPoint = point
        drawDot(at: point, withColour: self.performance?.colour.darkerColor.cgColor ?? DEFAULT_PLAYBACK_COLOUR)
    }
    /**
     Mirrors touchesMoved for replayed performances.
     **/
    func silentPlaybackMoved(_ point : CGPoint, _ radius : CGFloat) {
        swiped = true
        if let lastPoint = self.lastPoint {
            drawLine(from: lastPoint, to: point, withColour: self.performance?.colour.darkerColor.cgColor ?? DEFAULT_PLAYBACK_COLOUR)
        }
        lastPoint = point
    }
    
    /// Returns function for playing a `TouchRecord` at a certain time. Used for playing back touches.
    func makeSilentTouchPlayerWith(touch: TouchRecord) -> ((Timer) -> Void) {
        let z = CGFloat(touch.z)
        let point = CGPoint(x: Double(frame.size.width) * touch.x, y: Double(frame.size.width) * touch.y)
        let playbackFunction : (CGPoint, CGFloat) -> Void = touch.moving ? silentPlaybackMoved : silentPlaybackBegan
        func playbackTouch(withTimer timer: Timer) {
            playbackFunction(point, z)
        }
        return playbackTouch
    }
    
    /// Play out the loaded robojam silently to create the image.
    func generateImage() {
        print("Generating Image")
        guard let performance = performance else {
            print("No performance to generate from.")
            return
        }
        var animationTime = 0.0
        for touch in performance.performanceData {
            let frameTime = touch.time * 0.4
            timers.append(Timer.scheduledTimer(withTimeInterval: frameTime,
                                               repeats: false,
                                               block: makeSilentTouchPlayerWith(touch: touch)))
            animationTime = frameTime
        }
        animationTime += 0.1
        print("Trying to add the performance image in:", animationTime)
        timers.append(Timer.scheduledTimer(withTimeInterval: animationTime,
                                           repeats: false,
                                           block: addGeneratedImage))
    }
    
    /// update the performance image.
    func addGeneratedImage(_ timer: Timer) {
        if let image = self.moveAnimationLayerToImage(), let perf = self.performance {
            perf.image = image
            print("RoboJamView: added complete image")
        }
    }

}
