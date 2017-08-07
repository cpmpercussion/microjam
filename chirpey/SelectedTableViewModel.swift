//
//  SelectedTableViewModel.swift
//  microjam
//
//  Created by Henrik Brustad on 07/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import Foundation

class SelectedTableViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var data = ["Guitar", "Bass", "Keys", "Drums"]
    
    init(withData data: [String]) {
        super.init()
        //self.data = data
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterViewTableCell", for: indexPath) as! FilterViewTableCell
        cell.categoryLabel.text = data[indexPath.row]
        return cell
    }
}
