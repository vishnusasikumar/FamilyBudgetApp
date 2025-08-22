//
//  YearListView.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture

struct YearListView: View {
    let store: StoreOf<YearListFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewState in
            List {
                ForEach(viewState.years, id: \.objectID) { year in
                    Button(year.year.description) {
                        viewState.send(.openMonthGrid(year.objectID))
                    }
                }.onDelete {
                    viewState.send(.delete($0))
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                Button {
                    let current = Int64(Calendar.current.component(.year, from: Date()))
                    viewState.send(.addYear(current))
                } label: {
                    Image(systemName: "plus")
                }
            }
            .task {
                viewState.send(.load)
            }
        }
    }
}

#Preview {
    NavigationStack {
        YearListView(
            store: Store(
                initialState: YearListFeature.State(
                    years: [
                        BudgetYear.mock(yearValue: 2024),
                        BudgetYear.mock(yearValue: 2025)
                    ]
                )
            ) {
                YearListFeature()
            }
        )
    }
}
