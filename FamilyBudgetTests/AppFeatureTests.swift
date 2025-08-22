//
//  AppFeatureTests.swift
//  FamilyBudgetTests
//
//  Created by Admin on 22/08/2025.
//

import XCTest
import CoreData
import ComposableArchitecture
@testable import FamilyBudget

@MainActor
final class AppFeatureTests: XCTestCase {

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

    func testAppStartupBootstrapsCurrentMonth() async throws {
        let coreDataClient = CoreDataClient(container: container)

        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        ) {
            $0.coreData = coreDataClient
        }
        store.exhaustivity = .off

        await store.send(.appStarted) { state in
            state.isBootstrapped = false
        }

        // After bootstrap, expect path to contain the current month
        let currentMonth = try await coreDataClient.fetchCurrentMonth()

        await store.receive(\.bootstrapFinished, timeout: 5) { state in
            state.isBootstrapped = true
            XCTAssertEqual(state.path.count, 1)
            if case let .monthDetail(detailState) = state.path[0] {
                XCTAssertEqual(detailState.monthID, currentMonth.objectID)
            }
        }
    }

    func testAddYearViaYearList() async throws {
        let coreDataClient = CoreDataClient(container: container)
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        ) {
            $0.coreData = coreDataClient
        }
        store.exhaustivity = .off

        let newYearValue: Int64 = 2025

        // Trigger YearList add year action
        await store.send(.yearList(.addYear(newYearValue)))

        // Verify persistence
        let fetchRequest: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "year == %d", newYearValue)
        let fetchedYears = try container.viewContext.fetch(fetchRequest)
        XCTAssertEqual(fetchedYears.count, 1)
    }

    func testNavigateToMonthFromYearList() async throws {
        let coreDataClient = CoreDataClient(container: container)

        // Pre-populate a year and month
        let year = BudgetYear(context: container.viewContext)
        year.id = UUID()
        year.year = 2024

        let month = BudgetMonth(context: container.viewContext)
        month.id = UUID()
        month.monthIndex = 3
        month.year = year

        try container.viewContext.save()

        let store = TestStore(
            initialState: AppFeature.State(context: container.viewContext),
            reducer: { AppFeature() }
        ) {
            $0.coreData = coreDataClient
        }
        store.exhaustivity = .off

        // Send action to open the month grid for 2024
        await store.send(.yearList(.openMonthGrid(year.objectID))) { state in
            XCTAssertEqual(state.path.count, 1)
            if case let .monthGrid(monthGrid) = state.path[0] {
                XCTAssertEqual(monthGrid.yearID, year.objectID)
            } else {
                XCTFail("Expected monthGrid state in path")
            }
        }

        // Navigate to the month
        await store.send(.path(.element(id: StackElementID(integerLiteral: 0), action: .monthGrid(.openMonth(month.objectID))))) { state in
            XCTAssertEqual(state.path.count, 2)
            if case let .monthDetail(detail) = state.path[1] {
                XCTAssertEqual(detail.monthID, month.objectID)
            } else {
                XCTFail("Expected monthDetail state in path")
            }
        }
    }
}
