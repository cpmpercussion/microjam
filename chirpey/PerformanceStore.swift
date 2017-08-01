//
//  PerformanceStore.swift
//  microjam
//
//  Created by Charles Martin on 12/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// Maximum number of jams to download at a time from CloudKit
let max_jams_to_fetch = 25

/// Classes implementing this protocol have can be notified of success or failure of updates from the `PerformanceStore`'s cloud backend.
protocol ModelDelegate {
<<<<<<< HEAD

    /// Called when the `PerformanceStore` fails to update for some reason.
    func errorUpdating(error: NSError)

=======
    
    /// Called when the `PerformanceStore` fails to update for some reason.
    func errorUpdating(error: NSError)
    
>>>>>>> origin/adding-store-to-mvc
    /// Called when the `PerformanceStore` successfully updates from the cloud backend.
    func modelUpdated()
}

<<<<<<< HEAD
/**
 Contains stored performances and handles saving these to the local storage and synchronising with the cloud backend on CloudKit.
*/
class PerformanceStore: NSObject {

    var storedPerformances : [ChirpPerformance] = []

    // MARK: - CloudKit definitions

=======
/** 
 Contains stored performances and handles saving these to the local storage and synchronising with the cloud backend on CloudKit.
*/
class PerformanceStore: NSObject {
    
    var storedPerformances : [ChirpPerformance] = []
    
    // MARK: - CloudKit definitions
    
>>>>>>> origin/adding-store-to-mvc
    let container: CKContainer = CKContainer.default()
    let publicDB: CKDatabase = CKContainer.default().publicCloudDatabase
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    var delegate : ModelDelegate?
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
    /// Loads saved performances and then updates from cloud backend.
    override init() {
        super.init()
        if let savedPerformances = loadPerformances() {
            storedPerformances += savedPerformances
            sortStoredPerformances()
            NSLog("AD: Successfully loaded", storedPerformances.count, "performances")
        } else {
            NSLog("AD: Failed to load performances")
        }
        fetchWorldJamsFromCloud() // get jams from CloudKit
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
    /// Load Local Performances from file.
    func loadPerformances() -> [ChirpPerformance]? {
        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]
        return loadedPerformances
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
    /// Add a new performance to the list and then save the list.
    func addNew(performance : ChirpPerformance) {
        self.storedPerformances.insert(performance, at: 0)//
        self.savePerformances()
        self.upload(performance: performance)
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
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
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
    /// Returns a temporary file path for png images
    func tempURL() -> URL {
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
        return URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
    /// Refresh list of world jams from CloudKit and then update in world jam table view.
    func fetchWorldJamsFromCloud() {
        print("ADCK: Attempting to fetch World Jams from Cloud.")
        print("ADCK: Container is: ", container)
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
<<<<<<< HEAD

=======
        
>>>>>>> origin/adding-store-to-mvc
        operation.queryCompletionBlock = { [unowned self] (cursor, error) in
            // Handle possible error.
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error: error as NSError)
                    print("ADCK: Cloud Query error:\(error)")
                    self.delegate?.modelUpdated() // stop spinner
                }
                return
            }
            print("ADCK: ", fetchedPerformances.count, " performances downloaded.")
            self.addToStored(performances: fetchedPerformances) // update the stored performances
            //self.storedPerformances = fetchedPerformances // update the stored performances
            print("ADCK: ", self.storedPerformances.count, " total world jams.")
            DispatchQueue.main.async { // give the delegate the trigger to update the table.
                self.delegate?.modelUpdated()
            }
        }
<<<<<<< HEAD

        publicDB.add(operation) // perform the operation.
        // TODO: Define a more sensible way of downloading the performances
    }

=======
        
        publicDB.add(operation) // perform the operation.
        // TODO: Define a more sensible way of downloading the performances
    }
    
>>>>>>> origin/adding-store-to-mvc
    /// Add a list of performances into the currently stored performances.
    func addToStored(performances: [ChirpPerformance]) {
        print("ADCK: Adding performances to stored list")
        //self.storedPerformances = performances // update the stored performances // old
        let titles = self.storedPerformances.map{$0.title()}
        var countPerfsAdded = 0
        for perf in performances {
            if !titles.contains(perf.title()) {
                self.storedPerformances.append(perf)
                countPerfsAdded += 1
            }
        }
        print("ADCK: ", countPerfsAdded, " perfs added to stored world jams.")
        self.sortStoredPerformances()
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
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
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
    /// Sorts the stored performances by date
    func sortStoredPerformances() {
        self.storedPerformances.sort(by: {(rec1: ChirpPerformance, rec2: ChirpPerformance) -> Bool in
            rec1.date > rec2.date
        })
    }
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
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
<<<<<<< HEAD

=======
    
>>>>>>> origin/adding-store-to-mvc
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
<<<<<<< HEAD

=======
        
>>>>>>> origin/adding-store-to-mvc
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
<<<<<<< HEAD

=======
        
>>>>>>> origin/adding-store-to-mvc
        // Upload to the container
        publicDB.save(performanceRecord, completionHandler: {(record, error) -> Void in
            if (error != nil) {
                print("ADCK: Error saving to the database.")
                print(error ?? "")
            }
            print("ADCK: Saved to cloudkit:", performance.title()) // runs when upload is complete
        })
    }
}