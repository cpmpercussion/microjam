//
//  FilterTableModel.swift
//  microjam
//
//  Created by Henrik Brustad on 08/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class FilterTableModel: NSObject {
    
    var category : String
    var selected : String?
    
    init(withCategory category : String) {
        self.category = category
        super.init()
    }
}
