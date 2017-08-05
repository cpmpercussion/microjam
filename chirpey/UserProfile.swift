//
//  UserProfile.swift
//  microjam
//
//  Created by Charles Martin on 3/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// Singleton class to hold the logged-in user's profile.
class UserProfile: PerformerProfile {
    /// Shared instance (singleton) of the user's PerformerProfile
    static let shared = UserProfile()
    /// Maximum width of avatar image.
    static let avatarWidth: CGFloat = 200
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
    
    // MARK: Initialisers
    
    /// Designated initialiser is private as this is a singleton.
    private init() {
        // TODO: this should be loaded up from an NSCoder most likely!
        super.init(avatar: UIImage(), stageName: "", jamColour: UIColor.blue, backgroundColour: UIColor.clear, soundScheme: 1)
        //fetchUserRecordID() // fetch the cloudkit record and populate fields properly.
        NotificationCenter.default.addObserver(self, selector: #selector(discoverCloudAccountStatus), name: Notification.Name.CKAccountChanged, object: nil)
        discoverCloudAccountStatus() // start account discovery, populates fields as available
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
                print("UserProfile: Found user record.")
                self.record = record
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
                avatar = avatarImage
                print("UserProfile: Avatar found on Cloudkit.")
            }
            
            // Stage Name
            if let name = record[UserCloudKeys.stagename] as? String {
                stageName = name
                print("UserProfile: Stagename found on Cloudkit.")
            } else if let name = UserDefaults.standard.string(forKey: SettingsKeys.performerKey) {
                stageName = name
                print("UserProfile: Stagename found in UserDefaults (updating in cloud)")
                cloudNeedsUpdating = true
            }
            
            // Jam Colour
            if let jamHex = record[UserCloudKeys.jamColour] as? String {
                jamColour = UIColor(jamHex)
                print("UserProfile: jam colour found on Cloudkit.")
            } else {
                let jamHue = UserDefaults.standard.float(forKey: SettingsKeys.performerColourKey)
                jamColour = UIColor(hue: CGFloat(jamHue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                print("UserProfile: jam colour found in user defaults.")
                cloudNeedsUpdating = true
            }
            
            // BG Colour
            if let bgHex = record[UserCloudKeys.backgroundColour] as? String {
                backgroundColour = UIColor(bgHex)
                print("UserProfile: bg colour found on Cloudkit.")
            } else {
                let bgHue = UserDefaults.standard.float(forKey: SettingsKeys.backgroundColourKey)
                backgroundColour = UIColor(hue: CGFloat(bgHue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
                print("UserProfile: bg colour found in UserDefaults.")
                cloudNeedsUpdating = true
            }
            
            // SoundScheme
            if let scheme = record[UserCloudKeys.soundScheme] as? Int64 {
                soundScheme = scheme
                print("UserProfile: soundscheme found on Cloudkit.")
            } else {
                let scheme = UserDefaults.standard.integer(forKey: SettingsKeys.soundSchemeKey)
                soundScheme = Int64(scheme)
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
        
        avatar = newImage // set the new avatar
        
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
        if let record = self.record {
            record[UserCloudKeys.stagename] = stageName as CKRecordValue
            record[UserCloudKeys.jamColour] = jamColour.hexString() as CKRecordValue
            record[UserCloudKeys.backgroundColour] = backgroundColour.hexString() as CKRecordValue
            record[UserCloudKeys.soundScheme] = soundScheme as CKRecordValue
            container.publicCloudDatabase.save(record) { _, error in
                if (error != nil) {
                    print("UserProfile: Error saving to cloudkit")
                    print(error ?? "")
                } else {
                    print("UserProfile: updated user profile in cloudkit.")
                }
            }
        }

        // update user defaults
        // FIXME: use of userdefaults should be deprecated.
        UserDefaults.standard.set(stageName, forKey: SettingsKeys.performerKey)
        UserDefaults.standard.set(PerformerProfile.hueFrom(colour: jamColour), forKey: SettingsKeys.performerColourKey)
        UserDefaults.standard.set(PerformerProfile.hueFrom(colour: backgroundColour), forKey: SettingsKeys.backgroundColourKey)
        UserDefaults.standard.set(soundScheme, forKey: SettingsKeys.soundSchemeKey)
    }
}


// Some image scaling suggestions from https://stackoverflow.com/questions/31966885/ios-swift-resize-image-to-200x200pt-px
extension UIImage {

    /// scales UIImages to a given size.
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        // thx to Travis M.'s answer https://stackoverflow.com/a/34599236/1646138
        print("UserProfile Resizing to:", newSize.width, "by", newSize.height)
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(self.cgImage!, in: newRect)
            let newImage = UIImage(cgImage: context.makeImage()!)
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
    
    // Scale image just specifying width.
    func scaleImage(toWidth width: CGFloat) -> UIImage? {
        let scale = width / self.size.width
        let height = self.size.height * scale
        let newSize = CGSize(width: width, height: height)
        return scaleImage(toSize: newSize)
    }
}
