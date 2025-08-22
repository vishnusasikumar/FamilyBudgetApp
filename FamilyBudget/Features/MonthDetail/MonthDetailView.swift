//
//  MonthDetailView.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture
import CoreData

struct MonthDetailView: View {
    let store: StoreOf<MonthDetailFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                Section {
                    SummaryHeader(monthID: viewStore.monthID)
                }

                Section {
                    ForEach(viewStore.entries, id: \.objectID) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { viewStore.send(.delete($0)) }
                }
            }
            .accessibilityIdentifier("MonthDetailView")
            .navigationTitle(
                "\(viewStore.month?.monthName ?? "Month") \(viewStore.month?.year?.year.description ?? "")"
            )
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    sortMenu(viewStore: viewStore)
                    Button { viewStore.send(.addTapped) } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: viewStore.$showAdd) {
                AddEntryView(
                    store: Store(
                        initialState: AddEntryFeature.State(monthID: viewStore.monthID)
                    ) {
                        AddEntryFeature()
                    }
                )
            }
            .task {
                viewStore.send(.load)
            }
        }
    }

    // MARK: - Subviews
    private func sortMenu(viewStore: ViewStore<MonthDetailFeature.State, MonthDetailFeature.Action>) -> some View {
        // Break out binding explicitly
        let binding = viewStore.binding(get: \.sort, send: MonthDetailFeature.Action.setSort)

        return Menu {
            Picker("Sort", selection: binding) {
                ForEach(EntrySort.allCases, id: \.self) { sort in
                    Text(sort.description).tag(sort)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}

#Preview {
    NavigationStack {
        MonthDetailView(
            store: Store(
                initialState: .mock(),
                reducer: { MonthDetailFeature() }
            )
        )
    }
}
