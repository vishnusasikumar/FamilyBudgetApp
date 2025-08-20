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
    @State private var showAdd = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { vs in
            List {
                Section {
                    SummaryHeader(monthID: vs.monthID)
                }

                Section {
                    ForEach(vs.entries, id: \.objectID) { entry in
                        EntryRow(entry: entry)
                    }
                    .onDelete { vs.send(.delete($0)) }
                }
            }
            .navigationTitle("Month")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sortMenu(vs: vs)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEntryView(
                    store: Store(
                        initialState: AddEntryFeature.State(monthID: vs.monthID)
                    ) {
                        AddEntryFeature()
                    }
                )
            }
            .task {
                vs.send(.load)
            }
        }
    }

    // MARK: - Subviews
    private func sortMenu(vs: ViewStore<MonthDetailFeature.State, MonthDetailFeature.Action>) -> some View {
        // Break out binding explicitly
        let binding = vs.binding(get: \.sort, send: MonthDetailFeature.Action.setSort)

        return Menu {
            Picker("Sort", selection: binding) {
                ForEach(EntrySort.allCases, id: \.self) { sort in
                    Text(String(describing: sort)).tag(sort)
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
