//
//  MicrojamUITest.swift
//  microjam
//
//  Created by Charles Martin on 16/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import XCTest

class MicrojamUITest: XCTestCase {
    var app: XCUIApplication!
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUserNameChooserDisplay() {
        app.launch()
        XCTAssertTrue(app.otherElements["usernamechoosingview"].exists)
    }
    
}
