//
//  AddEntryView.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture
import CoreData

struct AddEntryView: View {
    let store: StoreOf<AddEntryFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                Form {
                    Section("Details") {
                        TextField("Title", text: Binding(get: { viewStore.model.title }, set: { store.send(.setTitle($0)) }))
                        TextField("Amount", value: Binding(get: { viewStore.model.amount }, set: { store.send(.setAmount($0)) }), format: .number)
                            .keyboardType(.decimalPad)
                        DatePicker("Date", selection: Binding(get: { viewStore.model.date }, set: { store.send(.setDate($0)) }), displayedComponents: .date)
                        Picker("Type", selection: Binding(get: { viewStore.model.kind }, set: { store.send(.setKind($0)) })) {
                            ForEach(EntryKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Toggle("Mark as carryover", isOn: Binding(get: { viewStore.model.isCarryover }, set: { store.send(.setCarryover($0)) }))
                        TextField("Note (optional)", text: Binding(get: { viewStore.model.note }, set: { store.send(.setNote($0)) }), axis: .vertical)
                    }
                }
                .navigationTitle("New Entry")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Add") {
                        store.send(.saveTapped)
                        dismiss()
                    }.disabled(viewStore.model.title.isEmpty || viewStore.model.amount == 0) }
                }
            }
        }
    }
}

#Preview {
    AddEntryView(
        store: Store(
            initialState: AddEntryFeature.State(
                monthID: NSManagedObjectID()
            )
        ) {
            AddEntryFeature()
        }
    )
}
