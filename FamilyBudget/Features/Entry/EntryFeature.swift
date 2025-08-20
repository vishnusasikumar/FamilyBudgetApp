//
//  EntryFeature.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import ComposableArchitecture
import CoreData

struct EntryFeature: Reducer {
    struct State: Equatable { var entryID: NSManagedObjectID }
    enum Action: Equatable { case noop }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
                .none
        }
    }
}
