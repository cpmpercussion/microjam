//
//  FilterView.swift
//  microjam
//
//  Created by Henrik Brustad on 11/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

private let reuseIdentifier = "filterCell"


class FilterView: UIView {
    
    let collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //initSubviews()
    }
    
    private func initSubviews() {
        
        collectionView.dataSource = self
        
        addSubview(collectionView)
        
        let views = ["v0" : collectionView]
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|[v0]|", options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(constraints)
        addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        cell.backgroundColor = .blue
        return cell
    }
}
