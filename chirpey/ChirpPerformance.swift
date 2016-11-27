//
//  ChirpPerformance.swift
//  
//
//  Created by Charles Martin on 21/11/16.
//
//

/**
 Contains the data from a single chirp performance.
 Data is stored as an array of `TouchRecord`.
 */
import UIKit

class ChirpPerformance : NSObject, NSCoding {
    /// Array of `TouchRecord`s to store performance data.
    var performanceData : [TouchRecord] = []
    var date : Date?
    var performer : String = ""
    var instrument : String = ""

    // Static vars
    static let CSV_HEADER = "time,x,y,z,moving\n"
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("performances")
    
    struct PropertyKey {
        static let performanceDataKey = "performanceData"
        static let dateKey = "date"
        static let performerKey = "performer"
        static let instrumentKey = "instrument"
    }
    
    /// NSCoder Encoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(performanceData, forKey: PropertyKey.performanceDataKey)
        aCoder.encode(date, forKey: PropertyKey.dateKey)
        aCoder.encode(performer, forKey: PropertyKey.performerKey)
        aCoder.encode(instrument, forKey: PropertyKey.instrumentKey)
        
    }

    /// NSCoder Decoding
    required convenience init?(coder aDecoder: NSCoder) {
        let data = aDecoder.decodeObject(forKey: PropertyKey.performanceDataKey) as! [TouchRecord]
        let date = aDecoder.decodeObject(forKey: PropertyKey.dateKey) as? Date
        let performer = aDecoder.decodeObject(forKey: PropertyKey.performerKey) as! String
        let instrument = aDecoder.decodeObject(forKey: PropertyKey.instrumentKey) as! String
        
        self.init(data: data, date: date!, performer: performer, instrument: instrument)
    }

    init(data: [TouchRecord], date: Date, performer: String, instrument: String) {
        self.performanceData = data
        self.date = date
        self.performer = performer
        self.instrument = instrument
        
        super.init()
    }
    
    convenience override init() {
        self.init(data : [], date : Date(), performer : "", instrument : "")
    }

    /// Returns a CSV of the current performance data
    func csv() -> String {
        var output = ""
        output += ChirpPerformance.CSV_HEADER
        for touch in self.performanceData {
            output += touch.csv
        }
        return output
    }
    
    /// Appends one touch datum to the current performance
    func recordTouchAt(time t : Double, x : Double, y : Double, z : Double, moving : Bool) {
        self.performanceData.append(TouchRecord(time: t, x: x, y: y, z: z, moving: moving))
    }
    
    /// Schedules playback of the performance in a given `ChirpView`
    func playback(inView view : ChirpView) {
        for touch in self.performanceData {
            let processor : (Timer) -> Void = view.makeTouchPlayerWith(touch: touch)
            Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: processor)
        }
    }
}

/**
 Contains the data from a single touch in the interaction square.
 
 - Time: time since the start of the recording in seconds.
 - x: location in square in [0,1]
 - y: location in square in [0,1]
 - z: pressure/size of touch in [0,1] (so far unused)
 - moving: whether the touch was moving when recorded
 
 Includes functions to output a single CSV line representing the touch.
 */
struct TouchRecord {
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
