//
//  UserPerfController.swift
//  microjam
//
//  Created by Henrik Brustad on 15/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

private let reuseIdentifier = "browseCell"

/// Displays all performances by a particular performer ID in a UICollectionView
class UserPerfController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    /// Global performance store singleton
    let performanceStore = (UIApplication.shared.delegate as! AppDelegate).performanceStore
    /// The performer to be displayed.
    var performer: String? {
        didSet {
            navigationItem.title = performer
        }
    }
    var performerID: CKRecordID?
    /// Performances by performer
    var loadedPerformances = [ChirpPerformance]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.backgroundColor = .white
        //        fetchPerformances() // retrieve performances for "performer" from CoudKit
        if let performerID = performerID {
            print("UserPerfController: fetching performances for:", performerID)
            fetchPerformances(createdBy: performerID)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 3.5, height: view.frame.width / 3.5)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedPerformances.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseCell
        let performance = loadedPerformances[indexPath.item]
        // Set up cell with performance data
        cell.performance = performance
        cell.performanceImageView.image = performance.image
        cell.performanceImageView.backgroundColor = performance.backgroundColour
        cell.performerNameLabel.text = "By: " + performance.performer
        cell.listenButton.addTarget(self, action: #selector(previewPerformance(sender:)), for: .touchUpInside)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "chirpJamController") as! ChirpJamViewController
        //controller.newViewWith(performance: loadedPerformances[indexPath.item], withFrame: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    /// Plays back the performance in each Browse Cell when the listen button is tapped.
    @objc func previewPerformance(sender: UIButton) {
        if let superView = sender.superview?.superview {
            let cell = superView as! BrowseCell
            ChirpView.play(performance: cell.performance!)
        }
    }

    /// Load performances from CloudKit matching a given query operation.
    func loadPerformances(withQueryOperation operation: CKQueryOperation) {
        // converts each retrieved performance individually.
        operation.recordFetchedBlock = { record in
            if let performance = self.performanceStore.performanceFrom(record: record) {
                self.loadedPerformances.append(performance)
            }
        }
        
        // reloads collectionView once all performances are fetched.
        operation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                print(error)
                return
            }
            // Reloading data on main thread when operation is complete
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
            }
        }
    }
    
    /// fetch performances for a given creatorID
    func fetchPerformances(createdBy creatorID: CKRecordID) {
        let publicDB = CKContainer.default().publicCloudDatabase
        loadedPerformances = [ChirpPerformance]()
        let predicate = NSPredicate(format: "%K == %@", argumentArray: ["creatorUserRecordID", creatorID])
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        loadPerformances(withQueryOperation: queryOperation)
        publicDB.add(queryOperation)
    }

}
