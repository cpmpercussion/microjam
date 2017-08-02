//
//  AddJamViewController.swift
//  microjam
//
//  Created by Henrik Brustad on 01/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

protocol AddJamDelegate {
    
    func didSelectJamAt(index : Int)
    
    func didReturnWithoutSelected()
}

class AddJamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    // Delegate to send data back to the JamView
    var delegate : AddJamDelegate?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.layer.cornerRadius = 10
    }

    @IBAction func `return`(_ sender: Any) {
        
        // User tapped outside of the collection view, just return without selecting a performance
        if let d = delegate {
            d.didReturnWithoutSelected()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension AddJamViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did select index: ", indexPath.row)
        
        if let d = delegate {
            d.didSelectJamAt(index: indexPath.row)
        }
    }
}

extension AddJamViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let viewCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "addJamCell", for: indexPath)
        viewCell.layer.cornerRadius = 6
        
        let imageView = UIImageView(frame: viewCell.bounds)
        imageView.image = appDelegate.performanceStore.storedPerformances[indexPath.row].image
        viewCell.contentView.addSubview(imageView)
        
        return viewCell
        
    }
}
