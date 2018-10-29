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
