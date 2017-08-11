//
//  Constants.swift
//  microjam
//
//  Created by Charles Martin on 22/6/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import Foundation

// MARK: Settings Constants

/// Keys for settings in UserDefaults
struct SettingsKeys {
    static let performerKey = "performer_name"
    static let performerColourKey = "performer_colour"
    static let backgroundColourKey = "background_colour"
    static let soundSchemeKey = "sound_scheme"
    static let defaultSettings : [String : Any] = [
        SettingsKeys.performerKey:"performer",
        SettingsKeys.performerColourKey: 0.5,
        SettingsKeys.backgroundColourKey: 0.2,
        SettingsKeys.soundSchemeKey: 0
    ]
}

// MARK: Pd Constants

let SOUND_OUTPUT_CHANNELS = 2
let SAMPLE_RATE = 44100
let TICKS_PER_BUFFER = 4

/// Constants relating SoundScheme names, ids, and Pd file names.
struct SoundSchemes {
    static let namesForKeys : [Int64 : String] = [
        0 : "chirp",
        1 : "keys",
        2 : "drums",
        3 : "strings",
        4 : "quack",
        5 : "wub"
    ]
    static let keysForNames : [String : Int64] = [
        "chirp" : 0,
        "keys" : 1,
        "drums" : 2,
        "strings" : 3,
        "quack" : 4,
        "wub" : 5
    ]
    static let pdFilesForKeys : [Int64 : String] = [
        0 : "chirp.pd",
        1 : "keys.pd",
        2 : "drums.pd",
        3 : "strings.pd",
        4 : "quack.pd",
        5 : "wub.pd"
    ]
}

/// Contains constants related to communication with Pd.
struct PdConstants {
    static let toGUILabel = "toGUI"
    static let debugLabel = "debug"
    static let receiverPostFix = "-input"
}

// MARK: CloudKit Constants

/// Keys for performance data in CloudKit Storage
struct PerfCloudKeys {
    static let type = "Performance"
    static let date = "Date"
    static let image = "Image"
    static let instrument = "Instrument"
    static let location = "PerformedAt"
    static let performer = "Performer"
    static let replyto = "ReplyTo"
    static let touches = "Touches"
    static let colour = "Colour"
}

/// Keys for Users type in CloudKit Storage
struct UserCloudKeys {
    static let avatar = "avatar" // Asset
    static let email = "Email" // String
    static let home = "Home" // String
    static let name = "Name" // String
    static let stagename = "stageName" // String
    static let jamColour = "jamColour" // String (of hex code)
    static let backgroundColour = "backgroundColour" // String (of hex code)
    static let soundScheme = "soundScheme" // Int(64) of instrument code
}

// MARK: UI and View Controller Constants

/// Modes for the ChirpJameViewController: either new, recording, loaded, or playing.
struct ChirpJamModes {
    static let new = 0
    static let recording = 1
    static let loadedAndUnsaved = 2
    static let loadedAndSaved = 3
    static let loaded = 4
    static let playing = 5
    static let composing = 6
    static let idle = 7
}

/// Identifiers for different segues used in the storyboard.
struct JamViewSegueIdentifiers {
    static let replyToSegue = "ReplyToPerformance"
    static let addNewSegue = "AddPerformance"
    static let showDetailSegue = "ShowDetail"
}

/// Titles for the TabBar items.
struct TabBarItemTitles {
    static let worldTab = "world"
    static let jamTab = "jam!"
    static let settingsTab = "settings"
}

/// Labels for performance contexts.
struct PerformanceLabels {
    static let solo : [String] = [
        "rides again.",
        "goes forth.",
        "takes the stage.",
        "rocked out.",
        "rings a bell.",
        "hit the right note.",
        "struck a chord.",
        "played out.",
        "played it again.",
        "hit the stage.",
        "played like they meant it."
    ]
    static let duo : [String] = [
        "rocked out with",
        "took the stage with",
        "jammed with",
    ]
}

