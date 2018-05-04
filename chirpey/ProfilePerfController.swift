//
//  ProfilePerfController.swift
//  microjam
//
//  Created by Charles Martin on 4/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

class ProfilePerfController: UserPerfController {
    /// Link to the users' profile data.
    let profile: PerformerProfile = UserProfile.shared.profile

    override func viewDidLoad() {
        super.viewDidLoad()
        performerID = CKRecordID(recordName: "__defaultOwner__")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// make sure header is size 0.
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
