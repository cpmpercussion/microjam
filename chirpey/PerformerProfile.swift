//
//  PerformerSettings.swift
//  microjam
//
//  Created by Charles Martin on 3/8/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

/// Storage for performer profile data (either for local user or other users).
class PerformerProfile: NSObject {
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

