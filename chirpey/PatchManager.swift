//
//  PatchManager.swift
//  microjam
//
//  Created by Charles Martin on 13/11/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class PatchManager: NSObject {
    /// Shared instance (singleton) of the user's PerformerProfile
    static let shared = PatchManager()
    /// Storage for all open patch files.
    var openPatches : [PdFile]
    /// Storage for all dollars zero
    var dollarsZero : [Int32]
    /// Dollar Zero to patch file
    var zeroToPatch : [Int32: PdFile]
    
    
    override init() {
        openPatches = [PdFile]()
        dollarsZero = [Int32]()
        zeroToPatch = [Int32: PdFile]()
        super.init()
    }
    
    func addPatch(dollarZero: Int32, patchFile: PdFile) {
        openPatches.append(patchFile)
        dollarsZero.append(dollarZero)
        zeroToPatch[dollarZero] = patchFile
        print(describeState()) // print the state.
    }
    
    /// Close a patch given the dollarZero
    func closePatch(dollarZero: Int32) {
        if let patch = zeroToPatch[dollarZero] {
            print("PatchMan: Starting to Close Patch: \(dollarZero)")
            PdBase.sendBang(toReceiver: "fadeout-\(dollarZero)")
            //DispatchQueue(label: QueueLabels.touchPlayback)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                print("PatchMan: Closing Patch:\(dollarZero)")
                patch.close()
                
                // remove from lists
                if let ind = self.zeroToPatch.index(forKey: dollarZero) {
                    self.zeroToPatch.remove(at: ind)
                }
                if let ind = self.dollarsZero.lastIndex(of: dollarZero) {
                    self.dollarsZero.remove(at: ind)
                }
                if let ind = self.openPatches.lastIndex(of: patch) {
                    self.openPatches.remove(at: ind)
                }
                
                print(self.describeState()) // print the state.
                
            })
        }
    }
    
    func closeAllPatches() {
        let dzs = dollarsZero
        for dz in dzs {
            closePatch(dollarZero: dz)
        }
    }
    
    /// Opens a Pd file given the filename (only if the file is not already open)
    func openPd(file fileToOpen: String) -> Int32? {
        // Only opens it if it's not already open.
        let openPatch = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
        let openPatchDollarZero = openPatch?.dollarZero
        if let dZero = openPatchDollarZero, let pFile = openPatch {
            self.addPatch(dollarZero: dZero, patchFile: pFile)
            // Fade in after 250ms
             DispatchQueue(label: QueueLabels.touchPlayback).asyncAfter(deadline: .now() + 0.5, execute: {
                PdBase.sendBang(toReceiver: "fadein-\(dZero)")
                print("Fading in \(dZero)")
            })
        }
        return openPatchDollarZero
    }
    
    func describeState() -> String {
        return "PatchMan: \(openPatches.count) open patches."
    }
    
}

//             DispatchQueue(label: QueueLabels.touchPlayback).asyncAfter(deadline: .now() + 0.5, execute: {

