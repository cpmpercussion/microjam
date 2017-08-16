//
//  PerformanceHandler.swift
//  microjam
//
//  Created by Henrik Brustad on 16/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class PerformanceHandler: NSObject {
    
    var timers: [Timer]?
    var performances: [ChirpPerformance]?
    
    init(performances: [ChirpPerformance]) {
        super.init()
        self.performances = performances
    }
}
