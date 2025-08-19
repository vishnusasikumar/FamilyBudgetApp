//
//  FamilyBudgetApp.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI

@main
struct FamilyBudgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
