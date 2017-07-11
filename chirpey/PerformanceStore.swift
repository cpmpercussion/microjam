//
//  PerformanceStore.swift
//  microjam
//
//  Created by Charles Martin on 12/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// Classes implementing this protocol have can be notified of success or failure of updates from the `PerformanceStore`'s cloud backend.
protocol ModelDelegate {
    
    /// Called when the `PerformanceStore` fails to update for some reason.
    func errorUpdating(error: NSError)
    
    /// Called when the `PerformanceStore` successfully updates from the cloud backend.
    func modelUpdated()
}

/** 
 Contains stored performances and handles saving these to the local storage and synchronising with the cloud backend on CloudKit.
*/
class PerformanceStore: NSObject {
    
}
