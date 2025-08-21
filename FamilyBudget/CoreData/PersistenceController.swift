//
//  PersistenceController.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import CoreData
import SwiftUI
import CloudKit

enum StorageChoice: String {
    case privateICloud
    case sharedICloud

    var containerIdentifier: String {
        switch self {
        case .privateICloud: return "iCloud.com.vvs.FamilyBudget.Private"
        case .sharedICloud: return "iCloud.com.vvs.FamilyBudget.Shared"
        }
    }

    var databaseScope: CKDatabase.Scope {
        switch self {
            case .privateICloud:
                return .private
            case .sharedICloud:
                return .shared   // ✅ shared database instead of per-record sharing
        }
    }
}

struct PersistenceController {

    let container: NSPersistentCloudKitContainer

    // MARK: - Preview
    static let preview: PersistenceController = {
        let controller = PersistenceController(choice: .privateICloud)
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
    init(choice: StorageChoice = .privateICloud) {
        container = NSPersistentCloudKitContainer(name: "FamilyBudget")

        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("Missing persistent store description")
        }

        let options = NSPersistentCloudKitContainerOptions(
            containerIdentifier: choice.containerIdentifier
        )
        options.databaseScope = choice.databaseScope   // ✅ private vs shared
        storeDescription.cloudKitContainerOptions = options

        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Load the store synchronously so it completes before initializing the
        // CloudKit schema.
        storeDescription.shouldAddStoreAsynchronously = false

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
        PersistenceController(choice: choice).container
    }
}
