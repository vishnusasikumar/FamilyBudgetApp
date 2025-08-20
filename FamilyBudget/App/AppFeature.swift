//
//  AppFeature.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture
import CoreData
import CasePaths

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var yearList = YearListFeature.State()
        var path = StackState<Path.State>()
    }

    @CasePathable
    enum Action {
        case yearList(YearListFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
    }

    @Reducer
    struct Path {
        enum State: Equatable {
            case monthGrid(MonthGridFeature.State)
            case monthDetail(MonthDetailFeature.State)
            case addEntry(AddEntryFeature.State)
        }
        enum Action: Equatable {
            case monthGrid(MonthGridFeature.Action)
            case monthDetail(MonthDetailFeature.Action)
            case addEntry(AddEntryFeature.Action)
        }
        var body: some ReducerOf<Self> {
            Scope(state: \.monthGrid, action: \.monthGrid) { MonthGridFeature() }
            Scope(state: \.monthDetail, action: \.monthDetail) { MonthDetailFeature() }
            Scope(state: \.addEntry, action: \.addEntry) { AddEntryFeature() }
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.yearList, action: \.yearList) { YearListFeature() }
        Reduce { state, action in
            switch action {
            case .yearList(.openMonthGrid(let yearID)):
                state.path.append(.monthGrid(.init(yearID: yearID)))
                return .none
            case .path(.element(id: _, action: .monthGrid(.openMonth(let monthID)))):
                state.path.append(.monthDetail(.init(monthID: monthID)))
                return .none
            case .yearList, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) { Path() }
    }
}

extension AppFeature.State {
    static func mock(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext) -> Self {
        // create years
        let year2024 = BudgetYear.mock(yearValue: 2024)
        let year2025 = BudgetYear.mock(yearValue: 2025)

        // create months for one year
        let jan = BudgetMonth.mock(context: context, monthIndex: 1, yearValue: 2025, startingBalance: 1000, incomes: [2000], expenses: [500])
        let feb = BudgetMonth.mock(context: context, monthIndex: 2, yearValue: 2025, startingBalance: 500, incomes: [1500], expenses: [200])

        return AppFeature.State(
            yearList: YearListFeature.State(years: [year2024, year2025]),
            path: StackState([
                .monthGrid(MonthGridFeature.State(yearID: year2025.objectID, months: [jan, feb]))
            ])
        )
    }
}
