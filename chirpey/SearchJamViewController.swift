//
//  SearchJamViewController.swift
//  microjam
//
//  Created by Henrik Brustad on 03/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class SearchJamViewController: UIViewController {


    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var numberOfColoums = 2
    var numberOfRows = 2
    
    let colors = [0xF0A97E, 0xA3D0D6, 0xC2D39D, 0xA29E94]
    let categories = ["Instrument", "Username", "Description", "Genre"]
    
    let performanceStore = (UIApplication.shared.delegate as! AppDelegate).performanceStore
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "SearchCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "searchCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateCollectionView(accordingToCell cell : SearchCell) {
        
        if cell.title.text == "Username" {
            
            collectionView.backgroundColor = cell.backgroundColor!
            numberOfRows = 0
            numberOfColoums = 0
            collectionView.reloadData()
        }
    }
    
    func getData(withSearchText text : String) {
        print("Getting data with text: ", text)
        
        performanceStore.fetchRecord(withType: PerfCloudKeys.type, matchingString: text, inField: "Performer")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
            collectionView.isUserInteractionEnabled = true
        }
    }

}

extension SearchJamViewController: ModelDelegate {
    
    func errorUpdating(error: NSError) {
        
    }
    
    func modelUpdated() {
        
    }
    
    func queryCompleted(withResult result: [Any]) {
        
        print("Query is complete!")
        
        for r in result {
            print(r)
        }
    }
}

extension SearchJamViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! SearchCell
        self.updateCollectionView(accordingToCell: cell)
    }
}

extension SearchJamViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfColoums + numberOfRows
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchCell", for: indexPath) as! SearchCell
        
        let colorHex = colors[(indexPath.row + indexPath.section) % 4]
        
        let color = UIColor(red: CGFloat((colorHex & 0xff0000) >> 16) / 255.0,
                            green: CGFloat((colorHex & 0x00ff00) >> 8) / 255.0,
                            blue: CGFloat(colorHex & 0x0000ff) / 255.0,
                            alpha: 1.0)
        
        cell.backgroundColor = color
        cell.title.textColor = UIColor.white
        cell.title.text = self.categories[indexPath.row]
        
        return cell
    }
}

extension SearchJamViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        let width = self.collectionView.bounds.size.width / CGFloat(numberOfColoums)
        let height = self.collectionView.bounds.size.height / CGFloat(numberOfRows)
        
        return CGSize(width: width, height: height)
    }
}

extension SearchJamViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("Did begin editing...")
        self.collectionView.isUserInteractionEnabled = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button clicked")
        
        if let text = searchBar.text {
            getData(withSearchText: text)
        }
        
        searchBar.resignFirstResponder()
    }
}


















