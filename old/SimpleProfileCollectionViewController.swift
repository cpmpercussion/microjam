//
//  ProfilePerfController.swift
//  microjam
//
//  Created by Charles Martin on 4/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// A simplified subclass of UserPerfController for the special case of the profile screen. Sets up for the local user and removes the header.
class SimpleProfileCollectionViewController: UserPerfController {
    /// Link to the users' profile data - not used right now, might be used later.
    let profile: PerformerProfile = UserProfile.shared.profile
    
    /// Override of viewDidLoad in order to set the perfomerID to the local user.
    override func viewDidLoad() {
        super.viewDidLoad()
        performerID = CKRecordID(recordName: "__defaultOwner__")
    }
    
    /// Override of the header function to blank it out: makes sure header is size 0.
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
}

