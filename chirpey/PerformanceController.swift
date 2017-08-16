//
//  PerformanceController.swift
//  microjam
//
//  Created by Henrik Brustad on 16/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Maximum allowed recording time.
let RECORDING_TIME = 5.0

class PerformanceController: UIViewController {
    
    /// Storage of the present playback/recording state: playing, recording or idle
    var state = ChirpJamModes.idle
    /// Stores the recording/playback progress.
    var progress = 0.0
    /// Timer for progress in recording and playback.
    var progressTimer : Timer?
    /// Storage of the parent performances (if any).
    var performanceViews : [ChirpView] = [ChirpView]()
    /// Stores the present jamming state
    var jamming : Bool = false
    
    override func viewDidLoad() {
        
        
    }
}
