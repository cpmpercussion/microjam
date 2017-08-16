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
        
        performances.append(performance)
        pdFiles.append(openPdFile(forPerformance: performance)!)
        
        print("Added performance!")
    }
    
    func removeLastPerformance() -> Bool {
        
        if let _ = performances.popLast(), let file = pdFiles.popLast() {
            closePd(file: file)
            return true
        }
        
        return false
    }
    
    func removePerformances() {
        
        performances.removeAll()
        // Closing all Pd files
        for file in pdFiles {
            closePd(file: file)
        }
        pdFiles.removeAll()
    }
    
    func playPerformances() {
        
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
    
    private func openPdFiles(forPerformances performances: [ChirpPerformance]) -> [PdFile] {
        
        var files = [PdFile]()
        
        for perf in performances {
            if let pdFile = openPdFile(forPerformance: perf) {
                files.append(pdFile)
            }
        }
        
        return files
    }
    
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
