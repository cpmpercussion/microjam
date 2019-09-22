//
//  PerformanceStore.swift
//  microjam
//
//  Created by Charles Martin on 12/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit


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
    var performances: [CKRecord.ID : ChirpPerformance]
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
            NSLog("PerfStore: Successfully loaded", storedPerformances.count, "performances")
        } else {
            NSLog("PerfStore: Failed to load performances")
        }
        feed = generateFeed()
        print("PerfStore: Feed has \(feed.count) items.")
        fetchWorldJamsFromCloud() // get jams from CloudKit
    }

    /// Load Local Performances from file.
    func loadPerformances() -> [ChirpPerformance]? {
        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]
        return loadedPerformances
    }
    
    /// Load Profiles from file
    private static func loadPerformanceDict() -> [CKRecord.ID: ChirpPerformance] {
        print("PerfStore: Loading performance dict...")
        let result = NSKeyedUnarchiver.unarchiveObject(withFile: PerformanceStore.perfDictURL.path)
        if let loadedPerformances = result as? [CKRecord.ID: ChirpPerformance] {
            return loadedPerformances
        } else {
            print("PerfStore: Failed to load perfs.")
            return [CKRecord.ID: ChirpPerformance]()
        }
    }

    /// Upload a new performance and add it to the performance store. This only works if the performer is logged in.
    func addNew(performance : ChirpPerformance) {
        self.upload(performance: performance)
        // Add this perf to the model as well.
        //print("User is logged in, updating performance info and adding to store.")
        let perfID = CKRecord.ID(recordName: performance.title())
        performance.performanceID = perfID
        if let performersUserRecordID = UserProfile.shared.record?.creatorUserRecordID  {
            performance.creatorID = performersUserRecordID
        }
        self.performances[perfID] = performance
        DispatchQueue.main.async {
            self.feed = self.generateFeed()
            self.delegate?.modelUpdated() // stop spinner
            NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
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
        print("PerfStore: starting generate Feed.")
        let startDate = Date.init()
        /// FIXME: is there a more swifty/functional way of doing all this? probably.
        var tempFeed = performances
        let titles = tempFeed.values.map{$0.title()}
        let parentTitles = tempFeed.values.map{$0.replyto}
        
        // remove each parent performance from the dict
        for parent in parentTitles {
            if titles.contains(parent) {
                tempFeed.removeValue(forKey: CKRecord.ID(recordName: parent))
            }
        }
        // the dict now only contains child (leaf) performances, turn into an array
        var outFeed = Array(tempFeed.values)
        // sort by date
        outFeed.sort(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
                rec1.date > rec2.date
            })
        // done!
        print("PerfStore: Time taken for generateFeed:", -startDate.timeIntervalSinceNow)
        return outFeed
    }
    
    /// Return performances in the store for a given user by CKRecordID
    func performances(byPerformer perfID: CKRecord.ID) -> [ChirpPerformance] {
        var output = [ChirpPerformance]()
        for perf in storedPerformances {
            if perf.creatorID == perfID {
                output.append(perf)
            }
        }
        return output
    }



    /// Add a list of performances into the currently stored performances.
    func addToStored(performances: [ChirpPerformance]) {
        //print("Store: Adding performances to stored list")
        //self.storedPerformances = performances // update the stored performances // old
        let titles = self.storedPerformances.map{$0.title()}
        var countPerfsAdded = 0
        for perf in performances {
            if let perfID = perf.performanceID {
                self.performances[perfID] = perf
            }
            
            // self.performances[CKRecordID(recordName: perf.title())] = perf
            /// TODO: Remove this bit.
            if !titles.contains(perf.title()) {
                self.storedPerformances.append(perf)
                countPerfsAdded += 1
            }
        }
        //print("Store: ", countPerfsAdded, " perfs added to stored performances.")
        self.sortStoredPerformances()
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

// MARK: - Fetching Operations

/// Extension for specific queries
extension PerformanceStore {
    
    /// Refresh list of world jams from CloudKit and then update in world jam table view.
    @objc func fetchWorldJamsFromCloud() {
        print("PerfStore: Attempting to fetch World Jams from Cloud.")
        //var fetchedPerformances = [ChirpPerformance]()
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)
        /// FIXME: predicate should only download latest 100 jams from the last month or something.
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        query.sortDescriptors = [sort]
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = max_jams_to_fetch
        operation.desiredKeys = [PerfCloudKeys.date, PerfCloudKeys.instrument, PerfCloudKeys.instrument, PerfCloudKeys.location, PerfCloudKeys.performer, PerfCloudKeys.replyto, PerfCloudKeys.touches, PerfCloudKeys.colour, PerfCloudKeys.backgroundColour, PerfCloudKeys.createdBy] // leaving out PerfCloudKeys.image
        
        operation.recordFetchedBlock = { record in
            if let perf = self.performanceFrom(record: record) {
                DispatchQueue.main.async {
                    //print("PerfStore: Downloaded a record.")
                    self.performances[record.recordID] = perf
                    //fetchedPerformances.append(perf)
                    NotificationCenter.default.post(name: .performanceStorePerfAdded, object: nil)
                }
            }
        } // Appends fetched records to the array of Performances

        operation.queryCompletionBlock = { [unowned self] (cursor, error) in
            // Handle possible error.
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error: error as NSError)
                    print("PerfStore: Cloud Query error: \(error)")
                }
                return
            }
            //print("PerfStore: downloaded", fetchedPerformances.count)
            //self.addToStored(performances: fetchedPerformances) // update the stored performances
            DispatchQueue.main.async { // give the delegate the trigger to update the table.
                self.feed = self.generateFeed()
                self.delegate?.modelUpdated()
                NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
            }
            print("PerfStore: Successfully updated from cloud")
        }
        
        print("PerfStore: About to start updating performances")
        publicDB.add(operation) // perform the operation.
        print("PerfStore: Download operation added.")
        // TODO: Define a more sensible way of downloading the performances
    }
    
    /// Return a performance for a given CKRecordID
    func getPerformance(forID recordID: CKRecord.ID) -> ChirpPerformance? {
        if let performance = performances[recordID] {
            return performance
        } else {
            fetchPerformance(forID: recordID)
            return nil
        }
    }

    /// Fetch a particular performance from CloudKit
    func fetchPerformance(forID recordID: CKRecord.ID) {
        // This is a low-priority operation.
        database.fetch(withRecordID: recordID) { [unowned self] (record: CKRecord?, error: Error?) in
            if let e = error {
                print("PerfStore: Error fetching performance: \(recordID): \(e)")
            }
            if let rec = record,
                let perf = ChirpPerformance(fromRecord: rec) {
                DispatchQueue.main.async {
                    self.performances[recordID] = perf
                    self.addToStored(performances: [perf])
                    print("PerfStore: \(perf.title()) found.")
                    self.delegate?.modelUpdated()
                    NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
                }
            }
        }
    }
    
    /// Fetch the Image for a given performance.
    func fetchImageFor(performance recordID: CKRecord.ID) {
        database.fetch(withRecordID: recordID) { [unowned self] (record: CKRecord?, error: Error?) in
            if let e = error {
                print("PerfStore: Error fetching image for perf: \(recordID): \(e)")
            }
            if let record = record,
                let imageAsset = record.object(forKey: PerfCloudKeys.image) as? CKAsset,
                let image = UIImage(contentsOfFile: imageAsset.fileURL!.path)
            {
                DispatchQueue.main.async {
                    self.performances[recordID]?.image = image
                    self.delegate?.modelUpdated()
                    NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
                }
                
            }
        }
    }
    
    /// Fetch the image for a given performance and assign it to a given ChirpView. (use this one)
    func fetchImageFor(performance recordID: CKRecord.ID, andAssignTo chirpView: ChirpView) {
        database.fetch(withRecordID: recordID) { [unowned self] (record: CKRecord?, error: Error?) in
            if let record = record,
                let imageAsset = record.object(forKey: PerfCloudKeys.image) as? CKAsset,
                let image = UIImage(contentsOfFile: imageAsset.fileURL!.path) {
                DispatchQueue.main.async {
                    // update performance in store.
                    self.performances[recordID]?.image = image
                    // update view
                    chirpView.image = image
                }
            }
        }
    }
    
    /// Fetch performances by a given performer from CloudKit
    func fetchPerformances(byPerformer perfID: CKRecord.ID) {
        let performerSearchPredicate = NSPredicate(format: "%K == %@", argumentArray: ["creatorUserRecordID", perfID])
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: performerSearchPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { record in
            if let performance = self.performanceFrom(record: record) {
                self.addToStored(performances: [performance])
                DispatchQueue.main.async {
                    // NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
                    // could notify delegate here - but triggers too many times.
                }
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                print("PerfStore: error:", error)
                return
            } else {
                print("PerfStore: finished loading perfs for", perfID)
                NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
                DispatchQueue.main.async {
                    self.delegate?.modelUpdated()
                }
            }
        }
        
        // perform query operation
        database.add(queryOperation)
    }
    
    /// Retrieve all the replies for a given performance from the performance store and iCloud.
    func getAllReplies(forPerformance performance: ChirpPerformance) -> [ChirpPerformance] {
        var output = [ChirpPerformance]()
        output.append(performance) // add the top performance.
        var current = performance
        while current.replyto != "" {
            // Check if the reply is available in the performanceStore
            if let next = getPerformance(forID: CKRecord.ID(recordName: current.replyto)) {
                output.append(next)
                current = next
            } else {
                // Try to find the relevant reply and add to the store. - this is low priority and will update later.
                fetchPerformance(forID: CKRecord.ID(recordName: current.replyto))
                break
            }
        }
        return output
    }
    
}

// MARK: - Uploading

/// Extension for uploading functionality
extension PerformanceStore {
    
    /// Upload a saved jam to CloudKit
    func upload(performance : ChirpPerformance) {
        // Setup the record
        print("PerfStore: Saving the performance:", performance.title())
        let performanceID = CKRecord.ID(recordName: performance.title())
        let performanceRecord = CKRecord(recordType: PerfCloudKeys.type,recordID: performanceID)
        performanceRecord[PerfCloudKeys.date] = performance.date as CKRecordValue
        performanceRecord[PerfCloudKeys.performer] = performance.performer as CKRecordValue
        performanceRecord[PerfCloudKeys.instrument] = performance.instrument as CKRecordValue
        performanceRecord[PerfCloudKeys.touches] = performance.csv() as CKRecordValue
        performanceRecord[PerfCloudKeys.replyto] = performance.replyto as CKRecordValue
        performanceRecord[PerfCloudKeys.location] = performance.location!
        performanceRecord[PerfCloudKeys.colour] = performance.colourString as CKRecordValue
        performanceRecord[PerfCloudKeys.backgroundColour] = performance.backgroundColourString as CKRecordValue
        
        guard let image = performance.image,
            let imageData = image.pngData() else {
            print("PerfStore: Blank performance, not able to save.")
            return
        }
        
        do { // Saving image data
            let imageURL = PerformanceStore.tempURL()
            try imageData.write(to: imageURL, options: .atomicWrite)
            let asset = CKAsset(fileURL: imageURL)
            performanceRecord[PerfCloudKeys.image] = asset
        }
        catch {
            print("PerfStore: Error writing image data:", error)
        }
        
        // Upload to the container
        publicDB.save(performanceRecord, completionHandler: {(record, error) -> Void in
            if (error != nil) {
                print("PerfStore: Error saving to the database.")
                print(error ?? "")
            }
            print("PerfStore: Saved to cloudkit:", performance.title()) // runs when upload is complete
        })
    }
}

// MARK: - Deleting

extension PerformanceStore {

    /// Removes a performances from the local store by CKRecordID
    func removePerformanceFromStore(withID recordID: CKRecord.ID) {
        // Remove from the dictionary version
        performances.removeValue(forKey: recordID)
        // Remove from the array version
        if let index = storedPerformances.firstIndex(where: { (performance) -> Bool in
            performance.performanceID == recordID
        }) {
            storedPerformances.remove(at: index)
        }
    }

    /// Delete a performance from the database and local store by CKRecord ID. Only works for performances owned by the user.
    func deleteUserPerformance(withID recordID: CKRecord.ID) {
        print("PerfStore: Starting Deletion Operation.")
        // remove from database
        database.delete(withRecordID: recordID, completionHandler: { (record, error) in
            print("PerfStore: Deletion operation complete")
            if let error = error {
                print("PerfStore: Deletion failed:", error)
            } else {
                print("PerfStore: Deletion was successful, updating")
                self.removePerformanceFromStore(withID: recordID)
                NotificationCenter.default.post(name: .performanceStoreUpdated, object: nil)
                DispatchQueue.main.async {
                    self.delegate?.modelUpdated()
                }
            }
        })
    }
}

// MARK: - Parsing

/// Extension for Parsing Methods
extension PerformanceStore {
    
    /// Returns a ChirpPerformance from a CKRecord of a performance
    func performanceFrom(record: CKRecord) -> ChirpPerformance? {
        // Initialise the Performance
        guard let perf = ChirpPerformance(fromRecord: record) else {
            print("PerfStore: Could not make Performance from CKRecord.")
            return nil
        }
        return perf
    }
}
