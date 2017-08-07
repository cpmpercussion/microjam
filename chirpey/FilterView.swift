//
//  FilterView.swift
//  microjam
//
//  Created by Henrik Brustad on 07/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

protocol FilterViewDelegate {
    
    func didRequestShowView()
    func didRequestHideView()
}

class FilterView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    
    var delegate : FilterViewDelegate?
    
    let categories = ["Instrument", "Genre"]
    
    var childTableView : UITableView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    private func initSubviews() {
        let nib = UINib(nibName: "FilterView", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let cell = UINib(nibName: "FilterViewTableCell", bundle: nil)
        tableView.register(cell, forCellReuseIdentifier: "filterViewTableCell")
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    @IBAction func filterButtonPressed(_ sender: UIButton) {
        
        if let delegate = self.delegate {
            if self.transform == .identity {
                delegate.didRequestHideView()
            } else {
                delegate.didRequestShowView()
            }
        }
    }
}

extension FilterView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! FilterViewTableCell
        if cell.categoryLabel.text == "Instrument" {
            
            let data = ["Guitar", "Bass", "Drums", "Keys"]
            
            childTableView = UITableView(frame: self.tableView.frame)
            
            let cell = UINib(nibName: "FilterViewTableCell", bundle: nil)
            childTableView!.register(cell, forCellReuseIdentifier: "filterViewTableCell")
            
            let tableModel = SelectedTableViewModel(withData: data)
            childTableView!.dataSource = tableModel
            childTableView!.delegate = tableModel
            childTableView!.reloadData()
            
            childTableView!.transform = CGAffineTransform(translationX: tableView.frame.width, y: tableView.frame.origin.y)
            self.addSubview(childTableView!)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.transform = CGAffineTransform(translationX: -self.tableView.frame.width, y: self.tableView.frame.origin.y)
                self.childTableView!.transform = .identity
            })
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

extension FilterView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterViewTableCell", for: indexPath) as! FilterViewTableCell
        
        cell.categoryLabel.text = categories[indexPath.row]
        cell.categoryLabel.sizeToFit()
        cell.selectedLabel.text = ""
        
        return cell
    }
}
