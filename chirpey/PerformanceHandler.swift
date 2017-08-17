//
//  PerformanceHandler.swift
//  microjam
//
//  Created by Henrik Brustad on 16/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class PerformanceHandler: NSObject {
    
    var isPlaying = false
    
    var timers: [Timer]?
    var performances = [ChirpPerformance]()
    var pdFiles = [PdFile]()
    
    convenience init(performances: [ChirpPerformance]) {
        self.init()
        self.performances = performances
        pdFiles = openPdFiles(forPerformances: performances)
    }
    
    func isEmpty() -> Bool {
        return performances.isEmpty
    }
    
    func add(performance: ChirpPerformance) {
        // Add a single performance and open the correct PdFile
        performances.append(performance)
        pdFiles.append(openPdFile(forPerformance: performance)!)
    }
    
    func add(performance: ChirpPerformance, withPdFile file: PdFile) {
        // Add a single performance with the specified PdFile
        performances.append(performance)
        pdFiles.append(file)
    }
    
    func remove(performance: ChirpPerformance) {
        if let index = performances.index(of: performance) {
            pdFiles.remove(at: index)
            performances.remove(at: index)
        }
    }
    
    func removeLastPerformance() {
        // Remove last performance and the corresponding pdFile
        if let _ = performances.popLast(), let file = pdFiles.popLast() {
            closePd(file: file) // Close the file
        }
    }
    
    func removePerformances() {
        // Remove all performances, close all the files and remove the file pointers
        performances.removeAll()
        // Closing all Pd files
        for file in pdFiles {
            closePd(file: file)
        }
        pdFiles.removeAll()
    }
    
    func playPerformances() {
        
        if !isPlaying {
            isPlaying = true
            timers = [Timer]()
            for (i, perf) in performances.enumerated() {
                // make the timers
                for touch in perf.performanceData {
                    timers!.append(Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: { _ in
                        // play back for each touch, with the performance instrument
                        self.makeSound(withTouch: touch, andPdFile: self.pdFiles[i])
                    }))
                }
            }
        }
    }
    
    func play(performances: [ChirpPerformance]) {
        
        let files = openPdFiles(forPerformances: performances)
        
        if !isPlaying {
            isPlaying = true
            timers = [Timer]()
            for (i, perf) in performances.enumerated() {
                // make the timers
                for touch in perf.performanceData {
                    timers!.append(Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: { _ in
                        // play back for each touch, with the performance instrument
                        self.makeSound(withTouch: touch, andPdFile: files[i])
                    }))
                }
            }
        }
    }
    
    
    
    func play(performance: ChirpPerformance, withPdFile file: PdFile) {
        
        playPerformances()
        
        for touch in performance.performanceData {
            timers!.append(Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: { _ in
                self.makeSound(withTouch: touch, andPdFile: file)
            }))
        }
    }
    
    func stopPerformances() {
        
        if isPlaying {
            isPlaying = false
            for timer in timers! {
                timer.invalidate()
            }
        }
    }
    
    /// Given a point in the UIImage, sends a touch point to Pd to process for sound.
    func makeSound(withTouch touch: TouchRecord, andPdFile file: PdFile) {

        let receiver = "\(file.dollarZero)" + PdConstants.receiverPostFix
        //let list = ["/x",x,"/y",y,"/z",z] as [Any]
        // FIXME: figure out how to get Pd to parse the list sequentially.
        PdBase.sendList(["/m", touch.moving], toReceiver: receiver)
        PdBase.sendList(["/z", touch.z], toReceiver: receiver)
        PdBase.sendList(["/y", touch.y], toReceiver: receiver)
        PdBase.sendList(["/x", touch.x], toReceiver: receiver)
    }
    
    /// Opens the PdFiles for all the performance in the array
    private func openPdFiles(forPerformances performances: [ChirpPerformance]) -> [PdFile] {
        
        var files = [PdFile]()
        for perf in performances {
            if let pdFile = openPdFile(forPerformance: perf) {
                files.append(pdFile)
            }
        }
        return files
    }
    
    /// Opens a PdFile for a single performance
    private func openPdFile(forPerformance performance: ChirpPerformance) -> PdFile? {
        
        if let fileKey = SoundSchemes.keysForNames[performance.instrument],
            let file = SoundSchemes.pdFilesForKeys[fileKey] {
            return openPd(file: file)
        }
        return nil
    }
    
    /// Opens a Pd file given the filename
    private func openPd(file: String) -> PdFile {
        return PdFile.openNamed(file, path: Bundle.main.bundlePath) as! PdFile
    }
    
    func openUserSoundScheme() -> PdFile? {
        let userChoiceKey = UserProfile.shared.profile.soundScheme
        if let userChoiceFile = SoundSchemes.pdFilesForKeys[userChoiceKey] {
            return openPd(file: userChoiceFile)
        }
        return nil
    }
    
    /// Closing all the PdFiles opened in the handler
    func closePdFiles() {
        for file in pdFiles {
            closePd(file: file)
        }
    }
    
    /// Closes a Pd file
    private func closePd(file: PdFile) {
        file.close()
    }
    
    
}
