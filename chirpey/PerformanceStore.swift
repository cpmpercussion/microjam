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
    /// Public CloudKit Database
    let publicDB: CKDatabase = CKContainer.default().publicCloudDatabase
    /// Private CloudKit Database
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    /// Delegate to notify when cloud operations are successful.
    var delegate : ModelDelegate?


    /// Loads saved performances and then updates from cloud backend.
    override private init() {
        super.init()
        print("Store: Initialising and loading saved performances.")
        if let savedPerformances = loadPerformances() {
            storedPerformances += savedPerformances
            sortStoredPerformances()
            NSLog("Store: Successfully loaded", storedPerformances.count, "performances")
        } else {
            NSLog("Store: Failed to load performances")
        }
        fetchWorldJamsFromCloud() // get jams from CloudKit
    }

    /// Load Local Performances from file.
    func loadPerformances() -> [ChirpPerformance]? {
        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]
        return loadedPerformances
    }

    /// Add a new performance to the list and then save the list.
    func addNew(performance : ChirpPerformance) {
        self.upload(performance: performance)
    }

    /// Save recorded performances to file.
    func savePerformances() {
        NSLog("Store: Going to save %d performances", self.storedPerformances.count)
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.storedPerformances, toFile: ChirpPerformance.ArchiveURL.path)
        if (!isSuccessfulSave) {
            print("Store: Save was not successful.")
        } else {
            print("Store: successfully saved", self.storedPerformances.count, "performances")
        }
    }

    /// Returns a temporary file path for png images
    static func tempURL() -> URL {
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
        return URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }

    /// Refresh list of world jams from CloudKit and then update in world jam table view.
    func fetchWorldJamsFromCloud() {
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
                    print("Store: Cloud Query error:\(error)")
                    self.delegate?.modelUpdated() // stop spinner
                }
                return
            }
            print("Store: ", fetchedPerformances.count, " performances downloaded.")
            self.addToStored(performances: fetchedPerformances) // update the stored performances
            //self.storedPerformances = fetchedPerformances // update the stored performances
            print("Store: ", self.storedPerformances.count, " total stored performances.")
            DispatchQueue.main.async { // give the delegate the trigger to update the table.
                self.delegate?.modelUpdated()
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
            if !titles.contains(perf.title()) {
                self.storedPerformances.append(perf)
                countPerfsAdded += 1
            }
        }
        print("Store: ", countPerfsAdded, " perfs added to stored performances.")
        self.sortStoredPerformances()
    }

    /// Retrieves a ChirpPerformance from a given title string.
    func fetchPerformanceFrom(title: String) -> ChirpPerformance? {
        var perf: ChirpPerformance?
        for chirpPerformance in self.storedPerformances {
            if (chirpPerformance.title() == title) {
                perf = chirpPerformance
            }
        }
        return perf
    }

    /// Sorts the stored performances by date
    func sortStoredPerformances() {
        self.storedPerformances.sort(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
            rec1.date > rec2.date
        })
    }

    /// Returns a ChirpPerformance from a CKRecord of a performance
    func performanceFrom(record: CKRecord) -> ChirpPerformance? {
        // Initialise the Performance
        guard let perf = ChirpPerformance(fromRecord: record) else {
            print("PerformanceStore: Could not make Performance from CKRecord.")
            return nil
        }
        return perf
    }

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

        do { // Saving image data
            let imageURL = PerformanceStore.tempURL()
            let imageData = UIImagePNGRepresentation(performance.image)!
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
            // todo take the record and add the CreatorID to the performance store's version.
            if let creator_id = record?.creatorUserRecordID {
                DispatchQueue.main.async {
                    // add the creator id to the record
                    performance.creatorID = creator_id
                    self.storedPerformances.insert(performance, at: 0)//
                    self.delegate?.modelUpdated() // stop spinner
                    self.savePerformances()
                }
            }
            
            print("Store: Saved to cloudkit:", performance.title()) // runs when upload is complete
        })
    }
}
