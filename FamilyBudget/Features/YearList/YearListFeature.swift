//
//  YearListFeature.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import ComposableArchitecture
import CoreData

struct YearListFeature: Reducer {
    struct State: Equatable {
        var years: [BudgetYear] = []
    }
    enum Action: Equatable {
        case load
        case yearsLoaded([BudgetYear])
        case addYear(Int64)
        case delete(IndexSet)
        case openMonthGrid(NSManagedObjectID)
    }
    @Dependency(\.coreData) var coreData

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                return .run { send in
                    let ys = try await coreData.fetchYears()
                    await send(.yearsLoaded(ys))
                }
            case .yearsLoaded(let ys):
                state.years = ys
                return .none
            case .addYear(let year):
                return .run { send in
                    _ = try await coreData.addYearIfNeeded(year)
                    await send(.load)
                }
            case .delete(let offsets):
                let ids = offsets.map { state.years[$0].objectID }
                return .run { _ in try await coreData.deleteYears(ids) }
                    .concatenate(with: .send(.load))
            case .openMonthGrid:
                return .none
            }
        }
    }
}
