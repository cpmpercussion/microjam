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
    
    let filterView : FilterView = {
        let view = FilterView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    let dimView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
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
        button.addTarget(self, action: #selector(toggleFilterView(sender:)), for: .touchUpInside)
        button.setTitle("Filters", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
                
        collectionView!.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView!.backgroundColor = UIColor.white
        collectionView!.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        collectionView!.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        
        fetchPerformances()

    }
    
    private func setupViews() {
        let views = ["v0" : topViewContainer, "v1" : searchButton, "v2" : filterButton, "v3" : filterView]
        
        topViewContainer.addSubview(searchButton)
        topViewContainer.addSubview(filterButton)
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[v1]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[v2]|", options: [], metrics: nil, views: views))
        constraints.append(NSLayoutConstraint(item: searchButton, attribute: .width, relatedBy: .equal, toItem: topViewContainer, attribute: .width, multiplier: 0.5, constant: 0))
        constraints.append(NSLayoutConstraint(item: filterButton, attribute: .width, relatedBy: .equal, toItem: topViewContainer, attribute: .width, multiplier: 0.5, constant: 0))
        constraints.append(NSLayoutConstraint(item: filterButton, attribute: .leading, relatedBy: .equal, toItem: searchButton, attribute: .trailing, multiplier: 1.0, constant: 0))
        NSLayoutConstraint.activate(constraints)
        topViewContainer.addConstraints(constraints)
        
        dimView.frame = view.bounds
        
        view.addSubview(topViewContainer)
        view.addSubview(dimView)
        view.addSubview(filterView)
        
        constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-64-[v0(44)]", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-96-[v3]-96-|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-32-[v3]-32-|", options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(constraints)
        view.addConstraints(constraints)
    }
    
    func toggleFilterView(sender: UIButton) {
        
        print("toggle filter view")
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











