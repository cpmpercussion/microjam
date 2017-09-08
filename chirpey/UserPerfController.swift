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

class UserPerfController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var performer: String? {
        didSet {
            navigationItem.title = performer
        }
    }
    
    var loadedPerformances = [ChirpPerformance]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.backgroundColor = .white
        fetchPerformances()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height / 5)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedPerformances.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseCell
        
        let performance = loadedPerformances[indexPath.item]
        
        cell.performance = performance
        cell.performanceImageView.image = performance.image
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
    
    func previewPerformance(sender: UIButton) {
        
        // The button is in the contentView of the cell, need to get the content view's superview...
        if let superView = sender.superview?.superview {
            let cell = superView as! BrowseCell
            ChirpView.play(performance: cell.performance!)
        }
    }

    func loadPerformances(withQueryOperation operation: CKQueryOperation) {
        
        let performanceStore = (UIApplication.shared.delegate as! AppDelegate).performanceStore
        
        operation.recordFetchedBlock = { record in
            if let performance = performanceStore.performanceFrom(record: record) {
                self.loadedPerformances.append(performance)
            }
        }
        
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
    
    func fetchPerformances() {
        
        // TODO: Find a better way to update the loaded performances
        // Should look through the loaded performances and see if some passes the filters
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        loadedPerformances = [ChirpPerformance]()
        
        let predicate = NSPredicate(format: "%K == %@", argumentArray: ["Performer", performer!])
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        loadPerformances(withQueryOperation: queryOperation)
        
        publicDB.add(queryOperation)
    }

    
    
    
    
}
