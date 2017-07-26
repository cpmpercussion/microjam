//
//  microjamUITests.swift
//  microjam
//
//  Created by Charles Martin on 20/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import XCTest

class microjamUITests: XCTestCase {
    var app: XCUIApplication!
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testScrollDownInList() {
        for _ in 1...10 {
            app.swipeUp()
        }
    }
    
}
