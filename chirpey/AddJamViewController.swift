//
//  AddJamViewController.swift
//  microjam
//
//  Created by Henrik Brustad on 20/07/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class AddJamViewController: UIViewController {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(AddJamCollectionViewCell.self, forCellWithReuseIdentifier: "addJamCell")
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

extension AddJamViewController: UICollectionViewDelegate {
    
}

extension AddJamViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let viewCell : AddJamCollectionViewCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "addJamCell", for: indexPath) as! AddJamCollectionViewCell
        viewCell.image = appDelegate.storedPerformances[indexPath.row].image
        
        return viewCell
    }
    
}
