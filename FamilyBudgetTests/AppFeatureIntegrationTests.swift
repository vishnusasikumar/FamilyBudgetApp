//
//  AppFeatureIntegrationTests.swift
//  FamilyBudgetTests
//
//  Created by Admin on 22/08/2025.
//

import XCTest
import CoreData
import ComposableArchitecture
@testable import FamilyBudget

@MainActor
final class AppFeatureIntegrationTests: XCTestCase {

    var coreDataClient: CoreDataClient!
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create an in-memory Core Data container for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        let container = NSPersistentCloudKitContainer(
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
        context = container.viewContext
        coreDataClient = CoreDataClient(container: container)
    }

    func testFullUserFlow_AddEntry() async throws {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        ) {
            $0.coreData = coreDataClient
        }
        store.exhaustivity = .off

        // 1 Simulate app started and bootstrap current month
        await store.send(.appStarted) { state in
            state.isBootstrapped = false
        }

        // Simulate successful bootstrap
        let currentMonth = try await coreDataClient.fetchCurrentMonth()
        await store.receive(\.bootstrapFinished, timeout: 5) { state in
            state.isBootstrapped = true
            XCTAssertEqual(state.path.count, 1)
            if case let .monthDetail(detailState) = state.path[0] {
                XCTAssertEqual(detailState.monthID, currentMonth.objectID)
            }
        }

        // 2 Creating a new entry
        let monthID = currentMonth.objectID
        let newEntry = NewEntry(
            title: "Coffee",
            amount: 5.0,
            date: Date(),
            kind: .expense,
            note: "Morning coffee",
            isCarryover: false
        )

        // 3 Push AddEntryFeature onto stack
        await store.send(.path(.element(id: StackElementID(integerLiteral: 0), action: .monthDetail(.addTapped))))

        await store.send(.path(.push(id: StackElementID(integerLiteral: 1), state: .addEntry(.init(monthID: monthID, model: newEntry)))))
        let addEntryID = store.state.path.ids.last!

        await store.send(.path(.element(id: addEntryID, action: .addEntry(.saveTapped))))

        // 4 Verify entry was added in Core Data
        let entries = try await coreDataClient.entriesForMonth(monthID, .byDateAsc)
        XCTAssertTrue(entries.contains(where: { $0.title == "Coffee" && $0.amount == 5.0 }))
    }
}
