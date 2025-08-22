//
//  CoreDataClientTests.swift
//  FamilyBudgetTests
//
//  Created by Admin on 22/08/2025.
//

import XCTest
import CoreData
@testable import FamilyBudget

final class CoreDataClientTests: XCTestCase {

    var client: CoreDataClient!

    var container: NSPersistentCloudKitContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create an in-memory Core Data container for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        container = NSPersistentCloudKitContainer(
            name: "FamilyBudget",
            managedObjectModel: NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        )
        container.persistentStoreDescriptions = [description]

        let expectation = XCTestExpectation(description: "Load persistent stores")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func testAddYearIfNeeded_returnsYear() async throws {
        client = CoreDataClient(container: container)
        let year = Int64(2025)
        let result = try await client.addYearIfNeeded(year)
        XCTAssertEqual(result.year, year)
    }

    func testFetchYears_returnsEmptyArray() async throws {
        client = CoreDataClient(container: container)
        let years = try await client.fetchYears()
        XCTAssertTrue(years.isEmpty)
    }
}
