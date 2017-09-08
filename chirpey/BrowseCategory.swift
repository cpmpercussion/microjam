//
//  BrowseCategory.swift
//  microjam
//
//  Created by Henrik Brustad on 14/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import Foundation

class BrowseCategory: NSObject {
    
    let name: String
    let values: [String]
    
    init(name: String, values: [String]) {
        self.name = name
        self.values = values
    }
}
