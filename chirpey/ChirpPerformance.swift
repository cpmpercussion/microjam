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
    var performanceData : [TouchRecord]
    var playbackTimers : [Timer] = []
    var date : Date
    var performer : String
    var instrument : String
    var image : UIImage

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
        static let imageKey = "image"
    }
    
    func encode(with aCoder: NSCoder) {
        print("Performance: encoding with ", performanceData.count, "notes.", performer, instrument)
        aCoder.encode(performanceData, forKey: PropertyKey.performanceDataKey)
        aCoder.encode(date, forKey: PropertyKey.dateKey)
        aCoder.encode(performer, forKey: PropertyKey.performerKey)
        aCoder.encode(instrument, forKey: PropertyKey.instrumentKey)
        aCoder.encode(UIImagePNGRepresentation(image), forKey: PropertyKey.imageKey)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let data = aDecoder.decodeObject(forKey: PropertyKey.performanceDataKey) as! [TouchRecord]
        guard
            //let data = aDecoder.decodeObject(forKey: PropertyKey.performanceDataKey) as? [TouchRecord],
            let date = aDecoder.decodeObject(forKey: PropertyKey.dateKey) as? Date,
            let performer = aDecoder.decodeObject(forKey: PropertyKey.performerKey) as? String,
            let instrument = aDecoder.decodeObject(forKey: PropertyKey.instrumentKey) as? String,
            let image = UIImage(data: (aDecoder.decodeObject(forKey: PropertyKey.imageKey) as? Data)!)
            else {return nil}
        
        print("Performance initialising from decoder with", data.count, "notes,", performer, instrument)
        self.init(data: data, date: date, performer: performer, instrument: instrument, image: image)
    }

    init(data: [TouchRecord], date: Date, performer: String, instrument: String, image: UIImage) {
        self.performanceData = data
        self.date = date
        self.performer = performer
        self.instrument = instrument
        self.image = image
        
        super.init()
    }
    
    convenience override init() {
        self.init(data : [], date : Date(), performer : "", instrument : "", image : UIImage())
    }

    /// Returns a CSV of the current performance data
    func csv() -> String {
        var output = ""
        output += ChirpPerformance.CSV_HEADER
        for touch in self.performanceData {
            output += touch.csv()
        }
        return output
    }
    
    /// Appends one touch datum to the current performance
    func recordTouchAt(time t : Double, x : Double, y : Double, z : Double, moving : Bool) {
        self.performanceData.append(TouchRecord(time: t, x: x, y: y, z: z, moving: moving))
    }
    
    
    // TODO: make playback behave like "play/pause" rather than start and cancel.
    
    /// Schedules playback of the performance in a given `ChirpView`
    func playback(inView view : ChirpView) {
        print("Performance: Playing back in a chirpview")
        for touch in self.performanceData {
            print("Performance: Scheduled a note.")
            let processor : (Timer) -> Void = view.makeTouchPlayerWith(touch: touch)
            let t = Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: processor)
            self.playbackTimers.append(t)
        }
        print("Performance: scheduled", self.playbackTimers.count, "notes.")
    }
    
    /// Cancels the current playback. (Can not be un-cancelled)
    func cancelPlayback() {
        for t in playbackTimers {
            t.invalidate()
        }
        playbackTimers = []
    }
    
    /// Writes a string to the documents directory with a title formed from the current date.
    func writeCSVToFile(csvString : String) {
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD-HH-mm-SS"
        let dateString = formatter.string(from: self.date)
        filePath.append(String(format: "chirprec-%@", dateString))
        try! csvString.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    /// Return a dateString that would work for adding to the performance list.
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss"
        return formatter.string(from: self.date)
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
    
//    /// Readable string version of the touchRecord
//    func description() -> String {
//        return String.init(format: "%f %f %f %f %@", time,x,y,z,moving.description)
//    }
    
    /// CSV version of the touchRecord for output to file
    func csv() -> String {
        return String(format:"%f, %f, %f, %f, %d\n", time, x, y, z, moving ? 0 : 1)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let time = aDecoder.decodeDouble(forKey: PropertyKey.time)
        let x = aDecoder.decodeDouble(forKey: PropertyKey.x)
        let y = aDecoder.decodeDouble(forKey: PropertyKey.y)
        let z = aDecoder.decodeDouble(forKey: PropertyKey.z)
        let moving = aDecoder.decodeBool(forKey: PropertyKey.moving)
        self.init(time: time, x: x, y: y, z: z, moving: moving)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.time, forKey: PropertyKey.time)
        aCoder.encode(self.x, forKey: PropertyKey.x)
        aCoder.encode(self.y, forKey: PropertyKey.y)
        aCoder.encode(self.z, forKey: PropertyKey.z)
        aCoder.encode(self.moving, forKey: PropertyKey.moving)
    }
}

