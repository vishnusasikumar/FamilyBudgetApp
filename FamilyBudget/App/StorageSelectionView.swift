//
//  StorageSelectionView.swift
//  FamilyBudget
//
//  Created by Admin on 20/08/2025.
//

import SwiftUI
import CloudKit
import UIKit
import CoreData

struct StorageSelectionView: View {
    var onSelect: (StorageChoice) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Where would you like to store your budgets?")
                .font(.headline)

            Button("Private iCloud") {
                select(choice: .privateICloud)
            }
            .buttonStyle(.borderedProminent)

            Button("Shared iCloud") {
                select(choice: .sharedICloud)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func select(choice: StorageChoice) {
        onSelect(choice)

        // Trigger CloudKit sharing if Shared iCloud selected
        if choice == .sharedICloud {
            triggerSharingFlow()
        }
    }

    private func triggerSharingFlow() {
        // Fetch root object to share (create if missing)
        let container = PersistenceController.defaultContainer(for: .sharedICloud)
        let context = container.viewContext

        let root: SharedRoot
        let fetchRequest: NSFetchRequest<SharedRoot> = SharedRoot.fetchRequest()
        if let existing = try? context.fetch(fetchRequest).first {
            root = existing
        } else {
            root = SharedRoot(context: context)
            try? context.save()
        }

        // Present the system CloudKit share sheet
        let share = CKShare(rootRecord: CKRecord(recordType: "SharedRoot", recordID: CKRecord.ID(recordName: "RootRecord")))
        share[CKShare.SystemFieldKey.title] = "Family Budget" as CKRecordValue

        let controller = UICloudSharingController(share: share, container: CKContainer(identifier: StorageChoice.sharedICloud.containerIdentifier))
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]

        // Use the first window's rootViewController to present
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = scene.windows.first?.rootViewController {
            controller.delegate = vc as? UICloudSharingControllerDelegate
            vc.present(controller, animated: true)
        }
    }
}

#Preview {
    StorageSelectionView { choice in
        debugPrint(choice)
    }
}
