//
//  PerformerSettings.swift
//  microjam
//
//  Created by Charles Martin on 3/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

/// Storage for performer profile data (either for local user or other users).
class PerformerProfile: NSObject, NSCoding {
    /// Performer avatar image
    var avatar : UIImage
    /// Performer stage name
    var stageName : String
    /// Performer's jam colour
    var jamColour : UIColor
    /// Performer's background colour
    var backgroundColour : UIColor
    /// Performer's favourite soundscheme key
    var soundScheme : Int64
    
    /// Main initialiser
    init (avatar: UIImage, stageName: String, jamColour: UIColor, backgroundColour: UIColor, soundScheme: Int64) {
        self.avatar = avatar
        self.stageName = stageName
        self.jamColour = jamColour
        self.backgroundColour = backgroundColour
        self.soundScheme = soundScheme
    }
    
    /// Convenience initialiser for creating from CloudKit data where colours are stored as hex string.
    convenience init?(avatar: UIImage, stageName: String, jamHex: String, backgroundHex: String, soundScheme: Int64) {
        self.init(avatar: avatar, stageName: stageName, jamColour: UIColor(jamHex, defaultColor: UIColor.blue), backgroundColour: UIColor(backgroundHex), soundScheme: soundScheme)
    }
    
    /// Initialiser for a blank performance
    convenience override init() {
        self.init(avatar: UIImage(), stageName: "", jamColour: UIColor.blue, backgroundColour: UIColor.clear, soundScheme: 1)
    }
    
    // MARK: NSCoding Functions
    
    /// Function for encoding as NSCoder, used for saving on app close.
    func encode(with aCoder: NSCoder) {
        aCoder.encode(UIImagePNGRepresentation(avatar), forKey: UserCloudKeys.avatar)
        aCoder.encode(stageName, forKey: UserCloudKeys.stagename)
        aCoder.encode(jamColour, forKey: UserCloudKeys.jamColour)
        aCoder.encode(backgroundColour, forKey: UserCloudKeys.backgroundColour)
        aCoder.encode(soundScheme, forKey: UserCloudKeys.soundScheme)
    }
    
    /// Initialiser from NSCoder, used when reopening on app launch
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let imageData = aDecoder.decodeObject(forKey: UserCloudKeys.avatar) as? Data,
            let avatar = UIImage(data: imageData),
            let stageName = aDecoder.decodeObject(forKey: UserCloudKeys.stagename) as? String,
            let jamColour = aDecoder.decodeObject(forKey: UserCloudKeys.jamColour) as? UIColor,
            let backgroundColour = aDecoder.decodeObject(forKey: UserCloudKeys.backgroundColour) as? UIColor,
            let soundScheme = aDecoder.decodeObject(forKey: UserCloudKeys.soundScheme) as? Int64
            else {return nil}
        self.init(avatar: avatar, stageName: stageName, jamColour: jamColour, backgroundColour: backgroundColour, soundScheme: soundScheme)
    }
}

extension PerformerProfile {
    /// Returns a colour from a given hue value picked using a slider.
    static func colourFromHue(hue: Float) -> UIColor {
        return UIColor(hue: CGFloat(hue), saturation: 1.0, brightness: 0.7, alpha: 1.0)
    }
    
    /// Returns a hue [0,1] from a given UIColor
    static func hueFrom(colour: UIColor) -> Float {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        colour.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Float(hue)
    }
}

// MARK: Functions when loading PerformerProfile from a CKRecord

extension PerformerProfile {
    
    convenience init?(fromRecord record: CKRecord) {
        guard
            let imagePath = record[UserCloudKeys.avatar] as? CKAsset,
            let avatar = UIImage(contentsOfFile: imagePath.fileURL.path),
            let stageName = record[UserCloudKeys.stagename] as? String,
            let jamColourHex = record[UserCloudKeys.jamColour] as? String,
            let backgroundColourHex = record[UserCloudKeys.backgroundColour] as? String,
            let soundScheme = record[UserCloudKeys.soundScheme] as? Int64
            else {return nil}
        let jamColour = UIColor(jamColourHex)
        let backgroundColour = UIColor(backgroundColourHex)
        self.init(avatar: avatar, stageName: stageName, jamColour: jamColour, backgroundColour: backgroundColour, soundScheme: soundScheme)
    }
}
