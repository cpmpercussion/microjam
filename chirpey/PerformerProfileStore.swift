//
//  PerformerProfiles.swift
//  microjam
//
//  Created by Charles Martin on 16/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

class PerformerProfileStore : NSObject {
    /// Shared Instance
    static let shared = PerformerProfileStore()
    /// URL of local documents directory.
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    /// URL of storage location
    static let profilesURL = DocumentsDirectory.appendingPathComponent("performerProfiles")
    /// CloudKit database
    let database = CKContainer.default().publicCloudDatabase
    /// Storage for profiles
    var profiles: [CKRecordID: PerformerProfile]
    /// Storage for delegate conforming to ModelDelegate
    var delegate: ModelDelegate?
    
    private override init() {
        profiles = PerformerProfileStore.loadProfiles()
        super.init()
        // TODO: Need to do some checking for updates in the background
        // TODO: What if there are multiple delegates? Maybe change to NSNotifications
    }
    
    /// Load Profiles from file
    private static func loadProfiles() -> [CKRecordID: PerformerProfile] {
        print("Loading profiles...")
//        var result : Any?
//        do {
//            let dat = try Data(contentsOf: PerformerProfileStore.profilesURL)
//            let unarchiver = NSKeyedUnarchiver(forReadingWith: dat)
//            result = try unarchiver.decodeTopLevelObject()
//            unarchiver.finishDecoding()
//            print("Successfully decoded archive.")
//        } catch let (err) {
//            print("PerformerProfileStore failed to decode archive.")
//            print(err)
//            result = nil
//        }
        
        let result = NSKeyedUnarchiver.unarchiveObject(withFile: PerformerProfileStore.profilesURL.path)
        
        if let loadedProfiles = result as? [CKRecordID: PerformerProfile] {
            print("PerformerProfileStore: Loaded \(loadedProfiles.count) profiles.")
            return loadedProfiles
        } else {
            print("PerformerProfileStore: Failed to load profiles.")
            return [CKRecordID: PerformerProfile]()
        }
    }
    
    /// Save Profiles to file.
    func saveProfiles() {
        print("PerformerProfileStore: Saving \(profiles.count) profiles.")
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(profiles, toFile: PerformerProfileStore.profilesURL.path)
        if (!isSuccessfulSave) {
            print("PerformerProfileStore: Save was not successful.")
        } else {
            print("PerformerProfileStore: Save was successful.")
        }
    }
    
    /// Return the profile for a given performance
    func getProfile(forPerformance performance: ChirpPerformance) -> PerformerProfile? {
        guard let creatorID = performance.creatorID else { return nil }
        return getProfile(forID: creatorID)
    }
    
    /// Return a profile for a given user's CKRecordID
    func getProfile(forID performerID: CKRecordID) -> PerformerProfile? {
        if let profile = profiles[performerID] {
            return profile
        } else {
            fetchProfile(forID: performerID)
            return nil
        }
    }
    
    /// Fetch a profile from CloudKit
    func fetchProfile(forID performerID: CKRecordID) {
        // This is a low-priority operation.
        database.fetch(withRecordID: performerID) { [unowned self] (record: CKRecord?, error: Error?) in
            if let e = error {
                print("PerformerProfileStore: Profile Error: \(e)")
            }
            if let rec = record,
                let prof = PerformerProfile(fromRecord: rec) {
                DispatchQueue.main.async {
                    self.profiles[performerID] = prof
                    print("PerformerProfileStore: \(prof.stageName)'s profile found.")
                    self.delegate?.modelUpdated()
                }
            }
        }
    }
    
}