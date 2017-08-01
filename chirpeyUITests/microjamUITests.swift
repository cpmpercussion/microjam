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
    
    /// Test that a jam can be opened and closed from the World screen.
    func testOpenCloseJam() {
        let app = XCUIApplication()
        XCTAssert(app.navigationBars["Microjams!"].exists) // we are on the world screen.
        let firstChild = app.tables.children(matching:.any).element(boundBy: 0)
        if firstChild.exists {
            firstChild.tap() // tap first cell
        }
        XCTAssert(app.buttons["playButton"].exists) // we are on a performance screen
        app.navigationBars.buttons["Cancel"].tap() // tap cancel
        XCTAssert(app.navigationBars["Microjams!"].exists) // we are back on the world screen.

    }
    
    /// Test Scroll Down in world screen
    func testWorldScreenScrollDown() {
        let app = XCUIApplication()
        XCTAssert(app.navigationBars["Microjams!"].exists) // we are on the world screen.
        for _ in 1..<10 {
            let child = app.tables.children(matching:.any).element(boundBy: 1)
            child.swipeUp()
            child.swipeUp()
        }

    }
    
    /// Testing Recordinga and Saving in Jam Tab
    func testRecordAndSaveJam() {
        let app = XCUIApplication()
        print(app.tabBars.buttons)
        app.tabBars.buttons["jam!"].tap()
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let image = element.children(matching: .image).element(boundBy: 0)
        image.swipeRight()
        image.swipeDown()
        image.swipeLeft()
        image.swipeUp()
        app.buttons["play"].tap()
        app.navigationBars.buttons["Save"].tap()
    }
    
    /// Tests that changing an instrument and recording works.
    func testSetInstrument() {
        let app = XCUIApplication()
        app.tabBars.buttons["jam!"].tap()
        app.buttons["instrumentChooser"].tap()
        app.tables.staticTexts["strings"].tap()
        
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element
        let image = element.children(matching: .image).element(boundBy: 0)
        image.tap()
        image.swipeDown()
        image.tap()
        image.swipeRight()
        image.tap()
        image.swipeLeft()
        app.navigationBars.buttons["Save"].tap()
    }
    
    func testPlayback() {
        let app = XCUIApplication()
        app.navigationBars["Microjams!"].buttons["Add"].tap()
        
        let image = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .image).element(boundBy: 0)
        image.tap()
        image.swipeDown()
        image.tap()
        image.swipeRight()
        image.tap()
        image.swipeLeft()
        image.tap()
        app.buttons["playButton"].tap()
        app.navigationBars.buttons["Cancel"].tap()
        XCTAssert(app.navigationBars["New Performance"].exists)
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
}
