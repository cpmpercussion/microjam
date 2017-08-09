//
//  BrowseController.swift
//  microjam
//
//  Created by Henrik Brustad on 09/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

private let reuseIdentifier = "browseCell"

class BrowseController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        self.collectionView?.backgroundColor = UIColor(white: 0.9, alpha: 1)
        self.collectionView!.register(BrowseCell.self, forCellWithReuseIdentifier: reuseIdentifier)

    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BrowseCell
        
        return cell
    }

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



class BrowseCell: UICollectionViewCell {
    
    let performaceImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.blue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let performerNameLabel : UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.red
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        initSubviews()
    }
    
    private func initSubviews() {
        addSubview(performaceImageView)
        addSubview(performerNameLabel)
        
        let views = ["v0" : performaceImageView, "v1" : performerNameLabel]
        
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]-8-[v1]-16-|", options: .alignAllTop, metrics: nil, views: views))
        
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v0]-16-|", options: .alignAllTop, metrics: nil, views: views))
        
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v1(33)]", options: .alignAllTop, metrics: nil, views: views))
        
        constraints.append(NSLayoutConstraint(item: performaceImageView, attribute: .width, relatedBy: .equal, toItem: performaceImageView, attribute: .height, multiplier: 1.0, constant: 1.0))
        
        NSLayoutConstraint.activate(constraints)
        addConstraints(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required init not implemented")
    }
}











