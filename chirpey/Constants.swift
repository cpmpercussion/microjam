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
    static let tutorialCompleted = "tutorial_completed"
    static let darkMode = "dark_mode"
    static let defaultSettings : [String : Any] = [
        SettingsKeys.performerKey:"",
        SettingsKeys.performerColourKey: 0.5,
        SettingsKeys.backgroundColourKey: 0.2,
        SettingsKeys.soundSchemeKey: 0,
        SettingsKeys.tutorialCompleted: false,
        SettingsKeys.darkMode: true
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
        5 : "wub",
        6 : "pad",
        7 : "fmlead",
        8 : "leadguitar"
    ]
    static let keysForNames : [String : Int64] = [
        "chirp" : 0,
        "keys" : 1,
        "drums" : 2,
        "strings" : 3,
        "quack" : 4,
        "wub" : 5,
        "pad" : 6,
        "fmlead" : 7,
        "leadguitar" : 8
    ]
    static let pdFilesForKeys : [Int64 : String] = [
        0 : "chirp.pd",
        1 : "keys.pd",
        2 : "drums.pd",
        3 : "strings.pd",
        4 : "quack.pd",
        5 : "wub.pd",
        6 : "pad.pd",
        7 : "fmlead.pd",
        8 : "leadguitar.pd"
    ]
}

/// Contains constants related to communication with Pd.
struct PdConstants {
    static let toGUILabel = "toGUI"
    static let debugLabel = "debug"
    static let receiverPostFix = "-input" // should be list input
    static let volumePostFix = "-volume" // should be float input
    static let mutePostFix = "-mute" /// should be a bool input
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
//    static let parent = "Parent"
    static let touches = "Touches"
    static let colour = "Colour"
    static let backgroundColour = "BackgroundColour"
    static let createdBy = "createdBy"
}

/// Keys for Users type in CloudKit Storage
struct UserCloudKeys {
    static let type = "Users"
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
    static let profileTab = "profile"
    static let userPerfsTab = "perfs"
    static let repliesTab = "replies"
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

/// Maximum allowed recording time.
let RECORDING_TIME = 5.0

/// Colours for buttons in Jam Screen
struct ButtonColors {
    static let rewind = UIColor.init("#774BE5") //"#2a317d") //UIColor.init("#A10702")
    static let record = UIColor.red //UIColor.init("#f13f04")//("#fb4d3d") //UIColor.init("#ED2D07")
    static let recordDisabled = UIColor.init("#b01435")
    static let recordGlow = UIColor.init("#ff5900") //("#e5470d") // just for glow effect on rec button
    static let play = UIColor.init("#a4f644") // "#03cea4") // UIColor.init("#FAA613")
    static let jam = UIColor.init("#FFD045") //"#eac435") // UIColor.init("#688E26") //
    static let layer = UIColor.init("#4FEBF9") //#7dcfb6")
    static let robojam = UIColor.init("#ca1551") //UIColor.init("#550527") //
}

/// Error messages and dialogues

struct ErrorDialogues {
    static let icloudNotLoggedIn = "MicroJam uses iCloud to store your performances."
}

struct DarkMode {
    static let background = UIColor.init("#141d26") // 0C1821
    static let midbackground = UIColor.init("#243447")
    static let midforeground = UIColor.init("fffde2")
    static let text = UIColor.init("#ffffff")
    static let highlight = UIColor.init("#ec6b2d")
}

struct LightMode {
    static let background = UIColor.init("#f2f2f4") // ffffff
    static let midbackground = UIColor.init("#d5d5d5")
    static let midforeground = UIColor.init("223843")
    static let text = UIColor.init("#0C1821")
    static let highlight = UIColor.init("#d95d39")
}


/// Notifications and notification keys

extension Notification.Name {
    static let userProfileUpdated = Notification.Name("au.com.charlesmartin.userProfileUpdatedNotificationKey")
    static let userDataExportReady = Notification.Name("au.com.charlesmartin.userDataExportReadyKey")
    static let performanceStoreUpdated = Notification.Name("au.com.charlesmartin.performanceStoreUpdatedNotificationKey")
    static let performanceStorePerfAdded = Notification.Name("au.com.charlesmartin.performanceStorePerfAdded")
    static let performanceStoreFailedUpdate = Notification.Name("au.com.charlesmartin.performanceStoreFailedUpdateNotificationKey")
    static let performerProfileUpdated = Notification.Name("au.com.charlesmartin.PerformerProfilesUpdatedNotificationKey")
    static let setColourTheme = Notification.Name("au.com.charlesmartin.setColourTheme")
}

/// Dispatch Queue Keys

struct QueueLabels {
    static let touchPlayback = "au.com.charlesmartin.microjam.touchplayback"
    static let performanceTimer = "au.com.charlesmartin.microjam.perftimer"
}
