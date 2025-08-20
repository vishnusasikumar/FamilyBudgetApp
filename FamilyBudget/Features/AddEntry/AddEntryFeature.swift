//
//  AddEntryFeature.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import ComposableArchitecture
import CoreData

struct AddEntryFeature: Reducer {
    struct State: Equatable {
        var monthID: NSManagedObjectID
        var model = NewEntry()
    }
    enum Action: Equatable {
        case setTitle(String), setAmount(Double), setDate(Date), setKind(EntryKind), setNote(String), setCarryover(Bool)
        case saveTapped, saved
    }
    @Dependency(\.coreData) var coreData

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .setTitle(let title):
                state.model.title = title
                return .none
            case .setAmount(let amount):
                state.model.amount = amount
                return .none
            case .setDate(let date):
                state.model.date = date
                return .none
            case .setKind(let kind):
                state.model.kind = kind
                return .none
            case .setNote(let note):
                state.model.note = note
                return .none
            case .setCarryover(let isCarryover):
                state.model.isCarryover = isCarryover
                return .none
            case .saveTapped:
                return .run { [id = state.monthID, model = state.model] send in
                    _ = try await coreData.addEntry(id, model)
                    await send(.saved)
                }
            case .saved:
                return .none
            }
        }
    }
}
