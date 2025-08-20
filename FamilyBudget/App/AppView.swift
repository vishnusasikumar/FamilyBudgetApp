//
//  AppView.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture
import CoreData

struct AppView: View {
    let store: StoreOf<AppFeature>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
            YearListView(store: store.scope(state: \.yearList, action: { .yearList($0) }))
        } destination: { state in
            switch state {
            case .monthGrid:
                CaseLet(/AppFeature.Path.State.monthGrid, action: AppFeature.Path.Action.monthGrid) { MonthGridView(store: $0) }
            case .monthDetail:
                CaseLet(/AppFeature.Path.State.monthDetail, action: AppFeature.Path.Action.monthDetail) { MonthDetailView(store: $0) }
            case .addEntry:
                CaseLet(/AppFeature.Path.State.addEntry, action: AppFeature.Path.Action.addEntry) { AddEntryView(store: $0) }
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(
            initialState: .mock(),
            reducer: { AppFeature() }
        )
    )
}
