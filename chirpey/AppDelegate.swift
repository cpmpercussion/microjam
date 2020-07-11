//
//  AppDelegate.swift
//  microjam
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PdReceiverDelegate {
    var window: UIWindow?
    let performanceStore = PerformanceStore.shared
    let userProfile = UserProfile.shared
    let profileStore = PerformerProfileStore.shared
    var audioController : PdAudioController?
    var audiobusController: ABAudiobusController?

    // MARK: Pd Engine Initialisation
    
    /// Starts the Pd Audio Engine and preemptively opens a patch.
    func startAudioEngine() {
        NSLog("AD: Starting Audio Engine");
        audioController = PdAudioController()
        audioController?.configurePlayback(withSampleRate: Int32(SAMPLE_RATE), numberChannels: Int32(SOUND_OUTPUT_CHANNELS), inputEnabled: false, mixingEnabled: true)
        audioController?.configureTicksPerBuffer(Int32(TICKS_PER_BUFFER))
        PdBase.setDelegate(self)
        PdBase.subscribe(PdConstants.toGUILabel)
        PdBase.subscribe(PdConstants.debugLabel)
        audioController?.isActive = true
        audioController?.print()
        // audiobuscontroller setup starts here...
//        audiobusController = ABAudiobusController(apiKey: "H4sIAAAAAAAAA2WMWw6CMBQF93K/kUKCMelWrCGlVC3SR257jQ1h7xbDD/F3zsxZQH+CwQy8qWAgN866d9Jq4GCNQj9JCxUQzn1UT33gp7Zu6nMtaTR+oMgFE6y4wWOKwK8LpBw2XxI+Cv9/HXVUaEIy3h2HSMPexuxSAVY6ukuVCDVuqpo27a0x/tp2vVVgxrIItsMo2EtnwbpL08H6BcFIyobmAAAA:CimuS2XdZn6+uXEStGuY1NEQekRdCeHzqoPAnGaCScxxFZGElJI6ECaxOyGPXWQVQGmdz+Gbsw5RZ5YSEWj8n4GiwQTb+1JuGSMFyiKn05rgVqqgkIGBKaA6plf+aUas")
        
        // Borrowed from AudioKit
        // https://github.com/AudioKit/AudioKit/blob/master/Examples/iOS/Audiobus/Audiobus.swift
        // Thanks!
//        var myDict: NSDictionary?
//        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
//            myDict = NSDictionary(contentsOfFile: path)
//        }

//        if let dict = myDict {
//            for component in dict["AudioComponents"] as! [[String: AnyObject]] {
////                let type = fourCC(component["type"] as! String)
//                let subtype = fourCC(component["subtype"] as! String)
//                let name = component["name"] as! String
//                let manufacturer = fourCC(component["manufacturer"] as! String)
//
//                audiobusController?.addAudioSenderPort(
//                    ABAudioSenderPort(
//                        name: name,
//                        title: name,
//                        audioComponentDescription: AudioComponentDescription(
//                            componentType: kAudioUnitType_RemoteGenerator,
//                            componentSubType: subtype,
//                            componentManufacturer: manufacturer,
//                            componentFlags: 0,
//                            componentFlagsMask: 0
//                        ),
//                        audioUnit: audioController?.audioUnit.audioUnit))
//            }
//            print("AppDelegate: configured audiobus")
//        } else {
//            print("AppDelegate: Failed to configure audiobus.")
//        }
        // Audiobus setup ends..
    }
    
    // Borrowed from AudioKit: https://github.com/AudioKit/AudioKit/blob/master/AudioKit/Common/Internals/AudioKitHelpers.swift
    // Thanks!
    func fourCC(_ string: String) -> UInt32 {
        let utf8 = string.utf8
        precondition(utf8.count == 4, "Must be a 4 char string")
        var out: UInt32 = 0
        for char in utf8 {
            out <<= 8
            out |= UInt32(char)
        }
        return out
    }
    
    /// Receives print messages from Pd for debugging
    func receivePrint(_ message: String!) {
        NSLog("Pd: %@", message)
    }
    
    // MARK: Application Lifecycle
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UserDefaults.standard.register(defaults: SettingsKeys.defaultSettings)
        startAudioEngine() // start Pd
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        //
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveData()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Tell all views to update ColourTheme
        NotificationCenter.default.post(name: .setColourTheme, object: nil)
        //
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //
    }
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        // MARK: Check to start tutorial.
        if (!UserDefaults.standard.bool(forKey: SettingsKeys.tutorialCompleted)) {
            print("AD: Starting Tutorial")
            perform(#selector(presentTutorial), with: nil, afterDelay: 0)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("AD: Application will terminate, saving data.")
        saveData()
    }
    
    /// Save the loaded data to a file for quick reloading later.
    func saveData() {
        print("AD: Saving all local data")
        performanceStore.savePerformances() // save locally stored performances.
        userProfile.saveProfile() // save local copy of the user's profile.
        profileStore.saveProfiles() // save local copy of performer profiles.
    }

    /// Presents the MicrojamTutorialViewController to new users.
    @objc func presentTutorial() {
        if let tutorialController = MicrojamTutorialViewController.storyboardInstance() {
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                currentController.present(tutorialController, animated: true, completion: nil)
            }
        }
    }
    


}
