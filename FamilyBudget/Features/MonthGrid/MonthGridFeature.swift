//
//  MonthGridFeature.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import ComposableArchitecture
import CoreData

struct MonthGridFeature: Reducer {
    struct State: Equatable {
        var yearID: NSManagedObjectID
        var months: [BudgetMonth] = []
    }
    enum Action: Equatable {
        case load
        case monthsLoaded([BudgetMonth])
        case openMonth(NSManagedObjectID)
    }
    @Dependency(\.coreData) var coreData

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                return .run { [yearID = state.yearID] send in
                    let ms = try await coreData.monthsForYear(yearID)
                    await send(.monthsLoaded(ms))
                }
            case .monthsLoaded(let months):
                state.months = months
                return .none
            case .openMonth:
                return .none
            }
        }
    }
}

extension MonthGridFeature.State {
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

        try? context.save()

        return MonthGridFeature.State(
            yearID: month.objectID,
            months: [
                .mock(monthIndex: 1, yearValue: 2025, startingBalance: 1000, incomes: [1500], expenses: [500]),
                .mock(monthIndex: 2, yearValue: 2025, startingBalance: 2000, incomes: [2000, 800], expenses: [2500, 300]),
                .mock(monthIndex: 3, yearValue: 2025, startingBalance: 500, incomes: [1200], expenses: [700], savings: [200])
            ]
        )
    }
}
