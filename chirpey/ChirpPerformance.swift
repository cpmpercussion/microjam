//
//  ChirpPerformance.swift
//  
//
//  Created by Charles Martin on 21/11/16.
//
//

import UIKit

class ChirpPerformance {
    var performanceData: NSMutableOrderedSet?
    
    
}


/**
 Contains the data from a single touch in the interaction square. Includes function to output as CSV
 
 - Time: time since the start of the recording in seconds.
 - x: location in square in [0,1]
 - y: location in square in [0,1]
 - z: pressure/size of touch in [0,1] (so far unused)
 - moving: whether the touch was moving when recorded
 
 */
struct touchRecord {
    /// Time since the start of the recording in seconds
    var time : Double
    /// location in square in [0,1]
    var x : Double
    /// location in square in [0,1]
    var y : Double
    /// pressure/size of touch in [0,1] (so far unused)
    var z : Double
    /// whether the touch was moving when recorded
    var moving : Bool
    /// Readable string version of the touchRecord
    var description : String {
        return String.init(format: "%f %f %f %f %@", time,x,y,z,moving.description)
    }
    /// CSV version of the touchRecord for output to file
    var csv : String {
        return String(format:"%f, %f, %f, %f, %d\n", time, x, y, z, moving ? 0 : 1)
    }
}
