//
//  MonthGridView.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture
import CoreData

struct MonthGridView: View {
    let store: StoreOf<MonthGridFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewStore.months, id: \.objectID) { month in
                        Button {
                            viewStore.send(.openMonth(month.objectID))
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(month.monthName)
                                    .font(.headline)
                                    .accessibilityIdentifier("Month_\(month.monthIndex)")
                                Divider()
                                VStack(alignment: .leading) {
                                    Text("Net: \(month.netBalance, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                                    Text("End: \(month.endingBalance, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                                        .font(.caption)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(PlainButtonStyle()) // Ensures button doesn’t inherit default row styling
                    }
                }
                .padding()
            }
            .accessibilityIdentifier("MonthGridCollection")
            .navigationTitle(viewStore.months.first?.year?.year.description ?? "Year")
            .task { viewStore.send(.load) }
        }
    }
}

#Preview {
    MonthGridView(
        store: Store(
            initialState: .mock(),
            reducer: { MonthGridFeature() }
        )
    )
}
