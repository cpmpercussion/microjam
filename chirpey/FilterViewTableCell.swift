//
//  FilterViewTableCell.swift
//  microjam
//
//  Created by Henrik Brustad on 07/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class FilterViewTableCell: UITableViewCell {

    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
