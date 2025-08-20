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

    var fetchMonthByID: @Sendable (_ id: NSManagedObjectID) async throws -> BudgetMonth?
}

extension CoreDataClient: DependencyKey {
    static let liveValue = CoreDataClient(
        context: { PersistenceController.shared.container.viewContext },
        bootstrapCurrentMonth: { try await PersistenceController.shared.bootstrapCurrentMonth() },
        fetchYears: { try await PersistenceController.shared.fetchYears() },
        addYearIfNeeded: { year in try await PersistenceController.shared.addYearIfNeeded(year: year) },
        deleteYears: { ids in try await PersistenceController.shared.delete(objectIDs: ids) },
        monthsForYear: { yearID in try await PersistenceController.shared.months(forYearID: yearID) },
        ensureMonth: { yearID, idx in try await PersistenceController.shared.ensureMonth(yearID: yearID, index: idx) },
        entriesForMonth: { monthID, sort in try await PersistenceController.shared.entries(forMonthID: monthID, sort: sort) },
        addEntry: { monthID, model in try await PersistenceController.shared.addEntry(monthID: monthID, model: model) },
        deleteEntries: { ids in try await PersistenceController.shared.delete(objectIDs: ids) },
        fetchMonthByID: { id in try await PersistenceController.shared.fetchMonth(id: id) }
    )

    static let testValue = CoreDataClient(
        context: { NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) },
        bootstrapCurrentMonth: {}, fetchYears: { [] }, addYearIfNeeded: { _ in BudgetYear() }, deleteYears: { _ in },
        monthsForYear: { _ in [] }, ensureMonth: { _, _ in BudgetMonth() },
        entriesForMonth: { _, _ in [] }, addEntry: { _, _ in Entry() }, deleteEntries: { _ in }, fetchMonthByID: { _ in nil }
    )
}

extension DependencyValues {
    var coreData: CoreDataClient {
        get { self[CoreDataClient.self] }
        set { self[CoreDataClient.self] = newValue }
    }
}

// MARK: - PersistenceController helper methods used by CoreDataClient
extension PersistenceController {
    var context: NSManagedObjectContext { container.viewContext }

    func bootstrapCurrentMonth() async throws {
        try await context.perform {
            let cal = Calendar.current
            let yVal = Int64(cal.component(.year, from: Date()))
            let mVal = Int16(cal.component(.month, from: Date()))

            let yReq: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
            yReq.predicate = NSPredicate(format: "year == %d", yVal)
            yReq.fetchLimit = 1
            let year = try self.context.fetch(yReq).first ?? {
                let budgetYear = BudgetYear(context: self.context)
                budgetYear.id = UUID()
                budgetYear.year = yVal
                return budgetYear
            }()

            let mReq: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
            mReq.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", year, mVal)
            mReq.fetchLimit = 1
            let month = try self.context.fetch(mReq).first ?? {
                let budgetMonth = BudgetMonth(context: self.context)
                budgetMonth.id = UUID()
                budgetMonth.monthIndex = mVal
                budgetMonth.year = year
                if let prev = self.previousMonth(forMonthIndex: mVal, inYear: yVal) {
                    budgetMonth.startingBalance = prev.endingBalance
                }
                return budgetMonth
            }()
            _ = month
            try self.context.save()
        }
    }

    private func previousMonth(forMonthIndex currentIndex: Int16, inYear currentYear: Int64) -> BudgetMonth? {
        var prevIndex = Int(currentIndex) - 1
        var prevYearVal = currentYear
        if prevIndex < 1 {
            prevIndex = 12
            prevYearVal -= 1
        }
        let yReq: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
        yReq.predicate = NSPredicate(format: "year == %d", prevYearVal)
        yReq.fetchLimit = 1
        guard let prevYear = try? context.fetch(yReq).first else { return nil }
        let mReq: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
        mReq.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", prevYear, prevIndex)
        mReq.fetchLimit = 1
        return try? context.fetch(mReq).first
    }

    func fetchYears() async throws -> [BudgetYear] {
        try await context.perform {
            let req: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
            req.sortDescriptors = [NSSortDescriptor(keyPath: \BudgetYear.year, ascending: true)]
            return try self.context.fetch(req)
        }
    }

    func addYearIfNeeded(year: Int64) async throws -> BudgetYear {
        try await context.perform {
            let req: NSFetchRequest<BudgetYear> = BudgetYear.fetchRequest()
            req.predicate = NSPredicate(format: "year == %d", year)
            req.fetchLimit = 1
            if let found = try self.context.fetch(req).first { return found }
            let budgetYear = BudgetYear(context: self.context)
            budgetYear.id = UUID()
            budgetYear.year = year
            try self.context.save()
            return budgetYear
        }
    }

    func months(forYearID id: NSManagedObjectID) async throws -> [BudgetMonth] {
        try await context.perform {
            guard let year = try self.context.existingObject(with: id) as? BudgetYear else { return [] }
            // ensure 12 months exist
            let existing: [BudgetMonth] = (year.months?.allObjects as? [BudgetMonth]) ?? []
            let existingIdx = Set(existing.map { Int($0.monthIndex) })
            for index in 1...12 where !existingIdx.contains(index) {
                let budgetMonth = BudgetMonth(context: self.context)
                budgetMonth.id = UUID()
                budgetMonth.monthIndex = Int16(index)
                budgetMonth.year = year
            }
            try self.context.save()
            let req: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
            req.predicate = NSPredicate(format: "year == %@", year)
            req.sortDescriptors = [NSSortDescriptor(keyPath: \BudgetMonth.monthIndex, ascending: true)]
            return try self.context.fetch(req)
        }
    }

    func ensureMonth(yearID: NSManagedObjectID, index: Int16) async throws -> BudgetMonth {
        try await context.perform {
            guard let year = try self.context.existingObject(with: yearID) as? BudgetYear else {
                throw NSError(domain: "YearNotFound", code: 1)
            }
            let req: NSFetchRequest<BudgetMonth> = BudgetMonth.fetchRequest()
            req.predicate = NSPredicate(format: "(year == %@) AND (monthIndex == %d)", year, index)
            req.fetchLimit = 1
            if let found = try self.context.fetch(req).first { return found }
            let budgetMonth = BudgetMonth(context: self.context)
            budgetMonth.id = UUID()
            budgetMonth.monthIndex = index
            budgetMonth.year = year
            try self.context.save()
            return budgetMonth
        }
    }

    func entries(forMonthID id: NSManagedObjectID, sort: EntrySort) async throws -> [Entry] {
        try await context.perform {
            guard let month = try self.context.existingObject(with: id) as? BudgetMonth else { return [] }
            let req: NSFetchRequest<Entry> = Entry.fetchRequest()
            req.predicate = NSPredicate(format: "month == %@", month)
            req.sortDescriptors = sort.sortDescriptors
            return try self.context.fetch(req)
        }
    }

    func addEntry(monthID: NSManagedObjectID, model: NewEntry) async throws -> Entry {
        try await context.perform {
            guard let month = try self.context.existingObject(with: monthID) as? BudgetMonth else {
                throw NSError(domain: "MonthNotFound", code: 1)
            }
            let entry = Entry(context: self.context)
            entry.id = UUID()
            entry.title = model.title
            entry.amount = model.amount
            entry.date = model.date
            entry.kind = model.kind.rawValue
            entry.note = model.note
            entry.isCarryover = model.isCarryover
            entry.month = month
            try self.context.save()
            return entry
        }
    }

    func delete(objectIDs: [NSManagedObjectID]) async throws {
        try await context.perform {
            for id in objectIDs { if let obj = try? self.context.existingObject(with: id) { self.context.delete(obj) } }
            try self.context.save()
        }
    }

    func fetchMonth(id: NSManagedObjectID) async throws -> BudgetMonth? {
        try await context.perform { try self.context.existingObject(with: id) as? BudgetMonth }
    }
}
