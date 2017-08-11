//
//  BrowseController.swift
//  microjam
//
//  Created by Henrik Brustad on 09/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

private let reuseIdentifier = "browseCell"

protocol BrowseControllerDelegate {
    
    func didSelect(performance: ChirpPerformance)
}

class BrowseController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var loadedPerformances = [ChirpPerformance]()
    
    var queryCursor: CKQueryCursor?
    var resultsLimit = 24
    
    var delegate: BrowseControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let topView = UIView()
        topView.backgroundColor = UIColor(white: 0.8, alpha: 1)
        view.addSubview(topView)
                
        collectionView?.backgroundColor = UIColor(white: 0.9, alpha: 1)
        collectionView!.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        fetchPerformances()

    }
    
    func previewPerformance(sender: UIButton) {
        
        if let superView = sender.superview {
            let cell = superView as! BrowseCell
            ChirpView.play(performance: cell.performance!)
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedPerformances.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseCell
        
        let performance = loadedPerformances[indexPath.item]
        
        cell.performance = performance
        cell.performaceImageView.image = performance.image
        cell.performerNameLabel.text = "By: " + performance.performer
        cell.listenButton.addTarget(self, action: #selector(previewPerformance(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let delegate = delegate {
            let cell = collectionView.cellForItem(at: indexPath) as! BrowseCell
            delegate.didSelect(performance: cell.performance!)
        }
    }
    
    // MARK: UICollectionViewFlowLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.width, height: 170)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: Database handling

extension BrowseController {
    
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
            // Used for continuing a search
            self.queryCursor = cursor
            
            // Reloading data on main thread when operation is complete
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
            }
        }
    }
    
    func fetchPerformances() {
        
        // TODO: Find a better way to update the loaded performances
        // Should look through the loaded performances and see if some passes the filters
        loadedPerformances = [ChirpPerformance]()
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = resultsLimit
        loadPerformances(withQueryOperation: queryOperation)
        
        publicDB.add(queryOperation)
    }
}











