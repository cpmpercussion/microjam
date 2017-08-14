//
//  Filter.swift
//  microjam
//
//  Created by Henrik Brustad on 14/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import Foundation

class Filter: NSObject {
    
    var category : String
    var value : String
    
    init(category : String, value: String) {
        self.category = category
        self.value = value
    }
}
