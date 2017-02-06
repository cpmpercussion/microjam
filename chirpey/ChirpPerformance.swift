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
import CoreLocation
import UIColor_Hex_Swift

class ChirpPerformance : NSObject, NSCoding {
    /// Array of `TouchRecord`s to store performance data.
    var performanceData : [TouchRecord]
    var playbackTimers : [Timer] = []
    var date : Date
    var performer : String
    var replyto : String = ""
    var instrument : String
    var image : UIImage
    var csvPathURL : URL?
    var location : CLLocation?
    var colour : UIColor = UIColor.blue
    //    var backgroundColour : UIColor = UIColor.gray

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
        static let locationKey = "location"
        static let colourKey = "colour"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(performanceData, forKey: PropertyKey.performanceDataKey)
        aCoder.encode(date, forKey: PropertyKey.dateKey)
        aCoder.encode(performer, forKey: PropertyKey.performerKey)
        aCoder.encode(instrument, forKey: PropertyKey.instrumentKey)
        aCoder.encode(UIImagePNGRepresentation(image), forKey: PropertyKey.imageKey)
        aCoder.encode(location, forKey: PropertyKey.locationKey)
        aCoder.encode(colour.hexString(), forKey: PropertyKey.colourKey)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(forKey: PropertyKey.performanceDataKey) as? [TouchRecord]
            else {return nil}
        guard
            let date = aDecoder.decodeObject(forKey: PropertyKey.dateKey) as? Date,
            let performer = aDecoder.decodeObject(forKey: PropertyKey.performerKey) as? String,
            let instrument = aDecoder.decodeObject(forKey: PropertyKey.instrumentKey) as? String,
            let image = UIImage(data: (aDecoder.decodeObject(forKey: PropertyKey.imageKey) as? Data)!),
            let colour = aDecoder.decodeObject(forKey: PropertyKey.colourKey) as? String
            else {return nil}
        let location = (aDecoder.decodeObject(forKey: "location") as? CLLocation) ?? CLLocation.init(latitude: 60, longitude: 11)
        print("PERF: Decoding", data.count, "notes:", performer, instrument)
        self.init(data: data, date: date, performer: performer, instrument: instrument, image: image, location: location, colour: colour)
    }

    /// Main initialiser
    init(data: [TouchRecord], date: Date, performer: String, instrument: String, image: UIImage, location: CLLocation, colour: String) {
        self.performanceData = data
        self.date = date
        self.performer = performer
        self.instrument = instrument
        self.image = image
        self.location = location
        self.colour = UIColor(colour)
        super.init()
    }
    
    /// Initialiser with csv of data for the TouchRecords, useful in initialising performances from CloudKit
    convenience init?(csv: String, date: Date, performer: String, instrument: String, image: UIImage, location: CLLocation, colour: String) {
        var data : [TouchRecord] = []
        let lines = csv.components(separatedBy: "\n")
        // TODO: test this initialiser
        data = lines.flatMap {TouchRecord.init(fromCSVLine: $0)}
        self.init(data: data, date: date, performer: performer, instrument: instrument, image: image, location: location, colour: colour)
    }
    
    
    /// Convenience Initialiser for creating performance with data yet to be added.
    convenience override init() {
        // FIXME: actually detect the proper location
        let perfColour : UIColor = UIColor(hue: CGFloat(UserDefaults.standard.float(forKey: SettingsKeys.performerColourKey)), saturation: 1.0, brightness: 0.7, alpha: 1.0)
        self.init(data : [], date : Date(), performer : "", instrument : "", image : UIImage(), location: CLLocation.init(latitude: 90.0, longitude: 45.0), colour: perfColour.hexString())
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
    func playback(inView view : ChirpView) -> [Timer] {
        view.playbackColour = self.colour.brighterColor.cgColor // make sure colour is set before playback.
        var timers : [Timer] = []
        for touch in self.performanceData {
            let processor : (Timer) -> Void = view.makeTouchPlayerWith(touch: touch)
            let t = Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: processor)
            timers.append(t)
        }
        print("PERF: playing back; scheduled", timers.count, "notes.")
        return(timers)
    }
    
    /// Cancels the current playback. (Can not be un-cancelled)
    func cancelPlayback(timers : [Timer]) {
        print("PERF: Cancelling", timers.count, "timers.")
        for t in timers {
            t.invalidate()
        }
    }
    
    /// A uniqueish string title for the performance
    func title() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD-HH-mm-SS"
        let dateString = formatter.string(from: date)
        return String(format: "perf-%@-%@-%@", performer, instrument, dateString)
    }
    
    /// Writes a string to the documents directory with a title formed from the current date. Returns the filepath.
    func writeToFile(csv : String) -> String {
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        filePath.append(String(format: "/%@.csv", title()))
        try? csv.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        return filePath
    }
    
    /// Return a dateString that would work for adding to the performance list.
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss"
        return formatter.string(from: self.date)
    }
    
    
    /// Returns the hex string for the performance's playback colour.
    func colourString() -> String {
        return self.colour.hexString()
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
    
//    /// Readable string version of the touchRecord
//    func description() -> String {
//        return String.init(format: "%f %f %f %f %@", time,x,y,z,moving.description)
//    }
    
    /// CSV version of the touchRecord for output to file
    func csv() -> String {
        return String(format:"%f, %f, %f, %f, %d\n", time, x, y, z, moving ? 1 : 0)
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


/// Makes a brighter version of UIColors for the playback version.
extension UIColor {
    
    /// return a brighter version of the UIColor
    var brighterColor: UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            else {return self}
        
        return UIColor(hue: h, saturation: s, brightness: min(1.3*b,1.0), alpha: a)
    }
}
