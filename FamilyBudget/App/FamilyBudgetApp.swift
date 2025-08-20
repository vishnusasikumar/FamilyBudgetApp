//
//  FamilyBudgetApp.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import ComposableArchitecture
import CoreData

@main
struct FamilyBudgetApp: App {
    // Build persistence and dependency environment
    let persistence = PersistenceController.shared
    let store = Store(
        initialState: AppFeature.State(),
        reducer: {
            AppFeature()
        }
    )

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
