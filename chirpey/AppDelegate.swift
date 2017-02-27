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
    static let performerColourKey = "performer_colour"
    static let backgroundColourKey = "background_colour"
    static let soundSchemeKey = "sound_scheme"
}

protocol ModelDelegate {
    func errorUpdating(error: NSError)
    func modelUpdated()
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

/// Maximum number of jams to download at a time from CloudKit
let max_jams_to_fetch = 25


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PdReceiverDelegate {
    var window: UIWindow?
    var storedPerformances : [ChirpPerformance] = []
    static let defaultSettings : [String : Any] = [
        SettingsKeys.performerKey:"performer",
        SettingsKeys.performerColourKey: 0.5,
        SettingsKeys.backgroundColourKey: 0.2,
        SettingsKeys.soundSchemeKey: 0
    ]
    let SOUND_OUTPUT_CHANNELS = 2
    let SAMPLE_RATE = 44100
    let TICKS_PER_BUFFER = 4
    var audioController : PdAudioController?
//    var openFile : PdFile?
//    var openFileName = ""

    // iCloud stuff
    let container: CKContainer = CKContainer.default()
    let publicDB: CKDatabase = CKContainer.default().publicCloudDatabase
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    var delegate : ModelDelegate?
    

    

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
        self.audioController?.isActive = true
        self.audioController?.print()
    }
    
//    /// Opens a Pd patch according the UserDefaults, does nothing if the patch is already open.
//    func openPdFile() {
//        print("AD: Attemping to open the Pd File from settings.")
//        let fileToOpen = SoundSchemes.pdFilesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]! as String
//        if openFileName != fileToOpen {
//            self.openFile?.close()
//            print("AD: Opening Pd File:", fileToOpen)
//            self.openFile = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
//            openFileName = fileToOpen
//        }
//    }
//    
//    /** 
//     Attempts to open a patch with a given name. Does nothing if the patch is already open. 
//     If the patch name can't be found, the patch listed in UserDefaults is used instead.
//     */
//    func openPdFile(withName name: String) {
//        print("AD: Attemping to open the Pd File with name:", name)
//        var fileToOpen = SoundSchemes.pdFilesForKeys[UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)]! as String
//        // See if we can retrieve the scheme for this name.
//        if let index = SoundSchemes.namesForKeys.values.index(of: name) {
//            let key = SoundSchemes.namesForKeys.keys[index]
//            fileToOpen = SoundSchemes.pdFilesForKeys[key]! as String
//        }
//        // Open the file.
//        if openFileName != fileToOpen {
//            self.openFile?.close()
////            print("AD: Opening Pd File:", fileToOpen)
//            self.openFile = PdFile.openNamed(fileToOpen, path: Bundle.main.bundlePath) as? PdFile
//            //self.openFile = (PdBase.openFile(fileToOpen, path: Bundle.main.bundlePath) as! PdFile)
//            openFileName = fileToOpen
//        } else {
////            print("AD:", name, "was already open!")
//        }
//    }
    
    
    /// Receives print messages from Pd for debugging
    func receivePrint(_ message: String!) {
        NSLog("Pd: %@", message)
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Register defaults
        UserDefaults.standard.register(defaults: AppDelegate.defaultSettings)
        // Load the saved performances
        if let savedPerformances = self.loadPerformances() {
            self.storedPerformances += savedPerformances
            self.sortStoredPerformances()
            NSLog("AD: Successfully loaded", self.storedPerformances.count, "performances")
        } else {
            NSLog("AD: Failed to load performances")
        }
        self.startAudioEngine() // start Pd
        self.fetchWorldJamsFromCloud() // try to get jams from iCloud.
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
    
    /// Load Local Performances from file.
    func loadPerformances() -> [ChirpPerformance]? {
        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]
        return loadedPerformances
    }

    /// Add a new performance to the list and then save the list.
    func addNew(performance : ChirpPerformance) {
        self.storedPerformances.insert(performance, at: 0)//
        self.savePerformances()
        self.upload(performance: performance)
    }
    
    /// Save recorded performances to file.
    func savePerformances() {
        NSLog("AD: Going to save %d performances", self.storedPerformances.count)
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.storedPerformances, toFile: ChirpPerformance.ArchiveURL.path)
        if (!isSuccessfulSave) {
            print("AD: Save was not successful.")
        } else {
            print("AD: successfully saved", self.storedPerformances.count, "performances")
        }
    }
    
    /// Keys for performance data in CloudKit Storage
    struct PerfCloudKeys {
        static let type = "Performance"
        static let date = "Date"
        static let image = "Image"
        static let instrument = "Instrument"
        static let location = "PerformedAt"
        static let performer = "Performer"
        static let replyto = "ReplyTo"
        static let touches = "Touches"
        static let colour = "Colour"
    }
    
    /// Returns a temporary file path for png images
    func tempURL() -> URL {
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
        return URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }
    
    
    /// Refresh list of world jams from CloudKit and then update in world jam table view.
    func fetchWorldJamsFromCloud() {
        print("ADCK: Attempting to fetch World Jams from Cloud.")
        var fetchedPerformances = [ChirpPerformance]()
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)
        /// FIXME: predicate should only download latest 100 jams from the last month or something.
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        query.sortDescriptors = [sort]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = max_jams_to_fetch
        operation.recordFetchedBlock = { record in
            let perf = self.performanceFrom(record: record)
            fetchedPerformances.append(perf)
        } // Appends fetched records to the array of Performances
        
        operation.queryCompletionBlock = { [unowned self] (cursor, error) in
            // Handle possible error.
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error: error as NSError)
                    print("ADCK: Cloud Query error:\(error)")
                }
                return
            }
            self.storedPerformances = fetchedPerformances // update the stored performances
            print("ADCK: ", self.storedPerformances.count, " world jams collected.")
            DispatchQueue.main.async { // give the delegate the trigger to update the table.
                self.delegate?.modelUpdated()
            }
        }
        
        publicDB.add(operation) // perform the operation.
        
        // TODO: Define a more sensible way of downloading the performances
        // Downloaded performances should augment existing data, not overwrite it.
    }
    
    /// Sorts the stored performances by date
    func sortStoredPerformances() {
        self.storedPerformances.sort(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
            rec1.date > rec2.date
        })
    }
    
    /// Returns a ChirpPerformance from a CKRecord of a performance
    func performanceFrom(record: CKRecord) -> ChirpPerformance {
        // TODO: Need some kind of protection against failure here.
        let touches = record.object(forKey: PerfCloudKeys.touches) as! String
        let date = (record.object(forKey: PerfCloudKeys.date) as! NSDate) as Date
        let performer = record.object(forKey: PerfCloudKeys.performer) as! String
        let instrument = record.object(forKey: PerfCloudKeys.instrument) as! String
        let location = record.object(forKey: PerfCloudKeys.location) as! CLLocation
        let colour = record.object(forKey: PerfCloudKeys.colour) as! String
        let imageAsset = record.object(forKey: PerfCloudKeys.image) as! CKAsset
        let image = UIImage(contentsOfFile: imageAsset.fileURL.path)!
        let replyto = record.object(forKey: PerfCloudKeys.replyto) as! String
        let perf = ChirpPerformance(csv: touches, date: date, performer: performer,
                                    instrument: instrument, image: image, location: location,
                                    colour: colour, replyto: replyto)!
        return perf
    }
    
    
    /// Upload a saved jam to CloudKit
    func upload(performance : ChirpPerformance) {
        // Setup the record
        print("ADCK: Saving the performance:", performance.title())
        let performanceID = CKRecordID(recordName: performance.title())
        let performanceRecord = CKRecord(recordType: PerfCloudKeys.type,recordID: performanceID)
        performanceRecord[PerfCloudKeys.date] = performance.date as CKRecordValue
        performanceRecord[PerfCloudKeys.performer] = performance.performer as CKRecordValue
        performanceRecord[PerfCloudKeys.instrument] = performance.instrument as CKRecordValue
        performanceRecord[PerfCloudKeys.touches] = performance.csv() as CKRecordValue
        performanceRecord[PerfCloudKeys.replyto] = performance.replyto as CKRecordValue
        performanceRecord[PerfCloudKeys.location] = performance.location!
        performanceRecord[PerfCloudKeys.colour] = performance.colourString() as CKRecordValue

        do { // Saving image data
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
        let container = CKContainer.default()
        let publicDatabase = container.publicCloudDatabase
        //        let privateDatabase = container.privateCloudDatabase
        publicDatabase.save(performanceRecord, completionHandler: {(record, error) -> Void in
            if (error != nil) {
                print("ADCK: Error saving to the database.")
                print(error ?? "")
            }
            print("ADCK: Saved to cloudkit:", performance.title()) // runs when upload is complete
        })
    }
        
        
}
