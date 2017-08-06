//
//  TouchRecord.swift
//  microjam
//
//  Created by Charles Martin on 6/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/**
 Contains the data from a single touch in the interaction square.
 
 - time: time since the start of the recording in seconds.
 - x: location in square in [0,1]
 - y: location in square in [0,1]
 - z: pressure/size of touch in [0,1] (so far unused)
 - moving: whether the touch was moving when recorded (Bool represented as 0 or 1).
 
 Includes functions to output a single CSV line representing the touch.
 Must be a class so that TouchRecords can be encoded as NSCoders.
 */
class TouchRecord: NSObject, NSCoding {
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
    
    /// Keys for NSCoder encoded contents.
    struct PropertyKey {
        static let time = "time"
        static let x = "x"
        static let y = "y"
        static let z = "z"
        static let moving = "moving"
    }
    
    init(time: Double, x: Double, y: Double, z: Double, moving: Bool) {
        self.time = time
        self.x = x
        self.y = y
        self.z = z
        self.moving = moving
        super.init()
    }
    
    /// Initialises a touchRecord from a single line of a CSV file
    convenience init?(fromCSVLine line : String) {
        let components = line.replacingOccurrences(of: " ", with: "").components(separatedBy: ",")
        guard let time = Double(components[0]),
            let x = Double(components[1]),
            let y = Double(components[2]),
            let z = Double(components[3]),
            let mov = Double(components[4])
            else {
                return nil
        }
        let moving = (mov == 1)
        self.init(time: time, x: x, y: y, z: z, moving: moving)
    }
    
    /// CSV version of the touchRecord for output to file
    func csv() -> String {
        return String(format:"%f, %f, %f, %f, %d\n", time, x, y, z, moving ? 1 : 0)
    }
    
    /// Initialise a TouchRecord from an NSCoder.
    required convenience init?(coder aDecoder: NSCoder) {
        let time = aDecoder.decodeDouble(forKey: PropertyKey.time)
        let x = aDecoder.decodeDouble(forKey: PropertyKey.x)
        let y = aDecoder.decodeDouble(forKey: PropertyKey.y)
        let z = aDecoder.decodeDouble(forKey: PropertyKey.z)
        let moving = aDecoder.decodeBool(forKey: PropertyKey.moving)
        self.init(time: time, x: x, y: y, z: z, moving: moving)
    }
    
    /// Encode a TouchRecord as an NSCoder.
    func encode(with aCoder: NSCoder) {
        aCoder.encode(time, forKey: PropertyKey.time)
        aCoder.encode(x, forKey: PropertyKey.x)
        aCoder.encode(y, forKey: PropertyKey.y)
        aCoder.encode(z, forKey: PropertyKey.z)
        aCoder.encode(moving, forKey: PropertyKey.moving)
    }
}
