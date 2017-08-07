//
//  SearchJamViewController.swift
//  microjam
//
//  Created by Henrik Brustad on 03/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit


class SearchJamViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterView: FilterView!
    
    // These numbers are ment for calculating the size of the each cell
    var numberOfColoums = 3
    var numberOfRows = -1
    var numberOfItems = 24
    
    var loadedPerformances = [ChirpPerformance]()
    
    override func viewWillAppear(_ animated: Bool) {
        filterView.transform = CGAffineTransform(translationX: 0, y: 44 - filterView.frame.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "SearchCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "searchCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        filterView.delegate = self
        
        getPerformances()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getPerformances() {
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = numberOfItems
        queryOperation.recordFetchedBlock = { record in
            self.loadedPerformances.append(PerformanceStore.performanceFrom(record: record))
        }
        queryOperation.queryCompletionBlock = { (cursor, error) in
            if let error = error {
                print(error)
                return
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        publicDB.add(queryOperation)
    }
    
    func handleSearch(withSearchText text: String) {
        
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
        
        // Make the keyboard go away!
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }

}

extension SearchJamViewController: FilterViewDelegate {
    
    func didRequestShowView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.filterView.transform = .identity
        })
    }
    
    func didRequestHideView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.filterView.transform = CGAffineTransform(translationX: 0, y: 44 - self.filterView.frame.height)
        })
    }
}

extension SearchJamViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! SearchCell
    }
}

extension SearchJamViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
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
        var height = self.collectionView.bounds.size.height / CGFloat(numberOfRows)
        
        if numberOfRows < 0 {
           height = width
        }
        
        return CGSize(width: width, height: height)
    }
}

extension SearchJamViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("Did begin editing...")
        self.collectionView.isUserInteractionEnabled = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("Did end editing...")
        self.collectionView.isUserInteractionEnabled = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button clicked")
        
//        if let text = searchBar.text {
//            handleSearch(withSearchText: text)
//        }
        
        // Make the keyboard go away!
        searchBar.resignFirstResponder()
    }
}


















