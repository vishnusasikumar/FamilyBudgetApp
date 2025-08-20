//
//  MonthDetailFeature.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import ComposableArchitecture
import CoreData

struct MonthDetailFeature: Reducer {
    struct State: Equatable {
        var monthID: NSManagedObjectID
        var month: BudgetMonth?
        var entries: [Entry] = []
        var sort: EntrySort = .byDateDesc
    }
    enum Action: Equatable {
        case load
        case monthLoaded(BudgetMonth, [Entry])
        case setSort(EntrySort)
        case delete(IndexSet)
        case addTapped
    }
    @Dependency(\.coreData) var coreData

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                return .run { [id = state.monthID, sort = state.sort] send in
                    let month = try await coreData.fetchMonthByID(id)          // fetch BudgetMonth
                    let list = try await coreData.entriesForMonth(id, sort)
                    await send(.monthLoaded(month, list))
                }
            case .monthLoaded(let month, let list):
                state.month = month
                state.entries = list
                return .none
            case .setSort(let sort):
                state.sort = sort
                return .send(.load)
            case .delete(let offsets):
                let ids = offsets.map { state.entries[$0].objectID }
                return .run { _ in try await coreData.deleteEntries(ids) }
                    .concatenate(with: .send(.load))
            case .addTapped:
                return .none
            }
        }
    }
}

extension MonthDetailFeature.State {
    static func mock(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext) -> Self {
        // create a BudgetYear
        let year = BudgetYear(context: context)
        year.id = UUID()
        year.year = 2025

        // create a BudgetMonth
        let month = BudgetMonth(context: context)
        month.id = UUID()
        month.monthIndex = 8
        month.year = year
        month.startingBalance = 1000

        // create some entries
        let groceries = Entry.mock(context: context, title: "Groceries", amount: 120.50, kind: "expense")
        groceries.month = month

        let salary = Entry.mock(context: context, title: "Salary", amount: 3200, kind: "income")
        salary.month = month

        let savings = Entry.mock(context: context, title: "Savings Transfer", amount: 500, kind: "saving")
        savings.month = month

        try? context.save()

        return MonthDetailFeature.State(
            monthID: month.objectID,
            month: month,
            entries: [groceries, salary, savings],
            sort: .byDateAsc
        )
    }
}
