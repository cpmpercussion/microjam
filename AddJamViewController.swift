//
//  AddJamViewController.swift
//  microjam
//
//  Created by Henrik Brustad on 01/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class AddJamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AddJamViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
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
        imageView.image = appDelegate.storedPerformances[indexPath.row].image
        viewCell.contentView.addSubview(imageView)
        
        return viewCell
        
    }
}
