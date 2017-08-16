//
//  PerformerProfiles.swift
//  microjam
//
//  Created by Charles Martin on 16/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

//extension PerformerProfileStore : NSKeyedUnarchiverDelegate {
//    // This class is placeholder for unknown classes.
//    // It will eventually be `nil` when decoded.
//    final class Unknown: NSObject, NSCoding  {
//        init?(coder aDecoder: NSCoder) { super.init(); return nil }
//        func encode(with aCoder: NSCoder) {}
//    }
//
//    func unarchiver(_ unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
//        return Unknown.self
//    }
//}

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
    var profiles: [CKRecordID: PerformerProfile] = PerformerProfileStore.loadProfiles()
    /// Storage for delegate conforming to ModelDelegate
    var delegate: ModelDelegate?
    
    private override init() {
        super.init()
        // TODO: Need to do some checking for updates in the background
        // TODO: What if there are multiple delegates? Maybe change to NSNotifications
    }
    
    /// Load Profiles from file
    static func loadProfiles() -> [CKRecordID: PerformerProfile] {

        guard let dat = NSData(contentsOf: PerformerProfileStore.profilesURL) else {
            print("PerformerProfilesStore: No archive found.")
            return [CKRecordID: PerformerProfile]()
        }

        let unarchiver = NSKeyedUnarchiver(forReadingWith: dat as Data)
        var result : Any?
        do {
            try result = unarchiver.decodeTopLevelObject()
        } catch {
            print("PerformerProfileStore: Error decoding archive.")
            result = nil
        }

        if let loadedProfiles = result as? [CKRecordID: PerformerProfile] {
            print("PerformerProfileStore: Loaded Profiles.")
            return loadedProfiles
        } else {
            print("PerformerProfileStore: Failed to load profiles.")
            return [CKRecordID: PerformerProfile]()
        }
    }
    
    /// Save Profiles to file.
    func saveProfiles() {
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
            if let rec = record {
                print("PerformerProfileStore: Profile Found.")
                DispatchQueue.main.async {
                    self.profiles[performerID] = PerformerProfile(fromRecord: rec)
                    self.delegate?.modelUpdated()
                }
            }
        }
    }
    
}
