//
//  ProfilePerfController.swift
//  microjam
//
//  Created by Charles Martin on 4/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// A subclass of UserPerfController for the special case of the profile screen. Sets up for the local user and removes the header.
class ProfilePerfController: UserPerfController {
    /// Link to the users' profile data - not used right now, might be used later.
    let profile: PerformerProfile = UserProfile.shared.profile
    /// Initialises ViewController with separate storyboard with same name. Used to programmatically load the user settings screen in the tab bar controller.
    static func storyboardInstance() -> ProfilePerfController? {
        print("Profile Controller: Attempting to initialise from storyboard.")
        let storyboard = UIStoryboard(name:"ProfilePerfController", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as? ProfilePerfController
        return controller
    }
    static let headerID = "ProfileSceneHeader"
    static let footerID = "ProfileSceneFooter"

    /// Override of viewDidLoad in order to set the perfomerID to the local user.
    override func viewDidLoad() {
        super.viewDidLoad()
        performerID = CKRecordID(recordName: "__defaultOwner__")
    }

    /// Override of the header function size to be 300
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 300)
    }
    
    /// Override to present header view from storyboard.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ProfilePerfController.headerID, for: indexPath) as! ProfileHeaderCollectionReusableView
            return headerView
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: ProfilePerfController.footerID, for: indexPath) as! ProfileFooterCollectionReusableView
            return footerView
        default:
            return UICollectionReusableView()
        }
    }

    
    /// Override of the footer function size to be 100 - just needs a few labels.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 100)
    }
    
    //    MARK: - Interface Builder Actions for footer
    
    /// Action to open the microjam website in the default browser
    @IBAction func openMicrojamWebsite(_ sender: Any) {
        if let url = URL(string: "https://microjam.info") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// Action to open the privacy policy in the default browser
    @IBAction func openPrivacyPolicy(_ sender: Any) {
        if let url = URL(string: "https://microjam.info/privacy") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}
