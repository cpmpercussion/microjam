//
//  Player.swift
//  microjam
//
//  Created by Henrik Brustad on 18/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

protocol PlayerDelegate {
    
    func playerShouldStop()
}

class Player: NSObject {
    
    var isPlaying = false
    var timers = [Timer]()
    var chirpViews = [ChirpView]()
    
    var progressTimer: Timer?
    
    var delegate: PlayerDelegate?
    
    func play() {
        
        if !isPlaying {
            isPlaying = true
            
            timers = [Timer]()
            
            for chirp in chirpViews {
                for touch in chirp.performance!.performanceData {
                    timers.append(Timer.scheduledTimer(withTimeInterval: touch.time,
                                                       repeats: false,
                                                       block: chirp.makeTouchPlayerWith(touch: touch)))
                }
            }
            
            progressTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { (timer) in
                self.delegate!.playerShouldStop()
            })
        }
    }
    
    func stop() {
        
        if isPlaying {
            isPlaying = false
            
            if let progress = progressTimer {
                progress.invalidate()
                
                for timer in timers {
                    timer.invalidate()
                }
                
                for chirp in chirpViews {
                    chirp.image = chirp.performance!.image
                }
            }
        }
    }
}




