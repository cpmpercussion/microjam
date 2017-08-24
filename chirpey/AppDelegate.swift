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
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UserDefaults.standard.register(defaults: SettingsKeys.defaultSettings)
        startAudioEngine() // start Pd
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
        if (UserDefaults.standard.string(forKey: SettingsKeys.performerKey) == SettingsKeys.defaultSettings[SettingsKeys.performerKey] as? String) {
            // Still set to default name, prompt to change setting!
            print("AD: Name still set to default, ask user to change")
            perform(#selector(presentUserNameChooserController), with: nil, afterDelay: 0)
        }
        
        perform(#selector(presentUserNameChooserController), with: nil, afterDelay: 0)
        
    }

    /// Presents the UserNameChooserViewController if the user hasn't set a name yet
    func presentUserNameChooserController() {
        // TODO: Replace this with a screen by screen onboarding process including check for iCloud login.
        
        let controller = OnBoardingController()
        
        if let window = self.window, let rootViewController = window.rootViewController {
            var currentController = rootViewController
            
            while let presentedController = currentController.presentedViewController {
                currentController = presentedController
            }
            currentController.present(controller, animated: true, completion: nil)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("AD: Application will terminate, saving data.")
        performanceStore.savePerformances() // save locally stored performances.
        userProfile.saveProfile() // save local copy of performance profile.
        profileStore.saveProfiles() // save local copy of performer profiles.
    }

}
