//
//  RoboJamView.swift
//  microjam
//
//  Created by Charles Martin on 20/9/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Subclass of ChirpView for a roboplay performance to be loaded.
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
        guard let performance = performance else {
            print("No performance to generate from.")
            return
        }
        var animationTime = 0.0
        for touch in performance.performanceData {
            timers.append(Timer.scheduledTimer(withTimeInterval: animationTime,
                                               repeats: false,
                                               block: makeSilentTouchPlayerWith(touch: touch)))
            animationTime += 0.01
        }
        timers.append(Timer.scheduledTimer(withTimeInterval: animationTime, repeats: false, block: {(Timer) -> Void in
            if let image = self.image, let perf = self.performance {
                perf.image = image
            }
        }))
        
    }

}
