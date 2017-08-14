//
//  FilterView.swift
//  microjam
//
//  Created by Henrik Brustad on 11/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

private let reuseIdentifier = "filterCell"

protocol FilterViewDelegate {
    
    func didRemove(filterWithCategory category: String, andValue value: String)
    func didAdd(filterWithCategory category: String, andValue value: String)
    func didEndEditing()
}

class FilterView: UIView {
    
    var delegate: FilterViewDelegate?

    let categories = [BrowseCategory(name: "Instrument", values: ["Chirp", "Keys", "Drums", "Quack", "Strings", "Wub"]),
                      BrowseCategory(name: "Genre", values: ["Pop", "Rock", "Jazz", "Heavy"]),
                      BrowseCategory(name: "Username", values: []),
                      BrowseCategory(name: "Description", values: [])]
    
    let collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.register(FilterViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 38/255, green: 173/255, blue: 228/255, alpha: 1)
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    private func initSubviews() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        addSubview(collectionView)
        addSubview(doneButton)
        
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: doneButton.topAnchor).isActive = true
        
        doneButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        doneButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        doneButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    func doneButtonPressed() {
        
        if let del = delegate {
            del.didEndEditing()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilterView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width, height: (frame.height - 44) / CGFloat(categories.count))
    }
}

extension FilterView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FilterViewCell
        cell.categoryLabel.text = categories[indexPath.item].name
        cell.categoryValues = categories[indexPath.item].values
        cell.parent = self
        return cell
    }
}




























