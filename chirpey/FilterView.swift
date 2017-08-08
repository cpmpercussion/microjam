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
    func didAddFilter(filter : FilterTableModel)
    func willUpdateFilter(filter : FilterTableModel)
}

class FilterView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    
    var delegate : FilterViewDelegate?
    
    var currentCategory : FilterTableModel?
    
    let categories = [FilterTableModel(withCategory: "Instrument"),
                      FilterTableModel(withCategory: "Genre")]
    
    let instruments = [FilterTableModel(withCategory: "chirp"),
                       FilterTableModel(withCategory: "keys"),
                       FilterTableModel(withCategory: "drums"),
                       FilterTableModel(withCategory: "string"),
                       FilterTableModel(withCategory: "quack"),
                       FilterTableModel(withCategory: "wub")]
    
    let genres = [FilterTableModel(withCategory: "Pop"),
                  FilterTableModel(withCategory: "Rock"),
                  FilterTableModel(withCategory: "Jazz"),
                  FilterTableModel(withCategory: "Heavey"),
                  FilterTableModel(withCategory: "EDM")]
    
    var tableData = [FilterTableModel]()
    
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
        
        tableData = categories
        
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
        
        print("Selected item with text: ", cell.categoryLabel.text!)
        
        if let category = currentCategory {
            
            if category.selected != nil {
                if let delegate = self.delegate {
                    delegate.willUpdateFilter(filter: category)
                }
            }
            
            category.selected = cell.categoryLabel.text
            
            if let delegate = self.delegate {
                delegate.didAddFilter(filter: category)
            }
            
            currentCategory = nil
            tableData = categories
            tableView.reloadData()
            
        } else {
            
            if cell.categoryLabel.text == "Instrument" {
                currentCategory = categories[0]
                tableData = instruments
                tableView.reloadData()
                
            } else if cell.categoryLabel.text == "Genre" {
                currentCategory = categories[1]
                tableData = genres
                tableView.reloadData()
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension FilterView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterViewTableCell", for: indexPath) as! FilterViewTableCell
        
        cell.categoryLabel.text = tableData[indexPath.row].category
        cell.selectedLabel.text = tableData[indexPath.row].selected
        cell.categoryLabel.sizeToFit()
        cell.selectedLabel.sizeToFit()
        
        return cell
    }
}
