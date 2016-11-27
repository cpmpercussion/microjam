//
//  AppDelegate.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var recordedPerformances : [ChirpPerformance] = []
    

    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        if let savedPerformances = self.loadPerformances() {
            self.recordedPerformances += savedPerformances
        } else {
            print("AD: Failed to load performances")
        }
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
    
    func applicationWillTerminate(_ application: UIApplication) {
        //
        print("AD: Application will terminate")
        self.savePerformances()
    }
    
    func loadPerformances() -> [ChirpPerformance]? {
        // load the performances

        let loadedPerformances =  NSKeyedUnarchiver.unarchiveObject(withFile: ChirpPerformance.ArchiveURL.path) as? [ChirpPerformance]

        //NSLog("AD: Loaded %d performances", loadedPerformances?.count)
        return loadedPerformances

    }
    
    
    func savePerformances() {
        // save the recordedPerformances
        NSLog("AD: Going to save %d performances", self.recordedPerformances.count)
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.recordedPerformances, toFile: ChirpPerformance.ArchiveURL.path)
        
        if (!isSuccessfulSave) {
            print("AD: Save was not successful.")
        } else {
            print("AD: %d performances successfully saved.", self.recordedPerformances.count)
        }
    }

}
