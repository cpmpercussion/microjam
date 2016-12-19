//
//  AppDelegate.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

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

    // iCloud stuff
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase

    // MARK: - Pd Engine Functions
    
    /// Starts the Pd Audio Engine and preemptively opens a patch.
    func startAudioEngine() {
        NSLog("JAMVC: Starting Audio Engine");
        self.audioController = PdAudioController()
        self.audioController?.configurePlayback(withSampleRate: Int32(SAMPLE_RATE), numberChannels: Int32(SOUND_OUTPUT_CHANNELS), inputEnabled: false, mixingEnabled: true)
        self.audioController?.configureTicksPerBuffer(Int32(TICKS_PER_BUFFER))
        PdBase.setDelegate(self)
        PdBase.subscribe("toGUI")
        PdBase.subscribe("debug")
        self.openPdFile()
        self.audioController?.isActive = true
        self.audioController?.print()
    }
    
    /// Opens a Pd patch according the UserDefaults, does nothing if the patch is already open.
    func openPdFile() {
        print("AD: Attemping to open the Pd File")
        let fileToOpen = SoundSchemes.pdFilesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]! as String
        if openFileName != fileToOpen {
            self.openFile?.close()
            print("AD: Opening Pd File:", fileToOpen)
            self.openFile = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
            openFileName = fileToOpen
        }
    }
    
    /** 
     Attempts to open a patch with a given name. Does nothing if the patch is already open. 
     If the patch name can't be found, the patch listed in UserDefaults is used instead.
     */
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
            NSLog("AD: Successfully loaded", self.recordedPerformances.count, "performances")
        } else {
            NSLog("AD: Failed to load performances")
        }
        
        // iCloud inits
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        
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
    
    /// Load Performances from file.
    func loadPerformances() -> [ChirpPerformance]? {
        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]
        return loadedPerformances
    }

    /// Add a new performance to the list and then save the list.
    func addNew(performance : ChirpPerformance) {
        self.recordedPerformances.append(performance)
        self.savePerformances()
        self.upload(performance: performance)
    }
    
    /// Save recorded performances to file.
    func savePerformances() {
        NSLog("AD: Going to save %d performances", self.recordedPerformances.count)
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.recordedPerformances, toFile: ChirpPerformance.ArchiveURL.path)
        if (!isSuccessfulSave) {
            print("AD: Save was not successful.")
        } else {
            print("AD: successfully saved", self.recordedPerformances.count, "performances")
        }
    }
    
    struct PerfCloudKeys {
        static let type = "Performance"
        static let date = "Date"
        static let image = "Image"
        static let instrument = "Instrument"
        static let location = "PerformedAt"
        static let performer = "Performer"
        static let replyto = "ReplyTo"
        static let touches = "Touches"
    }
    
    func tempURL() -> URL {
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
        return URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }
    
    var worldJams : [ChirpPerformance] = []
    
    func fetchWorldJamsFromCloud() {
        let numberOfRecords = 100
        let predicate = NSPredicate(format: "", numberOfRecords)
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) {[unowned self] results, error in
            if let error = error {
                DispatchQueue.main.async {
                    //self.delegate?.errorUpdating(error as Error)
                    print("ADCK: Cloud Query error:\(error)")
                }
                return
            }
            self.worldJams.removeAll(keepingCapacity: true)
            // FIXME: make this work.
            results?.forEach({ (record: CKRecord) in
                self.worldJams.append(
                    ChirpPerformance(csv: record.object(forKey: PerfCloudKeys.touches) as! String,
                                    date: record.object(forKey: PerfCloudKeys.date) as! Date,
                                    performer: record.object(forKey: PerfCloudKeys.performer) as! String,
                                    instrument: record.object(forKey: PerfCloudKeys.instrument) as! String,
                                    image: record.object(forKey: PerfCloudKeys.image) as! UIImage,
                                    location: record.object(forKey: PerfCloudKeys.location) as! CLLocation)!)
            })
            // updated!
            // FIXME: make sure any of this works.
    }
    
    func upload(performance : ChirpPerformance) {
        
        // Setup the record
        print("ADCK: Saving the performance:", performance.title())
        print("ADCK: Setting up the record...")
        let performanceID = CKRecordID(recordName: performance.title())
        let performanceRecord = CKRecord(recordType: PerfCloudKeys.type,recordID: performanceID)
        performanceRecord[PerfCloudKeys.date] = performance.date as CKRecordValue
        performanceRecord[PerfCloudKeys.performer] = performance.performer as CKRecordValue
        performanceRecord[PerfCloudKeys.instrument] = performance.instrument as CKRecordValue
        performanceRecord[PerfCloudKeys.touches] = performance.csv() as CKRecordValue
        performanceRecord[PerfCloudKeys.replyto] = "" as CKRecordValue
        performanceRecord[PerfCloudKeys.location] = performance.location as! CKRecordValue
        
        do {
            print("ADCK: Saving the image...")
            let imageURL = tempURL()
            let imageData = UIImagePNGRepresentation(performance.image)!
            try imageData.write(to: imageURL, options: .atomicWrite)
            let asset = CKAsset(fileURL: imageURL)
            performanceRecord[PerfCloudKeys.image] = asset
        }
        catch {
            print("ADCK: Error writing image data:", error)
        }
        
        // Upload to the container
        print("ADCK: Attempting to save to CloudKit")
        let container = CKContainer.default()
        let publicDatabase = container.publicCloudDatabase
//        let privateDatabase = container.privateCloudDatabase
        publicDatabase.save(performanceRecord, completionHandler: {(record, error) -> Void in
            if (error != nil) {
                print("ADCK: Error saving to the database")
                print(error ?? "")
            }
            print("ADCK: Saved to cloudkit! phew.")
            OperationQueue.main.addOperation({ 
                // Do some clean up stuff to express the finishedness of the upload...
                print("ADCK: Doing the cloudkit upload cleanup")
            })
        })
    }
}
