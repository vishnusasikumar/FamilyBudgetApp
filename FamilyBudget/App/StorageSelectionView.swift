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

    @State private var shareError: Error?
    @State private var shareControllerWrapper: IdentifiableSharingController?

    var body: some View {
        VStack(spacing: 20) {
            Text("Where would you like to store your budgets?")
                .font(.headline)

            Button("Private iCloud") {
                onSelect(.privateICloud)
            }
            .buttonStyle(.borderedProminent)

            Button("Shared iCloud") {
                onSelect(.sharedICloud)
                startSharingFlow()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(item: $shareControllerWrapper) { wrapper in
            CloudSharingControllerWrapper(controller: wrapper.controller)
        }
    }

    private func select(choice: StorageChoice) {
        onSelect(choice)

        // Trigger CloudKit sharing if Shared iCloud selected
        if choice == .sharedICloud {
            Task {
                await selectSharedICloud()
            }
        }
    }

    // MARK: - Helpers
    private func startSharingFlow() {
        let container = PersistenceController.defaultContainer(for: .sharedICloud)
        let context = container.viewContext

        // Fetch or create root object
        let root: SharedRoot
        let request: NSFetchRequest<SharedRoot> = SharedRoot.fetchRequest()
        if let existing = try? context.fetch(request).first {
            root = existing
        } else {
            root = SharedRoot(context: context)
            try? context.save()
        }

        // Ensure the object is saved before sharing
        context.performAndWait {
            if context.hasChanges {
                try? context.save()
            }
        }

        let ckRecord = root.record
        let share = CKShare(rootRecord: ckRecord)
        share[CKShare.SystemFieldKey.title] = "Family Budget" as CKRecordValue
        share.publicPermission = .none

        let controller = UICloudSharingController(share: share, container: CKContainer(identifier: StorageChoice.sharedICloud.containerIdentifier))
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = SharingDelegate.shared

        shareControllerWrapper = IdentifiableSharingController(controller: controller)
    }

    private func selectSharedICloud() async {
        do {
            let container = PersistenceController.defaultContainer(for: .sharedICloud)
            let context = container.viewContext

            // 1️⃣ Fetch or create the root object
            let root: SharedRoot = try await context.perform {
                let fetchRequest: NSFetchRequest<SharedRoot> = SharedRoot.fetchRequest()
                if let existing = try context.fetch(fetchRequest).first {
                    return existing
                } else {
                    let newRoot = SharedRoot(context: context)
                    newRoot.id = UUID()
                    try context.save()
                    return newRoot
                }
            }

            // 2️⃣ Make sure it's saved and pushed to CloudKit
            try await context.perform {
                if context.hasChanges {
                    try context.save()
                }
            }

            // 3️⃣ Prepare CKShare using the saved root
            let recordID = CKRecord.ID(recordName: root.id!.uuidString)
            let share = CKShare(rootRecord: CKRecord(recordType: "SharedRoot", recordID: recordID))
            share[CKShare.SystemFieldKey.title] = "Family Budget" as CKRecordValue

            // 4️⃣ Present the system share sheet
            await MainActor.run {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let vc = scene.windows.first?.rootViewController else { return }

                let controller = UICloudSharingController(
                    share: share,
                    container: CKContainer(identifier: StorageChoice.sharedICloud.containerIdentifier)
                )
                controller.availablePermissions = [.allowReadWrite, .allowPrivate]

                vc.present(controller, animated: true)
            }
        } catch {
            print("Failed to prepare shared root or present sharing sheet: \(error)")
            await MainActor.run { shareError = error }
        }
    }
}

#Preview {
    StorageSelectionView { choice in
        debugPrint(choice)
    }
}
