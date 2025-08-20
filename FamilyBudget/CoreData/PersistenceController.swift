//
//  PersistenceController.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import CoreData
import SwiftUI

enum StorageChoice: String {
    case privateICloud
    case sharedICloud

    var containerIdentifier: String {
        switch self {
        case .privateICloud: return "iCloud.com.vvs.FamilyBudget.Private"
        case .sharedICloud: return "iCloud.com.vvs.FamilyBudget.Shared"
        }
    }
}

struct PersistenceController {

    let container: NSPersistentCloudKitContainer

    // MARK: - Preview
    static let preview: PersistenceController = {
        let controller = PersistenceController(containerIdentifier: StorageChoice.privateICloud.containerIdentifier)
        let viewContext = controller.container.viewContext

        for _ in 0..<10 {
            let newItem = Entry(context: viewContext)
            newItem.date = Date()
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    // MARK: - Initialization
    init(containerIdentifier: String) {
        container = NSPersistentCloudKitContainer(name: "FamilyBudget")

        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("Missing persistent store description")
        }

        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: containerIdentifier
        )
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error loading persistent store: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Default Container
    static func defaultContainer(for choice: StorageChoice) -> NSPersistentCloudKitContainer {
        PersistenceController(containerIdentifier: choice.containerIdentifier).container
    }
}
