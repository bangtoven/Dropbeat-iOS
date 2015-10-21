//
//  DropbeatUITests.swift
//  DropbeatUITests
//
//  Created by 방정호 on 2015. 10. 21..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import XCTest

class DropbeatUITests: XCTestCase {
        
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
    
    func testExample() {
        
        let app = XCUIApplication()
        app.navigationBars["Profile"].buttons["Edit"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.cells.containingType(.Button, identifier:"ic camera").childrenMatchingType(.Button).matchingIdentifier("ic camera").elementBoundByIndex(0).tap()
        app.sheets.collectionViews.buttons["Phto Library"].tap()
        tablesQuery.buttons["Moments"].tap()
        app.collectionViews.cells["Photo, Landscape, March 12, 2011, 4:17 PM"].tap()
        app.buttons["Use"].tap()
        app.navigationBars["Edit Profile"].buttons["Save"].tap()
        
        app.navigationBars["Profile"].buttons["Edit"].tap()
        app.navigationBars["Edit Profile"].buttons["Cancel"].tap()
    }
    
}
