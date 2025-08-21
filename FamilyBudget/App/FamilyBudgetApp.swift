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
    @AppStorage("selectedStorageChoice") private var selectedStorageChoiceRaw: String?
    @State private var container: NSPersistentCloudKitContainer?

    var body: some Scene {
        WindowGroup {
            if let container {
                let coreDataClient = CoreDataClient(container: container)

                // ✅ Main App
                AppView(
                    store: Store(
                        initialState: AppFeature
                            .State(context: container.viewContext),
                        reducer: { AppFeature() }
                    ) {
                        $0.coreData = coreDataClient
                    }
                )
                .environment(\.managedObjectContext, container.viewContext)

            } else if let storedChoice = storedChoice {
                // ✅ User already picked before → boot container immediately
                ProgressView("Loading...")
                    .task {
                        container = PersistenceController(
                            choice: storedChoice
                        ).container
                    }

            } else {
                // ✅ Ask only once
                StorageSelectionView { choice in
                    saveChoice(choice)
                    container = PersistenceController(
                        choice: choice
                    ).container
                }
            }
        }
    }

    // MARK: - Helpers
    private var storedChoice: StorageChoice? {
        guard let raw = selectedStorageChoiceRaw else { return nil }
        return StorageChoice(rawValue: raw)
    }

    private func saveChoice(_ choice: StorageChoice) {
        selectedStorageChoiceRaw = choice.rawValue
    }
}
