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
    var profiles: [CKRecord.ID: PerformerProfile]
    /// List of CKRecord.ID currently being fetched
    var currentlyFetching: Set<CKRecord.ID> = []
    /// Special RoboJam Profile
    static let robojamProfile = PerformerProfile(avatar: #imageLiteral(resourceName: "robojam-avatar"), stageName: RoboJamPerfData.performer, jamColour: UIColor(RoboJamPerfData.color), backgroundColour: UIColor(RoboJamPerfData.bg), soundScheme: 1)
    
    private override init() {
        profiles = PerformerProfileStore.loadProfiles()
        super.init()
    }
    
    /// Load Profiles from file
    private static func loadProfiles() -> [CKRecord.ID: PerformerProfile] {
        print("ProfileStore: Loading profiles...")
        let result = NSKeyedUnarchiver.unarchiveObject(withFile: PerformerProfileStore.profilesURL.path)
        
        if let loadedProfiles = result as? [CKRecord.ID: PerformerProfile] {
            print("ProfileStore: Loaded \(loadedProfiles.count) profiles.")
            return loadedProfiles
        } else {
            print("ProfileStore: Failed to load profiles.")
            return [CKRecord.ID: PerformerProfile]()
        }
    }
    
    /// Save Profiles to file.
    func saveProfiles() {
        print("ProfileStore: Saving \(profiles.count) profiles.")
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(profiles, toFile: PerformerProfileStore.profilesURL.path)
        if (!isSuccessfulSave) {
            print("ProfileStore: Save was not successful.")
        } else {
            print("ProfileStore: Save was successful.")
        }
    }
    
    /// Return the profile for a given performance
    func getProfile(forPerformance performance: ChirpPerformance) -> PerformerProfile? {
        guard let creatorID = performance.creatorID else { return nil }
        return getProfile(forID: creatorID)
    }
    
    /// Return a profile for a given user's CKRecordID
    func getProfile(forID performerID: CKRecord.ID) -> PerformerProfile? {
        if let profile = profiles[performerID] {
            // if not fetched this session, fetch anyway, but return the local one as well.
            if !profile.fetchedThisSession { fetchProfile(forID: performerID) }
            return profile
        } else if performerID == RoboJamPerfData.creator {
            return PerformerProfileStore.robojamProfile
        } else {
            fetchProfile(forID: performerID)
            return nil
        }
    }
    
    /// Fetch a profile from CloudKit
    func fetchProfile(forID performerID: CKRecord.ID) {
        if currentlyFetching.contains(performerID) {
            return
            // early return if already fetching a profile.
        }
        // This is a low-priority operation.
        currentlyFetching.insert(performerID)
        database.fetch(withRecordID: performerID) { [unowned self] (record: CKRecord?, error: Error?) in
            if let e = error {
                print("ProfileStore: Profile Error: \(e)")
            }
            if let rec = record,
                let prof = PerformerProfile(fromRecord: rec) {
                DispatchQueue.main.async {
                    prof.fetchedThisSession = true // set fetched this session, so it's not refetched later.
                    self.profiles[performerID] = prof
                    print("ProfileStore: \(prof.stageName)'s profile fetched.")
                    NotificationCenter.default.post(name: .performerProfileUpdated, object: nil)
                }
            }
            DispatchQueue.main.async {self.currentlyFetching.remove(performerID)} // remove this profile ID from the currently fetching set.
        }
    }

}

// Check if UIImage is empty or not.
public extension UIImage {
    
    public var hasContent: Bool {
        return cgImage != nil || ciImage != nil
    }

}

