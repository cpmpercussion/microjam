//
//  Player.swift
//  microjam
//
//  Created by Henrik Brustad on 18/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Enabled classes to receive updates on the playback state of ChirpPlayers and ChirpRecorders.
protocol PlayerDelegate {
    
    func progressTimerEnded()
    func progressTimerStep()
}

/// Plays back one or more ChirpViews
class ChirpPlayer: NSObject {
    
    var maxPlayerTime = 5.0
    
    var isPlaying = false
    var timers = [Timer]()
    var chirpViews = [ChirpView]()
    var viewsAreLoaded = false
    
    var progressTimer: Timer?
    var progress = 0.0
    
    var delegate: PlayerDelegate?
    
    func play(chirp: ChirpView) {
        for touch in chirp.performance!.performanceData {
            timers.append(Timer.scheduledTimer(withTimeInterval: touch.time,
                                               repeats: false,
                                               block: chirp.makeTouchPlayerWith(touch: touch)))
        }
    }
    
    func play() {
        
        if !isPlaying {
            isPlaying = true
            
            timers = [Timer]()
            
            for chirp in chirpViews {
                play(chirp: chirp)
            }
            
            startProgressTimer()
        }
    }
    
    func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.step()
        })
    }
    
    func step() {
        
        self.delegate!.progressTimerStep()
        
        if progress >= maxPlayerTime {
            self.delegate!.progressTimerEnded()
        }
        
        progress += 0.01
    }
    
    func stop() {
        
        if isPlaying {
            isPlaying = false
            
            if let timer = progressTimer {
                timer.invalidate()
                progress = 0.0
                
                for t in timers {
                    t.invalidate()
                }
                
                for chirp in chirpViews {
                    chirp.image = chirp.performance!.image
                }
            }
        }
    }
}




