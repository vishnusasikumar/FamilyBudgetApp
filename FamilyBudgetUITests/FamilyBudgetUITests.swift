//
//  FamilyBudgetUITests.swift
//  FamilyBudgetUITests
//
//  Created by Admin on 19/08/2025.
//

import XCTest
import SwiftUI
import ComposableArchitecture
@testable import FamilyBudget

final class FamilyBudgetUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSelectingPrivateICloud_callsOnSelect() throws {
        // Wait for StorageSelectionView buttons
        let privateButton = app.buttons["Private iCloud"]
        let sharedButton = app.buttons["Shared iCloud"]

        XCTAssertTrue(privateButton.waitForExistence(timeout: 5), "Private iCloud button should appear on first launch")
        XCTAssertTrue(sharedButton.waitForExistence(timeout: 5), "Shared iCloud button should appear on first launch")

        // Simulate user selecting Private iCloud
        privateButton.tap()

        // After selection, main AppView should load
        let mainTitle = app.staticTexts["Budgets"] // adjust if you have a different main title
        XCTAssertTrue(mainTitle.waitForExistence(timeout: 5))
    }

    func testSelectingSharedICloud_callsOnSelectAndSharingFlow() throws {
        let sharedButton = app.buttons["Shared iCloud"]
        XCTAssertTrue(sharedButton.waitForExistence(timeout: 5))

        sharedButton.tap()

        // After selection, main AppView should load
        let mainTitle = app.staticTexts["Budgets"] // adjust if you have a different main title
        XCTAssertTrue(mainTitle.waitForExistence(timeout: 5))
    }

    func testAddYearAndVerifyMonths() throws {
        try testSelectingPrivateICloud_callsOnSelect()

        let yearList = app.collectionViews["YearListTable"]
        XCTAssertTrue(yearList.waitForExistence(timeout: 5))

        let addYearButton = app.buttons["AddYearButton"]
        XCTAssertTrue(addYearButton.exists)
        addYearButton.tap()

        // Verify the year now exists in the list
        let newYear = "2025"
        let newYearButton = yearList.buttons["Year_\(newYear)"]
        XCTAssertTrue(newYearButton.waitForExistence(timeout: 2))

        // Tap on the new year to open its MonthGrid
        newYearButton.tap()

        // Verify all 12 months exist
        let monthGrid = app.scrollViews["MonthGridCollection"]
        XCTAssertTrue(monthGrid.waitForExistence(timeout: 2))

        for monthIndex in 1...12 {
            let monthCell = monthGrid.buttons["Month_\(monthIndex)"]
            XCTAssertTrue(monthCell.exists, "Month \(monthIndex) should exist")
        }

        let firstMonthButton = monthGrid.buttons["Month_1"]
        firstMonthButton.tap()

        let monthDetailView = app.collectionViews["MonthDetailView"]
        XCTAssertTrue(monthDetailView.waitForExistence(timeout: 2))
    }

    func testDeleteYear() throws {
        try testSelectingSharedICloud_callsOnSelectAndSharingFlow()

        let yearList = app.collectionViews["YearListTable"]
        XCTAssertTrue(yearList.waitForExistence(timeout: 5))

        let addYearButton = app.buttons["AddYearButton"]
        XCTAssertTrue(addYearButton.exists)
        addYearButton.tap()

        // Swipe to delete first year
        let firstYearCell = yearList.cells.firstMatch
        XCTAssertTrue(firstYearCell.exists)
        firstYearCell.swipeLeft()
        app.buttons["Delete"].tap()

        // Assert the cell is gone
        XCTAssertFalse(firstYearCell.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
