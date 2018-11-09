//
//  Player.swift
//  microjam
//
//  Created by Henrik Brustad on 18/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import Repeat

/// Enabled classes to receive updates on the playback state of ChirpPlayers and ChirpRecorders.
protocol PlayerDelegate {
    /// Called when playback starts.
    func playbackStarted()
    /// Called when playback is completed.
    func playbackEnded()
    /// Called at each timestep (0.01s) during playback
    func playbackStep(_ time: Double)
}

/// Plays back one or more ChirpViews
class ChirpPlayer: NSObject {
    /// Maximum playback time of any player (or recording)
    var maxPlayerTime = 5.0
    /// Stores whether the player is currently playing.
    var isPlaying = false
    /// Array of timers used for currently playing performance.
    var timers = [Repeater]()
    /// Array of ChirpViews used for loaded performances.
    var chirpViews = [ChirpView]()
    /// Stores whether views have been loaded. (Maybe only used in ChirpRecorder?)
    var viewsAreLoaded = false
    /// Overall playback timer for displaying progress bar etc.
    var progressTimer: Repeater?
    /// Current progress through playback.
    var progress = 0.0
    /// Stores delegate to inform them about start/stop events and current progress.
    var delegate: PlayerDelegate?
    /// Dispatch Queue for the playback events
    var touchPlaybackQueue = DispatchQueue(label: "au.com.charlesmartin.microjam.touchplayback")
    /// Dispatch Queue for timer
    var perfTimerQueue = DispatchQueue(label: "au.com.charlesmartin.microjam.perftimer")
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
            timers.append(
                Repeater.once(after: .seconds(touch.time), queue: touchPlaybackQueue) { timer in
                    chirp.play(touch: touch) }
            )
        }
    }
    
    /// Convenience initialiser for creating a ChirpPlayer with an array of ChirpPerformances
    convenience init(withArrayOfPerformances performanceArray: [ChirpPerformance]) {
        let dummyFrame = CGRect.zero
        self.init()
        for perf in performanceArray {
            let chirp = ChirpView(with: dummyFrame, andPerformance: perf)
            chirpViews.append(chirp)
        }
    }
    
    /// Start playback.
    func play() {
        if !isPlaying {
            isPlaying = true
            timers = [Repeater]()
            for chirp in chirpViews {
                chirp.prepareToPlaySounds()
                play(chirp: chirp)
            }
            print("ChirpPlayer: Playing back: \(timers.count) touch events.")
            startProgressTimer()
        }
    }
    
    /// Start the progress timer.
    func startProgressTimer() {
        self.delegate?.playbackStarted() // tell delegate the progress timer has started.
        progressTimer = Repeater.every(.seconds(0.01), count: 502, queue: perfTimerQueue) { timer  in
            self.step()
        }
        progressTimer?.onStateChanged = { (timer,newState) in
            if newState == .finished {
                self.stop()
            }
        }
        
    }
    
    /// Move one time step (0.01s) through the progress timer.
    func step() {
        progress += 0.01
        self.delegate!.playbackStep(progress)
        if progress > maxPlayerTime {
            DispatchQueue.main.async { self.delegate!.playbackEnded() }
        }
    }
    
    /// Stop playback and reset timers.
    func stop() {
        if isPlaying {
            isPlaying = false
            if let timer = progressTimer {
                timer.removeAllObservers(thenStop: true)
                progress = 0.0
                
                for t in timers {
                    t.removeAllObservers(thenStop: true)
                }
                
                for chirp in chirpViews {
                    chirp.image = chirp.performance!.image
                }
            }
        }
    }
}




