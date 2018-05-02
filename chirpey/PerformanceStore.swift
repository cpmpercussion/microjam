//
//  PerformanceStore.swift
//  microjam
//
//  Created by Charles Martin on 12/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

let performanceStoreUpdatedNotificationKey = "au.com.charlesmartin.performanceStoreUpdatedNotificationKey"
let performanceStoreFailedUpdateNotificationKey = "au.com.charlesmartin.performanceStoreFailedUpdateNotificationKey"

/// Exposes CloudKit container to all UIViewControllers
extension UIViewController {

    /// Default Container (visible to all UIViewControllers)
    var container: CKContainer {
        return CKContainer.default()
    }

}

/// Maximum number of jams to download at a time from CloudKit
let max_jams_to_fetch = 50

/// Classes implementing this protocol have can be notified of success or failure of updates from the `PerformanceStore`'s cloud backend.
protocol ModelDelegate {
    /// Called when the `PerformanceStore` fails to update for some reason.
    func errorUpdating(error: NSError)
    /// Called when the `PerformanceStore` successfully updates from the cloud backend.
    func modelUpdated()

}

/**
 Contains stored performances and handles saving these to the local storage and synchronising with the cloud backend on CloudKit.
*/
class PerformanceStore: NSObject {
    /// Shared Instance (Singleton) of the PerformanceStore initialised on open.
    static let shared = PerformanceStore()
    /// Internally stored performances
    var storedPerformances : [ChirpPerformance] = []
    /// CloudKit database
    let database = CKContainer.default().publicCloudDatabase
    /// Public CloudKit Database
    let publicDB: CKDatabase = CKContainer.default().publicCloudDatabase
    /// Private CloudKit Database
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    /// Delegate to notify when cloud operations are successful.
    var delegate : ModelDelegate?
    /// performances
    var performances: [CKRecordID : ChirpPerformance]
    /// URL of local documents directory.
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    /// URL of storage location
    static let perfDictURL = DocumentsDirectory.appendingPathComponent("performanceStoreDict")
    /// a feed of ChirpPerformances for the world screen generated from stored performances.
    var feed : [ChirpPerformance] = []

    /// Loads saved performances and then updates from cloud backend.
    override private init() {
        performances = PerformanceStore.loadPerformanceDict() // load the performance dictionary
        super.init()
        
        if let savedPerformances = loadPerformances() {
            storedPerformances += savedPerformances
            sortStoredPerformances()
            NSLog("Store: Successfully loaded", storedPerformances.count, "performances")
        } else {
            NSLog("Store: Failed to load performances")
        }
        feed = generateFeed()
        print("PerformanceStore: Feed has \(feed.count) items.")
        fetchWorldJamsFromCloud() // get jams from CloudKit
    }

    /// Load Local Performances from file.
    func loadPerformances() -> [ChirpPerformance]? {
        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]
        return loadedPerformances
    }
    
    /// Load Profiles from file
    private static func loadPerformanceDict() -> [CKRecordID: ChirpPerformance] {
        print("Loading perf dict...")
        let result = NSKeyedUnarchiver.unarchiveObject(withFile: PerformanceStore.perfDictURL.path)
        if let loadedPerformances = result as? [CKRecordID: ChirpPerformance] {
            return loadedPerformances
        } else {
            print("PerformerProfileStore: Failed to load perfs.")
            return [CKRecordID: ChirpPerformance]()
        }
    }

    /// Upload a new performance and add it to the performance store. This only works if the performer is logged in.
    func addNew(performance : ChirpPerformance) {
        self.upload(performance: performance)
        // Add this perf to the model as well.
        if let performersUserRecordID = UserProfile.shared.record?.creatorUserRecordID  {
            print("User is logged in, updating performance info and adding to store.")
            let perfID = CKRecordID(recordName: performance.title())
            performance.performanceID = perfID
            performance.creatorID = performersUserRecordID
            self.performances[perfID] = performance
            DispatchQueue.main.async {
                self.feed = self.generateFeed()
                self.delegate?.modelUpdated() // stop spinner
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
            }
        }
    }

    /// Save recorded performances to file.
    func savePerformances() {
        NSKeyedArchiver.archiveRootObject(performances, toFile: PerformanceStore.perfDictURL.path)
        NSKeyedArchiver.archiveRootObject(self.storedPerformances, toFile: ChirpPerformance.ArchiveURL.path)
    }

    /// Returns a temporary file path for png images
    static func tempURL() -> URL {
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
        return URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }
    
    /// Traverse the performance store's dictionary to create a "feed", or list of relevant jams for the world screen.
    func generateFeed() -> [ChirpPerformance] {
        /// FIXME: is there a more swifty/functional way of doing all this? probably.
        var tempFeed = performances
        let titles = tempFeed.values.map{$0.title()}
        let parentTitles = tempFeed.values.map{$0.replyto}
        
        // remove each parent performance from the dict
        for parent in parentTitles {
            if titles.contains(parent) {
                tempFeed.removeValue(forKey: CKRecordID(recordName: parent))
            }
        }
        // the dict now only contains child (leaf) performances, turn into an array
        var outFeed = Array(tempFeed.values)
        // sort by date
        outFeed.sort(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
                rec1.date > rec2.date
            })
        // done!
        return outFeed
    }
    
    /// Return performances in the store for a given user by CKRecordID
    func performances(byPerformer perfID: CKRecordID) -> [ChirpPerformance] {
        var output = [ChirpPerformance]()
        for perf in storedPerformances {
            if perf.creatorID == perfID {
                output.append(perf)
            }
        }
        return output
    }

    /// Refresh list of world jams from CloudKit and then update in world jam table view.
    @objc func fetchWorldJamsFromCloud() {
        print("Store: Attempting to fetch World Jams from Cloud.")
        var fetchedPerformances = [ChirpPerformance]()
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)
        /// FIXME: predicate should only download latest 100 jams from the last month or something.
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        query.sortDescriptors = [sort]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = max_jams_to_fetch
        operation.recordFetchedBlock = { record in
            if let perf = self.performanceFrom(record: record) {
                fetchedPerformances.append(perf)
            }
        } // Appends fetched records to the array of Performances

        operation.queryCompletionBlock = { [unowned self] (cursor, error) in
            // Handle possible error.
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error: error as NSError)
                    print("Store: Cloud Query error: \(error)")
                }
                return
            }
            print("Store: ", fetchedPerformances.count, " performances downloaded.")
            self.addToStored(performances: fetchedPerformances) // update the stored performances
            self.feed = self.generateFeed()
            print("Store: ", self.storedPerformances.count, " total stored performances.")
            DispatchQueue.main.async { // give the delegate the trigger to update the table.
                self.delegate?.modelUpdated()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
            }
            print("Store: Successfully updated from cloud")
        }

        publicDB.add(operation) // perform the operation.
        // TODO: Define a more sensible way of downloading the performances
    }

    /// Add a list of performances into the currently stored performances.
    func addToStored(performances: [ChirpPerformance]) {
        print("Store: Adding performances to stored list")
        //self.storedPerformances = performances // update the stored performances // old
        let titles = self.storedPerformances.map{$0.title()}
        var countPerfsAdded = 0
        for perf in performances {
            self.performances[CKRecordID(recordName: perf.title())] = perf
            if !titles.contains(perf.title()) {
                self.storedPerformances.append(perf)
                countPerfsAdded += 1
            }
        }
        print("Store: ", countPerfsAdded, " perfs added to stored performances.")
        self.sortStoredPerformances()
    }
    
    /// Return a performance for a given CKRecordID
    func getPerformance(forID recordID: CKRecordID) -> ChirpPerformance? {
        if let performance = performances[recordID] {
            return performance
        } else {
            fetchPerformance(forID: recordID)
            return nil
        }
    }

    /// Fetch a particular performance from CloudKit
    func fetchPerformance(forID recordID: CKRecordID) {
        // This is a low-priority operation.
        database.fetch(withRecordID: recordID) { [unowned self] (record: CKRecord?, error: Error?) in
            if let e = error {
                print("PerformanceStore: Performance Error: \(e)")
            }
            if let rec = record,
                let perf = ChirpPerformance(fromRecord: rec) {
                DispatchQueue.main.async {
                    self.performances[recordID] = perf
                    self.addToStored(performances: [perf])
                    print("PerformanceStore: \(perf.title()) found.")
                    self.delegate?.modelUpdated()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
                }
            }
        }
    }
    
    /// Sorts the stored performances by date
    func sortStoredPerformances() {
        self.storedPerformances.sort(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
            rec1.date > rec2.date
        })
    }
    
    /// Sorts a list of ChirpPerformances by date.
    func sortPerformancesByDate(_ perfs : [ChirpPerformance]) -> [ChirpPerformance] {
        return perfs.sorted(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
            rec1.date > rec2.date
        })
    }
    
}

/// Extension for specific queries
extension PerformanceStore {
    
    /// Fetch performances by a given performer from CloudKit
    func fetchPerformances(byPerformer perfID: CKRecordID) {
        let performerSearchPredicate = NSPredicate(format: "%K == %@", argumentArray: ["creatorUserRecordID", perfID])
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: performerSearchPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { record in
            if let performance = self.performanceFrom(record: record) {
                self.addToStored(performances: [performance])
                DispatchQueue.main.async {
                    print("PerformanceStore: finished loading performer's perfs - model updated.")
                    self.delegate?.modelUpdated()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: performanceStoreUpdatedNotificationKey), object: nil)
                }
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                print("PerformanceStore error:", error)
                return
            }
        }
        
        // perform query operation
        database.add(queryOperation)
    }
    
}

/// Extension for uploading functionality
extension PerformanceStore {
    
    /// Upload a saved jam to CloudKit
    func upload(performance : ChirpPerformance) {
        // Setup the record
        print("Store: Saving the performance:", performance.title())
        let performanceID = CKRecordID(recordName: performance.title())
        let performanceRecord = CKRecord(recordType: PerfCloudKeys.type,recordID: performanceID)
        performanceRecord[PerfCloudKeys.date] = performance.date as CKRecordValue
        performanceRecord[PerfCloudKeys.performer] = performance.performer as CKRecordValue
        performanceRecord[PerfCloudKeys.instrument] = performance.instrument as CKRecordValue
        performanceRecord[PerfCloudKeys.touches] = performance.csv() as CKRecordValue
        performanceRecord[PerfCloudKeys.replyto] = performance.replyto as CKRecordValue
        performanceRecord[PerfCloudKeys.location] = performance.location!
        performanceRecord[PerfCloudKeys.colour] = performance.colourString as CKRecordValue
        performanceRecord[PerfCloudKeys.backgroundColour] = performance.backgroundColourString as CKRecordValue
        
        guard let imageData = UIImagePNGRepresentation(performance.image) else {
            print("PerformanceStore: Blank performance, not able to save.")
            return
        }
        
        do { // Saving image data
            let imageURL = PerformanceStore.tempURL()
            try imageData.write(to: imageURL, options: .atomicWrite)
            let asset = CKAsset(fileURL: imageURL)
            performanceRecord[PerfCloudKeys.image] = asset
        }
        catch {
            print("Store: Error writing image data:", error)
        }
        
        // Upload to the container
        publicDB.save(performanceRecord, completionHandler: {(record, error) -> Void in
            if (error != nil) {
                print("Store: Error saving to the database.")
                print(error ?? "")
            }
            print("Store: Saved to cloudkit:", performance.title()) // runs when upload is complete
        })
    }
}

/// Extension for Parsing Methods
extension PerformanceStore {
    
    /// Returns a ChirpPerformance from a CKRecord of a performance
    func performanceFrom(record: CKRecord) -> ChirpPerformance? {
        // Initialise the Performance
        guard let perf = ChirpPerformance(fromRecord: record) else {
            print("PerformanceStore: Could not make Performance from CKRecord.")
            return nil
        }
        return perf
    }
}
