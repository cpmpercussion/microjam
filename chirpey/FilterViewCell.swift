//
//  FilterViewCell.swift
//  microjam
//
//  Created by Henrik Brustad on 14/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

private let cellIdentifier = "valueCell"

class FilterViewCell: UICollectionViewCell {
    
    var parent: FilterView?
    
    var categoryValues: [String]?
    
    let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Category"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var valueCollection: UICollectionView = {
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.register(ValueCell.self, forCellWithReuseIdentifier: cellIdentifier)
        view.contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    let separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor(white: 0.8, alpha: 1)
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initSubviews() {
       
        contentView.addSubview(categoryLabel)
        contentView.addSubview(valueCollection)
        contentView.addSubview(separatorLine)
        
        categoryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        categoryLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8).isActive = true
        categoryLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8).isActive = true

        valueCollection.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor).isActive = true
        valueCollection.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        valueCollection.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        valueCollection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separatorLine.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        separatorLine.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        separatorLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}

extension FilterViewCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width - 16) / 3, height: (collectionView.frame.height - 12) / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}

extension FilterViewCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ValueCell {
            
            cell.addThis = !cell.addThis
            cell.valueLabel.textColor = cell.addThis ? UIColor(white: 0.8, alpha: 1) : .black
            
            if let del = parent?.delegate {
                if cell.addThis {
                    del.didAdd(filterWithCategory: categoryLabel.text!, andValue: cell.valueLabel.text!)
                } else {
                    del.didRemove(filterWithCategory: categoryLabel.text!, andValue: cell.valueLabel.text!)
                }
            }
        }
    }
}

extension FilterViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryValues!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ValueCell
        cell.valueLabel.text = categoryValues![indexPath.item]
        return cell
    }
}

class ValueCell: UICollectionViewCell {
    
    var addThis = false
    
    let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initSubviews() {
        contentView.addSubview(valueLabel)
        valueLabel.frame = contentView.bounds
    }
}
































