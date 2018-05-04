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
    /// Called when playback is completed.
    func progressTimerEnded()
    /// Called at each timestep (0.01s) during playback
    func progressTimerStep()
}

/// Plays back one or more ChirpViews
class ChirpPlayer: NSObject {
    /// Maximum playback time of any player (or recording)
    var maxPlayerTime = 5.0
    /// Stores whether the player is currently playing.
    var isPlaying = false
    /// Array of timers used for currently playing performance.
    var timers = [Timer]()
    /// Array of ChirpViews used for loaded performances.
    var chirpViews = [ChirpView]()
    /// Stores whether views have been loaded. (Maybe only used in ChirpRecorder?)
    var viewsAreLoaded = false
    /// Overall playback timer for displaying progress bar etc.
    var progressTimer: Timer?
    /// Current progress through playback.
    var progress = 0.0
    /// Stores delegate to inform them about start/stop events and current progress.
    var delegate: PlayerDelegate?
    /// Description of the ChirpPlayer with it's first ChirpPerformance.
    override var description: String {
        guard let perfString = chirpViews.first?.performance?.description else {
            return "ChirpPlayer-NoPerformance"
        }
        return "ChirpPlayer-" + perfString
    }
        
    /// Play a particular ChirpView's performance
    func play(chirp: ChirpView) {
        for touch in chirp.performance!.performanceData {
            timers.append(Timer.scheduledTimer(withTimeInterval: touch.time,
                                               repeats: false,
                                               block: chirp.makeTouchPlayerWith(touch: touch)))
        }
    }
    
    /// Start playback.
    func play() {
        if !isPlaying {
            isPlaying = true
            timers = [Timer]()
            for chirp in chirpViews {
                chirp.prepareToPlaySounds()
                play(chirp: chirp)
            }
            startProgressTimer()
        }
    }
    
    /// Start the progress timer.
    func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.step()
        })
    }
    
    /// Move one time step (0.01s) through the progress timer.
    func step() {
        self.delegate!.progressTimerStep()
        if progress >= maxPlayerTime {
            self.delegate!.progressTimerEnded()
        }
        progress += 0.01
    }
    
    /// Stop playback and reset timers.
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




