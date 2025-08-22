//
//  FamilyBudgetTests.swift
//  FamilyBudgetTests
//
//  Created by Admin on 19/08/2025.
//

import Testing
import CoreData
import ComposableArchitecture
@testable import FamilyBudget

struct FamilyBudgetTests {

    // MARK: - Properties
    var client: CoreDataClient!
    var container: NSPersistentCloudKitContainer!

    init() async throws {
        // Create an in-memory Core Data container for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        container = NSPersistentCloudKitContainer(
            name: "FamilyBudget",
            managedObjectModel: NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        )
        container.persistentStoreDescriptions = [description]

        await confirmation("Load persistent stores") { expectation in
            container.loadPersistentStores { _, error in
                if error == nil {
                    expectation()
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        client = CoreDataClient(container: container)
    }

    @Test func testAddYearIfNeeded_returnsYear() async throws {
        let year: Int64 = 2025
        let result = try await client.addYearIfNeeded(year)
        #expect(result.year == year)
    }

    @Test func testFetchYears_returnsEmptyArray() async throws {
        let years = try await client.fetchYears()
        #expect(years.isEmpty)
    }

    @Test func testEnsureMonth_returnsBudgetMonth() async throws {
        let context = container.viewContext
        let year = BudgetYear(context: context)
        year.year = 2025

        try context.save()
        let yearID = year.objectID

        let monthIndex: Int16 = 3
        let month = try await client.ensureMonth(yearID, monthIndex)
        #expect(month.monthIndex == monthIndex)
    }

    @Test func testAddEntry_createsEntry() async throws {
        let context = container.viewContext
        let year = BudgetYear(context: context)
        year.year = 2025

        let month = BudgetMonth(context: context)
        month.monthIndex = 8
        month.year = year

        try context.save()
        let monthID = month.objectID
        let newEntry = NewEntry(title: "Groceries", amount: 100, date: Date(), kind: .expense, note: "", isCarryover: false)

        let entry = try await client.addEntry(monthID, newEntry)
        #expect(entry.title == "Groceries")
        #expect(entry.amount == 100)
        #expect(!entry.isCarryover)
    }

    @Test func testEntriesForMonth_returnsEmptyArray() async throws {
        let context = container.viewContext
        let year = BudgetYear(context: context)
        year.year = 2025

        let month = BudgetMonth(context: context)
        month.monthIndex = 8
        month.year = year

        try context.save()
        let monthID = month.objectID
        let entries = try await client.entriesForMonth(monthID, .byDateAsc)
        #expect(entries.isEmpty)
    }

    @Test func testDeleteEntries_doesNotThrow() async throws {
        let context = container.viewContext

        // 1. Create a year + month
        let year = BudgetYear(context: context)
        year.year = 2025

        let month = BudgetMonth(context: context)
        month.monthIndex = 8
        month.year = year

        // 2. Create an entry inside that month
        let entry = Entry(context: context)
        entry.title = "Test Entry"
        entry.amount = 50
        entry.month = month

        try context.save() // objectIDs become permanent

        // 3. Grab the objectID
        let ids = [entry.objectID]

        // 4. Call the client
        try await client.deleteEntries(ids)

        // 5. Verify it's gone
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "SELF == %@", entry.objectID)

        let results = try context.fetch(request)
        #expect(results.isEmpty)
    }

    @Test func testDeleteYears_doesNotThrow() async throws {
        let context = container.viewContext

        // 1. Create a BudgetYear
        let year = BudgetYear(context: context)
        year.year = 2025

        try context.save() // Make objectID permanent

        // 2. Grab the objectID
        let ids = [year.objectID]

        // 3. Call the client
        try await client.deleteYears(ids)

        // 4. Verify it's gone
        let request: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
        request.predicate = NSPredicate(format: "SELF == %@", year.objectID)

        let results = try context.fetch(request)
        #expect(results.isEmpty)
    }

    @Test func testFetchMonthByID_returnsMonth() async throws {
        let context = container.viewContext
        let year = BudgetYear(context: context)
        year.year = 2025

        let month = BudgetMonth(context: context)
        month.monthIndex = 8
        month.year = year

        try context.save()
        let monthID = month.objectID

        let fetchedMonth = try await client.fetchMonthByID(monthID)
        #expect(fetchedMonth.objectID == month.objectID)
    }

    @Test func testFetchCurrentMonth_returnsMonth() async throws {
        let month = try await client.fetchCurrentMonth()
        #expect(!month.monthName.isEmpty)
    }

    @Test func testMonthsForYear_returns12Months() async throws {
        let context = container.viewContext

        let year = BudgetYear(context: context)
        year.year = 2025

        try context.save()
        let yearID = year.objectID

        let months = try await client.monthsForYear(yearID)
        #expect(months.count == 12)
    }
}
