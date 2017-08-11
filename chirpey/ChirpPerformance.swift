//
//  ChirpPerformance.swift
//  
//
//  Created by Charles Martin on 21/11/16.
//
//
import UIKit
import CoreLocation
import CloudKit
import UIColor_Hex_Swift
import DateToolsSwift

/**
 Contains the data from a single chirp performance.
 Data is stored as an array of `TouchRecord`.
 */
class ChirpPerformance : NSObject {
    /// Array of `TouchRecord`s to store performance data.
    var performanceData : [TouchRecord]
    /// Array of Timers scheduled to play back each TouchRecord
    var playbackTimers : [Timer] = []
    /// Date of the MicroJam performance
    var date : Date
    /// Performer of the MicroJam performance
    var performer : String
    /// Title of the MicroJam performance that this replies to, empty string if it is not a reply.
    var replyto : String = ""
    /// Name of the SoundScheme used to record this performance.
    var instrument : String
    /// UIImage of completed performance touch trace.
    var image : UIImage
    /// Location of CSV file storing this performance's TouchRecords.
    var csvPathURL : URL?
    /// Location where performances was recorded (unused).
    var location : CLLocation?
    /// Colour used for touch trace of this recording.
    var colour : UIColor = UIColor.blue
    /// Return a dateString that would work for adding to the performance list.
    var dateString: String { return self.date.timeAgoSinceNow }
    /// Returns the hex string for the performance's playback colour.
    var colourString : String { return self.colour.hexString() }
    //    var backgroundColour : UIColor = UIColor.gray
    /// Keeps track of the Record ID of performances retrieved from CloudKit
    var performanceID : CKRecordID?
    /// Keeps track of Record ID of parent performance
    var parentReference : CKReference?

    // MARK: Archiving Paths and TouchRecord header.

    /// Header line for performance CSVs.
    static let CSV_HEADER = "time,x,y,z,moving\n"
    /// URL of local documents directory.
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    /// URL of performance storage directory.
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("performances")
    
    /// Initialiser from NSCoder, used when reopening saved performances on app launch
    required convenience init?(coder aDecoder: NSCoder) {
        // TODO: write unit test to test this function.
        guard let data = aDecoder.decodeObject(forKey: PropertyKey.performanceDataKey) as? [TouchRecord]
            else {return nil}
        guard
            let date = aDecoder.decodeObject(forKey: PropertyKey.dateKey) as? Date,
            let performer = aDecoder.decodeObject(forKey: PropertyKey.performerKey) as? String,
            let instrument = aDecoder.decodeObject(forKey: PropertyKey.instrumentKey) as? String,
            let imageData = aDecoder.decodeObject(forKey: PropertyKey.imageKey) as? Data,
            let image = UIImage(data: imageData),
            let colour = aDecoder.decodeObject(forKey: PropertyKey.colourKey) as? String,
            let replyto = aDecoder.decodeObject(forKey: PropertyKey.replyToKey) as? String
            else {return nil}
        let location = (aDecoder.decodeObject(forKey: "location") as? CLLocation) ?? CLLocation.init(latitude: 60, longitude: 11)
        // print("PERF: Decoding", data.count, "notes:", performer, instrument)
        self.init(data: data, date: date, performer: performer, instrument: instrument, image: image, location: location, colour: colour, replyto: replyto)
        if let perfId = aDecoder.decodeObject(forKey: PropertyKey.performanceIDKey) as? CKRecordID {
            self.performanceID = perfId
        }
    }

    /// Main initialiser
    init(data: [TouchRecord], date: Date, performer: String, instrument: String, image: UIImage, location: CLLocation, colour: String, replyto: String) {
        self.performanceData = data
        self.date = date
        self.performer = performer
        self.instrument = instrument
        self.image = image
        self.location = location
        self.colour = UIColor(colour)
        self.replyto = replyto
        super.init()
    }
    
    /// Initialiser with csv of data for the TouchRecords, useful in initialising performances from CloudKit
    convenience init?(csv: String, date: Date, performer: String, instrument: String, image: UIImage, location: CLLocation, colour: String, replyto: String, performanceID: CKRecordID) {
        var data : [TouchRecord] = []
        let lines = csv.components(separatedBy: "\n")
        // TODO: test this initialiser
        data = lines.flatMap {TouchRecord.init(fromCSVLine: $0)}
        self.init(data: data, date: date, performer: performer, instrument: instrument, image: image, location: location, colour: colour, replyto: replyto)
        self.performanceID = performanceID
    }
    
    /// Convenience Initialiser for creating performance with data yet to be added.
    convenience override init() {
        // FIXME: actually detect the proper location
        let perfColour : UIColor = UserProfile.shared.profile.jamColour
        self.init(data : [], date : Date(), performer : "", instrument : "", image : UIImage(), location: CLLocation.init(latitude: 90.0, longitude: 45.0), colour: perfColour.hexString(), replyto: "")
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
    
    /// A uniqueish string title for the performance - used for CloudKit records and reply system.
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
    

}

// MARK: Playback functions

/// Extension for playback functions
extension ChirpPerformance {
    
    // TODO: make playback behave like "play/pause" rather than start and cancel.
    
    /// Schedules playback of the performance in a given `ChirpView`
    func playback(inView view : ChirpView) {
        view.playbackColour = self.colour.brighterColor.cgColor // make sure colour is set before playback.
        var timers : [Timer] = []
        for touch in self.performanceData {
            let processor : (Timer) -> Void = view.makeTouchPlayerWith(touch: touch)
            let t = Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: processor)
            timers.append(t)
        }
        print("PERF: playing back; scheduled", timers.count, "notes.")
        self.playbackTimers = timers
    }
    
    /// Cancels the current playback. (Can not be un-cancelled)
    func cancelPlayback() {
        print("PERF: Cancelling", self.playbackTimers.count, "timers.")
        for t in self.playbackTimers {
            t.invalidate()
        }
    }
    
}

// MARK: NSCoding stuff

/// Extension for NSCoding methods
extension ChirpPerformance: NSCoding {
    /// Keys for performances stored in NSCoders.
    struct PropertyKey {
        static let performanceDataKey = "performanceData"
        static let dateKey = "date"
        static let performerKey = "performer"
        static let instrumentKey = "instrument"
        static let imageKey = "image"
        static let locationKey = "location"
        static let colourKey = "colour"
        static let replyToKey = "replyto"
        static let performanceIDKey = "performance_id"
    }
    
    /// Function for encoding as NSCoder, used for saving performances on app close.
    func encode(with aCoder: NSCoder) {
        aCoder.encode(performanceData, forKey: PropertyKey.performanceDataKey)
        aCoder.encode(date, forKey: PropertyKey.dateKey)
        aCoder.encode(performer, forKey: PropertyKey.performerKey)
        aCoder.encode(instrument, forKey: PropertyKey.instrumentKey)
        aCoder.encode(UIImagePNGRepresentation(image), forKey: PropertyKey.imageKey)
        aCoder.encode(location, forKey: PropertyKey.locationKey)
        aCoder.encode(colour.hexString(), forKey: PropertyKey.colourKey)
        aCoder.encode(replyto, forKey: PropertyKey.replyToKey)
        if let perfID = self.performanceID {
            aCoder.encode(perfID, forKey: PropertyKey.performanceIDKey)
        }
    }
}

// MARK: UIColor brighterColor for playback

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
