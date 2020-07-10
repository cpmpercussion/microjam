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

/// A CollectionViewController for browsing through multiple MicroJams. Not used in present Beta.
class BrowseController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var loadedPerformances = [ChirpPerformance]()
    
    var filters = [Filter]()
    var queryCursor: CKQueryOperation.Cursor?
    var resultsLimit = 24
    
    var delegate: BrowseControllerDelegate?
    
    lazy var filterView : FilterView = {
        let view = FilterView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.delegate = self
        return view
    }()
    
    let dimView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        return view
    }()
    
    let topViewContainer : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.6, alpha: 1)
        return view
    }()
    
    let searchButton : UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let filterButton : UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(toggleFilterView), for: .touchUpInside)
        button.setTitle("Filters", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView!.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView!.backgroundColor = UIColor.white
        collectionView!.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        collectionView!.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        
        setupViews()
        
        fetchPerformances()

    }
    
    private func setupViews() {
        
        view.addSubview(topViewContainer)
        
        topViewContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 64).isActive = true
        topViewContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        topViewContainer.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        topViewContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        topViewContainer.addSubview(searchButton)
        topViewContainer.addSubview(filterButton)
        
        searchButton.leftAnchor.constraint(equalTo: topViewContainer.leftAnchor).isActive = true
        searchButton.topAnchor.constraint(equalTo: topViewContainer.topAnchor).isActive = true
        searchButton.widthAnchor.constraint(equalTo: topViewContainer.widthAnchor, multiplier: 0.5).isActive = true
        searchButton.heightAnchor.constraint(equalTo: topViewContainer.heightAnchor).isActive = true
        
        filterButton.rightAnchor.constraint(equalTo: topViewContainer.rightAnchor).isActive = true
        filterButton.topAnchor.constraint(equalTo: topViewContainer.topAnchor).isActive = true
        filterButton.widthAnchor.constraint(equalTo: topViewContainer.widthAnchor, multiplier: 0.5).isActive = true
        filterButton.heightAnchor.constraint(equalTo: topViewContainer.heightAnchor).isActive = true
        
        // Dim entire screen
        tabBarController!.view.addSubview(dimView)
        tabBarController!.view.addSubview(filterView)
        
        dimView.frame = (navigationController?.view.bounds)!
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimViewTapped)))
        dimView.isHidden = true
        
        filterView.centerYAnchor.constraint(equalTo: tabBarController!.view.centerYAnchor).isActive = true
        filterView.leftAnchor.constraint(equalTo: tabBarController!.view.leftAnchor, constant: 32).isActive = true
        filterView.rightAnchor.constraint(equalTo: tabBarController!.view.rightAnchor, constant: -32).isActive = true
        filterView.heightAnchor.constraint(equalTo: filterView.widthAnchor, multiplier: 4/3).isActive = true
        filterView.isHidden = true
    }
    
    @objc func dimViewTapped() {
        toggleFilterView()
    }
    
    @objc func toggleFilterView() {
        
        if dimView.isHidden {
            dimView.isHidden = false
            filterView.isHidden = false
        } else {
            dimView.isHidden = true
            filterView.isHidden = true
        }
    }
    
    @objc func previewPerformance(sender: UIButton) {
        // The button is in the contentView of the cell, need to get the content view's superview...
        //if let superView = sender.superview?.superview {
            //let cell = superView as! BrowseCell
            // FIXME: Revise this statement to use a chirpplayer object.
            //ChirpView.play(performance: cell.performance!)
        //}
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
        cell.performanceImageView.image = performance.image
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
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
                
        if indexPath.item >= loadedPerformances.count - 1 {
            print("Should get more data...")
            loadMorePerformances()
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

extension BrowseController: FilterViewDelegate {
    
    func didAdd(filterWithCategory category: String, andValue value: String) {
        filters.append(Filter(category: category, value: value))
        print("Added filter for: ", category, value)
    }
    
    func didRemove(filterWithCategory category: String, andValue value: String) {
        
        if let i = filters.firstIndex(where: { filter in
            return filter.value == value
        }) {
            print("Removing filter at index: ", i)
            filters.remove(at: i)
        }
    }
    
    func didEndEditing() {
        fetchPerformances()
        toggleFilterView()
    }
}

// MARK: Database handling

extension BrowseController {
    
    func getFilterPredicate() -> NSPredicate {
        
        if filters.isEmpty {
            return NSPredicate(value: true)
        }
        
        var predicates = [NSPredicate]()
        
        // Creating predicates for all filters in the list
        for filter in filters {
            let predicate = NSPredicate(format: "%K == %@", argumentArray: [filter.category, filter.value.lowercased()])
            predicates.append(predicate)
        }
        
        // A series of AND predicates
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
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
            // Used for continuing a search
            self.queryCursor = cursor
            
            // Reloading data on main thread when operation is complete
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
            }
        }
    }
    
    func loadMorePerformances() {
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        if let cursor = queryCursor {
            let operation = CKQueryOperation(cursor: cursor)
            operation.resultsLimit = resultsLimit
            loadPerformances(withQueryOperation: operation)
            publicDB.add(operation)
        }
    }
    
    func fetchPerformances() {
        
        // TODO: Find a better way to update the loaded performances
        // Should look through the loaded performances and see if some passes the filters
        
        let publicDB = CKContainer.default().publicCloudDatabase
        
        loadedPerformances = [ChirpPerformance]()
        
        let predicate = getFilterPredicate()
        let query = CKQuery(recordType: PerfCloudKeys.type, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: PerfCloudKeys.date, ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = resultsLimit
        loadPerformances(withQueryOperation: queryOperation)
        
        publicDB.add(queryOperation)
    }
}











