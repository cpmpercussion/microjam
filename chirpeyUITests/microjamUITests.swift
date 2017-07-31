//
//  microjamUITests.swift
//  microjam
//
//  Created by Charles Martin on 20/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import XCTest

class microjamUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Should confirm that tab bar "world" button exists.
    func testTabBarExists() {
        print("Testing tab bar.")
        let app = XCUIApplication()
        print(app.tabBars.buttons.keys)
        XCTAssert(app.tabBars.buttons["world"].exists)
    }
    
    /// Just testing that the world view opens correctly on app launch.
    func testAppLoads() {
        let app = XCUIApplication()
        XCTAssert(app.navigationBars["Microjams!"].exists)
    }
    
    /// Testing Recordinga and Saving in Jam Tab
    func testRecordAndSaveJam() {
        let app = XCUIApplication()
        print(app.tabBars.buttons)
        app.tabBars.buttons["jam!"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .image).element(boundBy: 0).swipeRight()
        app.buttons["play"].tap()
        app.navigationBars["7 seconds ago"].buttons["Save"].tap()
        //        app.tabBars.buttons["world"].tap()
    }
    
    /// Tests procession through
    func testMakeUserName() {
        let app = XCUIApplication()
        let chooseAStageNameTextField = app.textFields["choose a stage name"]
        chooseAStageNameTextField.tap()
        chooseAStageNameTextField.typeText("uitestuser")
        app.buttons["Continue"].tap()
        app.typeText("\n")
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    /// Tests that changing an instrument works.
    func testSetInstrument() {
        let app = XCUIApplication()
        app.tabBars.buttons["jam!"].tap()
        app.tables.staticTexts["drums"].tap()
        
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let image = element.children(matching: .image).element(boundBy: 1)
        image.tap()
        image.tap()
        image.tap()
        image.tap()
        image.tap()
        image.tap()
        image.tap()
        image.swipeDown()
        element.tap()
        element.swipeDown()
        element.tap()
        app.navigationBars["Just now"].buttons["Save"].tap()
        
    }
    

    
}
