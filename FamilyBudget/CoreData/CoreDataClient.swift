//
//  CoreDataClient.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import Foundation
import CoreData
import ComposableArchitecture

enum EntryKind: String, CaseIterable, Codable, Equatable { case income, expense, saving }

struct NewEntry: Equatable, Codable {
    var title: String = ""
    var amount: Double = 0
    var date: Date = .now
    var kind: EntryKind = .expense
    var note: String = ""
    var isCarryover: Bool = false
}

enum EntrySort: String, CaseIterable, Equatable {
    case byDateDesc, byDateAsc, byAmountDesc, byAmountAsc
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .byDateDesc: return [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
        case .byDateAsc: return [NSSortDescriptor(keyPath: \Entry.date, ascending: true)]
        case .byAmountDesc: return [NSSortDescriptor(keyPath: \Entry.amount, ascending: false)]
        case .byAmountAsc: return [NSSortDescriptor(keyPath: \Entry.amount, ascending: true)]
        }
    }

    /// Human-readable description for UI
    var description: String {
        switch self {
        case .byDateAsc:      return "Date ↑"
        case .byDateDesc:     return "Date ↓"
        case .byAmountAsc:    return "Amount ↑"
        case .byAmountDesc:   return "Amount ↓"
        }
    }
}

struct CoreDataClient {
    var context: () -> NSManagedObjectContext

    var bootstrapCurrentMonth: @Sendable () async throws -> Void
    var fetchYears: @Sendable () async throws -> [BudgetYear]
    var addYearIfNeeded: @Sendable (_ year: Int64) async throws -> BudgetYear
    var deleteYears: @Sendable (_ ids: [NSManagedObjectID]) async throws -> Void
    var monthsForYear: @Sendable (_ yearID: NSManagedObjectID) async throws -> [BudgetMonth]
    var ensureMonth: @Sendable (_ yearID: NSManagedObjectID, _ index: Int16) async throws -> BudgetMonth
    var entriesForMonth: @Sendable (_ monthID: NSManagedObjectID, _ sort: EntrySort) async throws -> [Entry]
    var addEntry: @Sendable (_ monthID: NSManagedObjectID, _ model: NewEntry) async throws -> Entry
    var deleteEntries: @Sendable (_ ids: [NSManagedObjectID]) async throws -> Void
    var fetchMonthByID: @Sendable (_ id: NSManagedObjectID) async throws -> BudgetMonth
    var fetchCurrentMonth: @Sendable () async throws -> BudgetMonth
}

extension CoreDataClient: DependencyKey {
    static var liveValue: CoreDataClient {
        CoreDataClient(container: PersistenceController.defaultContainer(for: .privateICloud))
    }

    static var testValue: CoreDataClient = CoreDataClient(
        context: { NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) },
        bootstrapCurrentMonth: { },
        fetchYears: { [] },
        addYearIfNeeded: { _ in BudgetYear() },
        deleteYears: { _ in },
        monthsForYear: { _ in [] },
        ensureMonth: { _, _ in BudgetMonth() },
        entriesForMonth: { _, _ in [] },
        addEntry: { _, _ in Entry() },
        deleteEntries: { _ in },
        fetchMonthByID: { _ in BudgetMonth() },
        fetchCurrentMonth: { BudgetMonth() }
    )
}

// Convenience initializer using a container
extension CoreDataClient {
    init(container: NSPersistentCloudKitContainer) {
        self.context = { container.viewContext }

        self.bootstrapCurrentMonth = {
            try await container.viewContext.perform {
                let calendar = Calendar.current
                let currentYear = Int64(calendar.component(.year, from: Date()))
                let currentMonth = Int16(calendar.component(.month, from: Date()))

                // Ensure year exists
                let yearReq: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
                yearReq.predicate = NSPredicate(format: "year == %d", currentYear)
                let year = try container.viewContext.fetch(yearReq).first ?? {
                    let y = BudgetYear(context: container.viewContext)
                    y.id = UUID()
                    y.year = currentYear
                    return y
                }()

                // Ensure month exists
                let monthReq: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
                monthReq.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", year, currentMonth)
                monthReq.fetchLimit = 1
                let month = try container.viewContext.fetch(monthReq).first ?? {
                    let m = BudgetMonth(context: container.viewContext)
                    m.id = UUID()
                    m.monthIndex = currentMonth
                    m.year = year
                    m.startingBalance = 0
                    if let prev = try previousMonth(forMonthIndex: currentMonth, inYear: currentYear) {
                        m.startingBalance = prev.endingBalance
                    }
                    return m
                }()
                _ = month
                try container.viewContext.save()

                func previousMonth(
                    forMonthIndex currentIndex: Int16,
                    inYear currentYear: Int64
                ) throws -> BudgetMonth? {
                    var prevIndex = Int(currentIndex) - 1
                    var prevYearVal = currentYear
                    if prevIndex < 1 {
                        prevIndex = 12
                        prevYearVal -= 1
                    }

                    let yReq: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
                    yReq.predicate = NSPredicate(format: "year == %d", prevYearVal)
                    yReq.fetchLimit = 1
                    guard let prevYear = try container.viewContext.fetch(yReq).first else { return nil }

                    let mReq: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
                    mReq.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", prevYear, prevIndex)
                    mReq.fetchLimit = 1
                    return try container.viewContext.fetch(mReq).first
                }
            }
        }

        self.fetchYears = {
            try await container.viewContext.perform {
                let request: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
                return try container.viewContext.fetch(request)
            }
        }

        self.addYearIfNeeded = { year in
            try await container.viewContext.perform {
                let req: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
                req.predicate = NSPredicate(format: "year == %d", year)
                if let existing = try container.viewContext.fetch(req).first { return existing }

                let newYear = BudgetYear(context: container.viewContext)
                newYear.id = UUID()
                newYear.year = year
                try container.viewContext.save()
                return newYear
            }
        }

        self.deleteYears = { ids in
            try await container.viewContext.perform {
                for id in ids {
                    if let obj = try? container.viewContext.existingObject(with: id) {
                        container.viewContext.delete(obj)
                    }
                }
                try container.viewContext.save()
            }
        }

        self.monthsForYear = { yearID in
            try await container.viewContext.perform {
                guard let year = try container.viewContext.existingObject(with: yearID) as? BudgetYear else { return [] }
                // ensure 12 months exist
                let existing: [BudgetMonth] = (year.months?.allObjects as? [BudgetMonth]) ?? []
                let existingIdx = Set(existing.map { Int($0.monthIndex) })
                for index in 1...12 where !existingIdx.contains(index) {
                    let budgetMonth = BudgetMonth(context: container.viewContext)
                    budgetMonth.id = UUID()
                    budgetMonth.monthIndex = Int16(index)
                    budgetMonth.year = year
                }
                try container.viewContext.save()
                let req: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
                req.predicate = NSPredicate(format: "year == %@", year)
                req.sortDescriptors = [NSSortDescriptor(keyPath: \BudgetMonth.monthIndex, ascending: true)]
                return try container.viewContext.fetch(req)
            }
        }

        self.ensureMonth = { yearID, index in
            try await container.viewContext.perform {
                guard let year = try container.viewContext.existingObject(with: yearID) as? BudgetYear else {
                    throw NSError(domain: "YearNotFound", code: 1)
                }
                let req: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
                req.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", year, index)
                req.fetchLimit = 1
                if let found = try container.viewContext.fetch(req).first { return found }
                let budgetMonth = BudgetMonth(context: container.viewContext)
                budgetMonth.id = UUID()
                budgetMonth.monthIndex = index
                budgetMonth.year = year
                try container.viewContext.save()
                return budgetMonth
            }
        }

        self.entriesForMonth = { monthID, sort in
            try await container.viewContext.perform {
                guard let month = try container.viewContext.existingObject(with: monthID) as? BudgetMonth else { return [] }
                let req: NSFetchRequest<Entry> = Entry.fetchRequest()
                req.predicate = NSPredicate(format: "month == %@", month)
                req.sortDescriptors = sort.sortDescriptors
                return try container.viewContext.fetch(req)
            }
        }

        self.addEntry = { monthID, model in
            try await container.viewContext.perform {
                guard let month = try container.viewContext.existingObject(with: monthID) as? BudgetMonth else {
                    throw NSError(domain: "MonthNotFound", code: 1)
                }
                let entry = Entry(context: container.viewContext)
                entry.title = model.title
                entry.amount = model.amount
                entry.date = model.date
                entry.kind = model.kind.rawValue
                entry.note = model.note
                entry.isCarryover = model.isCarryover
                entry.month = month
                try container.viewContext.save()
                return entry
            }
        }

        self.deleteEntries = { ids in
            try await container.viewContext.perform {
                for id in ids {
                    if let obj = try? container.viewContext.existingObject(with: id) {
                        container.viewContext.delete(obj)
                    }
                }
                try container.viewContext.save()
            }
        }

        self.fetchMonthByID = { id in
            try await container.viewContext.perform {
                guard let month = try container.viewContext.existingObject(with: id) as? BudgetMonth else {
                    throw NSError(domain: "MonthNotFound", code: 1)
                }
                try container.viewContext.save()
                return month
            }
        }

        self.fetchCurrentMonth = {
            try await container.viewContext.perform {
                let calendar = Calendar.current
                let currentYear = Int64(calendar.component(.year, from: Date()))
                let currentMonth = Int16(calendar.component(.month, from: Date()))

                let yearReq: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
                yearReq.predicate = NSPredicate(format: "year == %d", currentYear)
                let year = try container.viewContext.fetch(yearReq).first ?? {
                    let y = BudgetYear(context: container.viewContext)
                    y.id = UUID()
                    y.year = currentYear
                    return y
                }()

                let monthReq: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
                monthReq.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", year, currentMonth)
                monthReq.fetchLimit = 1

                return try container.viewContext.fetch(monthReq).first ?? {
                    let m = BudgetMonth(context: container.viewContext)
                    m.id = UUID()
                    m.monthIndex = currentMonth
                    m.year = year
                    m.startingBalance = 0
                    try container.viewContext.save()
                    return m
                }()
            }
        }
    }
}

extension DependencyValues {
    var coreData: CoreDataClient {
        get { self[CoreDataClient.self] }
        set { self[CoreDataClient.self] = newValue }
    }
}
