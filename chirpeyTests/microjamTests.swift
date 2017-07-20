//
//  microjamTests.swift
//  microjam
//
//  Created by Charles Martin on 20/7/17.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import XCTest
@testable import microjam

class microjamTests: XCTestCase {
    var performanceUnderTest: ChirpPerformance!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        performanceUnderTest = ChirpPerformance()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceCreated() {
        XCTAssertEqual(performanceUnderTest.performanceData.count,0,"Performance data is not empty.")
    }
    
    func testRecordTouchData() {
        performanceUnderTest.recordTouchAt(time: 0.5, x: 0.5, y: 0.5, z: 0.5, moving: false)
        performanceUnderTest.recordTouchAt(time: 0.6, x: 0.6, y: 0.6, z: 0.6, moving: true)
        performanceUnderTest.recordTouchAt(time: 0.7, x: 0.7, y: 0.7, z: 0.7, moving: false)
        
        XCTAssertEqual(performanceUnderTest.performanceData.count, 3,"Performance data was not recorded.")
    }
    
}
