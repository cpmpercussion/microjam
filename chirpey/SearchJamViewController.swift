//
//  SearchJamViewController.swift
//  microjam
//
//  Created by Henrik Brustad on 03/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

protocol SearchJamDelegate {
    
    func didSelect(performance: ChirpPerformance)
}

class SearchJamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterView: FilterView!
    
    // These numbers are ment for calculating the size of the each cell
    var numberOfColoums = 3
    
    var filters = [FilterTableModel]()
    var loadedPerformances = [ChirpPerformance]()
    var queryCursor : CKQueryCursor?
    var resultsLimit = 24
    
    var delegate : SearchJamDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        filterView.transform = CGAffineTransform(translationX: 0, y: 44 - filterView.frame.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "SearchCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "searchCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        filterView.delegate = self
        
        getPerformances()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFilterPredicate() -> NSPredicate {
        
        if filters.isEmpty {
            return NSPredicate(value: true)
        }
        
        var predicates = [NSPredicate]()
        
        // Creating predicates for all filters in the list
        for filter in filters {
            let predicate = NSPredicate(format: "%K == %@", argumentArray: [filter.category, filter.selected!])
            predicates.append(predicate)
        }
        
        // A series of AND predicates
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    func loadPerformances(withQueryOperation operation: CKQueryOperation) {
        
        operation.recordFetchedBlock = { record in
            self.loadedPerformances.append(PerformanceStore.performanceFrom(record: record))
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
                self.collectionView.reloadData()
            }
        }
    }
    
    func loadMoreData() {
        
        if let cursor = queryCursor { // Continuing a previous search
            
            let publicDB = CKContainer.default().publicCloudDatabase

            let queryOperation = CKQueryOperation(cursor: cursor)
            queryOperation.resultsLimit = resultsLimit
            loadPerformances(withQueryOperation: queryOperation)
            publicDB.add(queryOperation)
        }
    }
    
    func getPerformances() {
        
        // TODO: Find a better way to update the loaded performances
        // Should look through the loaded performances and see if some passes the filters
        loadedPerformances = [ChirpPerformance]()
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        let predicate = getFilterPredicate()
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = resultsLimit
        loadPerformances(withQueryOperation: queryOperation)
        publicDB.add(queryOperation)
    }
    
    func handleSearch(withSearchText text: String) {
        
        // TODO: Implement more search related stuff
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        var records = [CKRecord]()
        
        let predicate = NSPredicate(format: "Performer == %@", argumentArray: [text])
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { (result:[CKRecord]?, error:Error?) in
            
            if let e = error {
                print(e)
                return
            }
            
            if let r = result {
                records = r
            }
            
            print("Query is complete!")
            print(records)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

}

extension SearchJamViewController: UINavigationBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension SearchJamViewController: FilterViewDelegate {
    
    func didRequestShowView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.filterView.transform = .identity
        })
    }
    
    func didRequestHideView() {
        getPerformances()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.filterView.transform = CGAffineTransform(translationX: 0, y: 44 - self.filterView.frame.height)
        })
    }
    
    func willUpdateFilter(filter: FilterTableModel) {
        // Updating filters, for now just removing the filter because it will be added again later
        if let index = filters.index(of: filter) {
            print("Removing filter at: ", index)
            filters.remove(at: index)
        }
    }
    
    func didAddFilter(filter: FilterTableModel) {
        filters.append(filter)
    }
}

extension SearchJamViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let del = delegate {
            del.didSelect(performance: loadedPerformances[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.row >= loadedPerformances.count - 1 {
            print("Should fetch more data!")
            loadMoreData()
        }
    }
}

extension SearchJamViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedPerformances.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchCell", for: indexPath) as! SearchCell
        
        if !loadedPerformances.isEmpty {
            cell.imageView.image = loadedPerformances[indexPath.row].image
        }
        
        return cell
    }
}

extension SearchJamViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = self.collectionView.bounds.size.width / CGFloat(numberOfColoums)
        
        return CGSize(width: width, height: width)
    }
}


















