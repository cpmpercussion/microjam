//
//  AppDelegate.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

struct SettingsKeys {
    static let performerKey = "performer_name"
    static let soundSchemeKey = "sound_scheme"
}

struct SoundSchemes {
    static let namesForKeys : [Int : String] = [
        0 : "chirp",
        1 : "keys",
        2 : "drums",
        3 : "strings"
    ]
    static let pdFilesForKeys : [Int : String] = [
        0 : "chirp.pd",
        1 : "keys.pd",
        2 : "drums.pd",
        3 : "strings.pd"
    ]
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PdReceiverDelegate {
    var window: UIWindow?
    var recordedPerformances : [ChirpPerformance] = []
 
    static let defaultSettings : [String : Any] = [
        SettingsKeys.performerKey:"performer",
        SettingsKeys.soundSchemeKey: 0
    ]
    let SOUND_OUTPUT_CHANNELS = 2
    let SAMPLE_RATE = 44100
    let TICKS_PER_BUFFER = 4
    var audioController : PdAudioController?
    var openFile : PdFile?
    var openFileName = ""

    // MARK: - Pd Engine Functions
    func startAudioEngine() {
        NSLog("JAMVC: Starting Audio Engine");
        self.audioController = PdAudioController()
        self.audioController?.configurePlayback(withSampleRate: Int32(SAMPLE_RATE), numberChannels: Int32(SOUND_OUTPUT_CHANNELS), inputEnabled: false, mixingEnabled: true)
        self.audioController?.configureTicksPerBuffer(Int32(TICKS_PER_BUFFER))
        //    [self openPdPatch];
        PdBase.setDelegate(self)
        PdBase.subscribe("toGUI")
        PdBase.subscribe("debug")
        self.openPdFile()
        self.audioController?.isActive = true
        //[self.audioController setActive:YES];
        self.audioController?.print()
        NSLog("JAMVC: Ticks Per Buffer: %d",self.audioController?.ticksPerBuffer ?? "didn't work!");
    }
    
    /// Check if Pd File is already open, if not,
    func openPdFile() {
        print("AD: Attemping to open the Pd File")
        let fileToOpen = SoundSchemes.pdFilesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]! as String
        if openFileName != fileToOpen {
            self.openFile?.close()
            print("AD: Opening Pd File:", fileToOpen)
            self.openFile = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
            //self.openFile = (PdBase.openFile(fileToOpen, path: Bundle.main.bundlePath) as! PdFile)
            openFileName = fileToOpen
        }
    }
    
    func openPdFile(withName name: String) {
        print("AD: Attemping to open the Pd File with name:", name)
        var fileToOpen = SoundSchemes.pdFilesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]! as String
        // See if we can retrieve the scheme for this name.
        if let index = SoundSchemes.namesForKeys.values.index(of: name) {
            let key = SoundSchemes.namesForKeys.keys[index]
            fileToOpen = SoundSchemes.pdFilesForKeys[key]! as String
        }
        // Open the file.
        if openFileName != fileToOpen {
            self.openFile?.close()
            print("AD: Opening Pd File:", fileToOpen)
            self.openFile = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
            //self.openFile = (PdBase.openFile(fileToOpen, path: Bundle.main.bundlePath) as! PdFile)
            openFileName = fileToOpen
        } else {
            print("AD:", name, "was already open!")
        }
    }
    
    
    /// Receives print messages from Pd for debugging
    func receivePrint(_ message: String!) {
        NSLog("Pd: %@", message)
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Register defaults
        UserDefaults.standard.register(defaults: AppDelegate.defaultSettings)
        // Load the saved performances
        if let savedPerformances = self.loadPerformances() {
            self.recordedPerformances += savedPerformances
            NSLog("AD: Successfully loaded %d performances", self.recordedPerformances.count)
        } else {
            NSLog("AD: Failed to load performances")
        }
        
        self.startAudioEngine() // start Pd
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        //
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        //
        print("AD: Application will terminate")
        self.savePerformances()
    }
    
    func loadPerformances() -> [ChirpPerformance]? {
        // load the performances

        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]

        //NSLog("AD: Loaded %d performances", loadedPerformances?.count)
        return loadedPerformances

    }

    /// Add a new performance to the list and then save the list.
    func addNew(performance : ChirpPerformance) {
        self.recordedPerformances.append(performance)
        self.savePerformances()
    }
    
    
    func savePerformances() {
        // save the recordedPerformances
        NSLog("AD: Going to save %d performances", self.recordedPerformances.count)
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.recordedPerformances, toFile: ChirpPerformance.ArchiveURL.path)
        
        if (!isSuccessfulSave) {
            print("AD: Save was not successful.")
        } else {
            print("AD: %d performances successfully saved.", self.recordedPerformances.count)
        }
    }

}
