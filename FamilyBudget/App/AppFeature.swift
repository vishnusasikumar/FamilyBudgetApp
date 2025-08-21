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
        var isBootstrapped = false
    }

    @CasePathable
    enum Action {
        case yearList(YearListFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
        case appStarted
        case bootstrapFinished(Result<BudgetMonth, Error>)
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

    @Dependency(\.coreData) var coreData

    var body: some ReducerOf<Self> {
        Scope(state: \.yearList, action: \.yearList) { YearListFeature() }

        Reduce { state, action in
            switch action {
            case .appStarted:
                state.isBootstrapped = false
                return .run { send in
                    do {
                        try await coreData.bootstrapCurrentMonth()
                        let month = try await coreData.fetchCurrentMonth()
                        await send(.bootstrapFinished(.success(month)))
                    } catch {
                        await send(.bootstrapFinished(.failure(error)))
                    }
                }

            case .bootstrapFinished(let result):
                state.isBootstrapped = true
                switch result {
                case .success(let currentMonth):
                    state.path.append(.monthDetail(.init(monthID: currentMonth.objectID)))
                case .failure(let error):
                    print("Bootstrap failed: \(error)")
                }
                return .none

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

/// We’ll check Core Data on startup for the current year/month.
/// If found, we’ll push .monthDetail, otherwise fall back to showing YearList.
extension AppFeature.State {
    init(context: NSManagedObjectContext) {
        // Get current year/month
        let now = Date()
        let calendar = Calendar.current
        let yearValue = Int64(calendar.component(.year, from: now))
        let monthIndex = Int16(calendar.component(.month, from: now))

        // Try to fetch the current BudgetMonth
        let request = BudgetMonth.fetchRequest()
        request.predicate = NSPredicate(
            format: "year.year == %d AND monthIndex == %d",
            yearValue, monthIndex
        )
        request.fetchLimit = 1

        if let currentMonth = try? context.fetch(request).first {
            // Month exists → open MonthDetail directly
            self.yearList = YearListFeature.State()
            self.path = StackState([.monthDetail(.init(monthID: currentMonth.objectID))])
        } else {
            // Month doesn't exist → show YearList
            let allYears = (try? context.fetch(BudgetYear.fetchRequest())) ?? []
            self.yearList = YearListFeature.State(years: allYears)
            self.path = StackState()
        }

        self.isBootstrapped = true
    }

    static func mock(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext) -> Self {
        // Create mock years
        let year2024 = BudgetYear.mock(yearValue: 2024)
        let year2025 = BudgetYear.mock(yearValue: 2025)

        // Create a mock month for 2025
        let jan = BudgetMonth.mock(
            context: context,
            monthIndex: 1,
            yearValue: 2025,
            startingBalance: 1000,
            incomes: [2000],
            expenses: [500]
        )

        return AppFeature.State(
            yearList: YearListFeature.State(years: [year2024, year2025]),
            path: StackState([.monthDetail(.init(monthID: jan.objectID))]),
            isBootstrapped: true
        )
    }
}
