//
//  UserProfile.swift
//  microjam
//
//  Created by Charles Martin on 3/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

let userProfileUpdatedNotificationKey = "au.com.charlesmartin.userProfileUpdatedNotificationKey"

/// Singleton class to hold the logged-in user's profile.
class UserProfile: NSObject {
    /// Shared instance (singleton) of the user's PerformerProfile
    static let shared = UserProfile()
    /// Maximum width of avatar image.
    static let avatarWidth: CGFloat = 200
    /// URL of local documents directory.
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    /// UserProfile storage location.
    static let profileURL = DocumentsDirectory.appendingPathComponent("userProfile")
    /// CloudKit Container
    let container = CKContainer.default()
    /// Records whether user is logged in or not.
    var loggedIn = false
    /// CKRecord of user information.
    var record: CKRecord? {
        didSet {
            assignFromRecord()
        }
    }
    /// Storage for user's performer profile.
    var profile: PerformerProfile = UserProfile.loadProfile()
    
    // MARK: Initialisers
    
    /// Designated initialiser is private as this is a singleton.
    private override init() {
        // TODO: this should be loaded up from an NSCoder most likely!
        super.init()
        // Look up performer profile.
        
        //fetchUserRecordID() // fetch the cloudkit record and populate fields properly.
        NotificationCenter.default.addObserver(self, selector: #selector(discoverCloudAccountStatus), name: Notification.Name.CKAccountChanged, object: nil)
        discoverCloudAccountStatus() // start account discovery, populates fields as available
    }
    
    /// Load UserProfile from file.
    static func loadProfile() -> PerformerProfile {
        if let loadedProfile =  NSKeyedUnarchiver.unarchiveObject(withFile: UserProfile.profileURL.path) as? PerformerProfile {
            return loadedProfile
        } else {
            return PerformerProfile()
        }
    }
    
    /// Save UserProfile to file.
    func saveProfile() {
        NSLog("UserProfile: Going to save profile")
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(profile, toFile: UserProfile.profileURL.path)
        if (!isSuccessfulSave) {
            print("UserProfile: Save was not successful.")
        } else {
            print("UserProfile: Save was successful.")
        }
    }
    
    // MARK: Discovery Methods
    
    /// Used to discover if user is logged into iCloud or not and display appropriate views.
    @objc private func discoverCloudAccountStatus() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Error doing CloudKit Discovery
                    print("UserProfile: Error dicovering profile: \(error)")
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                } else {
                    switch status {
                    case .available:
                        // logged in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        print("UserProfile: iCloud is available")
                        self.fetchUserRecordID()
                        self.loggedIn = true
                    case .couldNotDetermine, .noAccount, .restricted:
                        // not logged in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        print("UserProfile: iCloud is not available")
                        self.loggedIn = false
                    }
                }
            }
        }
    }
    
    /// Fetches the user's user record ID.
    private func fetchUserRecordID() {
        container.fetchUserRecordID { recordID, error in
            guard let recordID = recordID, error == nil else {
                // TODO: fill in error handling.
                print("UserProfile: Error: User record ID not found.")
                return
            }
            
            DispatchQueue.main.async {
                print("USVC: Found user: \(recordID.recordName). Discovering info.")
                self.fetchUserRecord(with: recordID) // get the user record.
                self.discoverIdentity(for: recordID)
                self.discoverFriends()
            }
        }
    }
    
    /// fetches the user's record on CloudKit
    private func fetchUserRecord(with recordID: CKRecordID) {
        container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            guard let record = record, error == nil else {
                // TODO: error handling.
                print("UserProfile: Error: User record not found.")
                return
            }
            
            DispatchQueue.main.async {
                print("UserProfile: Found user record, notifying.")
                self.record = record
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: userProfileUpdatedNotificationKey), object: nil)
                
            }
        }
    }
    
    /// Look up the user's name and other details on CloudKit
    private func discoverIdentity(for recordID: CKRecordID) {
        container.requestApplicationPermission(.userDiscoverability) { status, error in
            guard status == .granted, error == nil else {
                // TODO: error handling.
                DispatchQueue.main.async {
                    print("UserProfile: Not authorised to show user's name.")
                }
                return
            }
            
            self.container.discoverUserIdentity(withUserRecordID: recordID) { identity, error in
                defer {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
            }
        }
    }
    
    /// Look up users contacts who also have microjam records.
    private func discoverFriends() {
        container.discoverAllIdentities { identities, error in
            guard let identities = identities, error == nil else {
                // TODO: error handling.
                return
            }
            print("UserProfile: User has \(identities.count) contact(s) using the app:")
        }
    }
    
    /// Update fields from User's CKRecord:
    private func assignFromRecord() {
        if let record = record {
            // User Record Found, extract user data to display
            var cloudNeedsUpdating = false
            // Avatar
            if let avatarPath = record[UserCloudKeys.avatar] as? CKAsset,
                let avatarImage = UIImage(contentsOfFile: avatarPath.fileURL.path) {
                profile.avatar = avatarImage
                print("UserProfile: Avatar found on Cloudkit.")
            } else {
                // Generate temporary avatar image
                if let avatarImage = PerformerProfile.randomUserAvatar() {
                    profile.avatar = avatarImage
                    print("UserProfile: New avatar generated")
                    cloudNeedsUpdating = true
                }
            }
            
            // Stage Name
            if let name = record[UserCloudKeys.stagename] as? String {
                profile.stageName = name
                print("UserProfile: Stagename found on Cloudkit.")
                if name.isEmpty || name == "Performer" {
                    let genName = PerformerProfile.randomPerformerName()
                    profile.stageName = genName
                    print("UserProfile: New stagename generated: ", name)
                    cloudNeedsUpdating = true
                }
            } else {
                // Generate random stagename
                let name = PerformerProfile.randomPerformerName()
                profile.stageName = name
                print("UserProfile: New stagename generated: ", name)
                cloudNeedsUpdating = true
            }
            
            // Jam Colour
            if let jamHex = record[UserCloudKeys.jamColour] as? String {
                profile.jamColour = UIColor(jamHex)
                print("UserProfile: jam colour found on Cloudkit.")
            } else {
                let jamHue = UserDefaults.standard.float(forKey: SettingsKeys.performerColourKey)
                profile.jamColour = UIColor(hue: CGFloat(jamHue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                print("UserProfile: jam colour found in user defaults.")
                cloudNeedsUpdating = true
            }
            
            // BG Colour
            if let bgHex = record[UserCloudKeys.backgroundColour] as? String {
                profile.backgroundColour = UIColor(bgHex)
                print("UserProfile: bg colour found on Cloudkit.")
            } else {
                let bgHue = UserDefaults.standard.float(forKey: SettingsKeys.backgroundColourKey)
                profile.backgroundColour = UIColor(hue: CGFloat(bgHue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                print("UserProfile: bg colour found in UserDefaults.")
                cloudNeedsUpdating = true
            }
            
            // SoundScheme
            if let scheme = record[UserCloudKeys.soundScheme] as? Int64 {
                profile.soundScheme = scheme
                print("UserProfile: soundscheme found on Cloudkit.")
            } else {
                let scheme = UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)
                profile.soundScheme = Int64(scheme)
                print("UserProfile: soundscheme found in userdefaults.")
                cloudNeedsUpdating = true
            }
            
            if (cloudNeedsUpdating) {
                updateUserProfile()
            }
        } else {
            print("UserProfile: Error: User record does not exist!")
        }
    }

    // MARK: Update Methods

    /// Update avatar image in record and sends to cloudkit
    func updateAvatar(_ image: UIImage) {
        // resize image
        print("UserProfile: resizing avatar to:", UserProfile.avatarWidth)
        guard let newImage = image.scaleImage(toWidth: UserProfile.avatarWidth) else {
            print("UserProfile: Could not resize avatar")
            return
        }
        guard let record = self.record else {
            print("UserProfile: Error: User record not initialised")
            return
        }
        
        profile.avatar = newImage // set the new avatar
        
        do { // Saving image data
            let imageURL = PerformanceStore.tempURL()
            let imageData = UIImagePNGRepresentation(newImage)!
            try imageData.write(to: imageURL, options: .atomicWrite)
            let asset = CKAsset(fileURL: imageURL)
            record[UserCloudKeys.avatar] = asset
        }
        catch {
            print("UserProfile: Error writing image data:", error)
        }
        updateUserProfile()
    }
    
    /// Update basic profile info in CloudKit (stagename, colours, and soundscheme)
    /// Does not update avatar image.
    internal func updateUserProfile() {
        guard let record = self.record else {
            print("UserProfile: Error: User record not initialised")
            return
        }
        
        record[UserCloudKeys.stagename] = profile.stageName as CKRecordValue
        record[UserCloudKeys.jamColour] = profile.jamColour.hexString() as CKRecordValue
        record[UserCloudKeys.backgroundColour] = profile.backgroundColour.hexString() as CKRecordValue
        record[UserCloudKeys.soundScheme] = profile.soundScheme as CKRecordValue
        container.publicCloudDatabase.save(record) { _, error in
            if (error != nil) {
                print("UserProfile: Error saving to cloudkit")
                print(error ?? "")
            } else {
                print("UserProfile: updated user profile in cloudkit.")
            }
        }

        // update user defaults
        // FIXME: use of userdefaults should be deprecated.
        UserDefaults.standard.set(profile.stageName, forKey: SettingsKeys.performerKey)
        UserDefaults.standard.set(PerformerProfile.hueFrom(colour: profile.jamColour), forKey: SettingsKeys.performerColourKey)
        UserDefaults.standard.set(PerformerProfile.hueFrom(colour: profile.backgroundColour), forKey: SettingsKeys.backgroundColourKey)
        UserDefaults.standard.set(profile.soundScheme, forKey: SettingsKeys.soundSchemeKey)
    }
}


// Some image scaling suggestions from https://stackoverflow.com/questions/31966885/ios-swift-resize-image-to-200x200pt-px
extension UIImage {

    /// scales UIImages to a given size.
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        // thx to Travis M.'s answer https://stackoverflow.com/a/34599236/1646138
        print("UserProfile Resizing to:", newSize.width, "by", newSize.height)
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.interpolationQuality = .high
        self.draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // Scale image just specifying width.
    func scaleImage(toWidth width: CGFloat) -> UIImage? {
        let scale = width / self.size.width
        let height = self.size.height * scale
        let newSize = CGSize(width: width, height: height)
        return scaleImage(toSize: newSize)
    }
}
