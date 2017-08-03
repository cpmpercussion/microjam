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
    static let shared = UserProfile()
    var record: CKRecord?
    
    
    /// Designated initialiser is private as this is a singleton.
    private init() {
        super.init(avatar: UIImage(), stageName: "", jamColour: UIColor.blue, backgroundColour: UIColor.clear, soundScheme: 1)
    }
    
    /// Updates the basic user information on CloudKit
    func updateUserBasicProfile() {
        
    }
    
    /// Update avatar on cloudkit
    func updateAvatar() {
        
    }
}
