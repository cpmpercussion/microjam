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
    let performanceStore = PerformanceStore()
    let userProfile = UserProfile.shared
    var storedPerformances : [ChirpPerformance] = [] // FIXME delete these
    static let defaultSettings : [String : Any] = [
        SettingsKeys.performerKey:"performer",
        SettingsKeys.performerColourKey: 0.5,
        SettingsKeys.backgroundColourKey: 0.2,
        SettingsKeys.soundSchemeKey: 0
    ]
    let SOUND_OUTPUT_CHANNELS = 2
    let SAMPLE_RATE = 44100
    let TICKS_PER_BUFFER = 4
    var audioController : PdAudioController?

    // MARK: Pd Engine Initialisation
    
    /// Starts the Pd Audio Engine and preemptively opens a patch.
    func startAudioEngine() {
        NSLog("JAMVC: Starting Audio Engine");
        self.audioController = PdAudioController()
        self.audioController?.configurePlayback(withSampleRate: Int32(SAMPLE_RATE), numberChannels: Int32(SOUND_OUTPUT_CHANNELS), inputEnabled: false, mixingEnabled: true)
        self.audioController?.configureTicksPerBuffer(Int32(TICKS_PER_BUFFER))
        PdBase.setDelegate(self)
        PdBase.subscribe(PdConstants.toGUILabel)
        PdBase.subscribe(PdConstants.debugLabel)
        self.audioController?.isActive = true
        self.audioController?.print()
    }
    
    /// Receives print messages from Pd for debugging
    func receivePrint(_ message: String!) {
        NSLog("Pd: %@", message)
    }
    
    // MARK: Application Lifecycle
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Register defaults
        UserDefaults.standard.register(defaults: AppDelegate.defaultSettings)
//        performanceStore = PerformanceStore() // Init the PerformanceStore
        self.startAudioEngine() // start Pd
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        //
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //
    }
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        if (UserDefaults.standard.string(forKey: SettingsKeys.performerKey) == AppDelegate.defaultSettings[SettingsKeys.performerKey] as? String) {
            // Still set to default name, prompt to change setting!
            print("AD: Name still set to default, ask user to change")
//            if let viewcontroller = window?.rootViewController {
//                viewcontroller.performSegue(withIdentifier:"username", sender: viewcontroller)
//            }
            perform(#selector(presentUserNameChooserController), with: nil, afterDelay: 0)
        }
    }

    func presentUserNameChooserController() {
        if let usernamecontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserNameChooser") as? UserNameChooserViewController {
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                currentController.present(usernamecontroller, animated: true, completion: nil)
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("AD: Application will terminate")
        performanceStore.savePerformances()
    }

}
