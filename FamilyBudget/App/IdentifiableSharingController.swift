//
//  IdentifiableSharingController.swift
//  FamilyBudget
//
//  Created by Admin on 21/08/2025.
//

import SwiftUI
import CloudKit
import SwiftUI

final class IdentifiableSharingController: NSObject, Identifiable {
    let id = UUID()
    let controller: UICloudSharingController

    init(controller: UICloudSharingController) {
        self.controller = controller
    }
}

struct CloudSharingControllerWrapper: UIViewControllerRepresentable {
    let controller: UICloudSharingController

    func makeUIViewController(context: Context) -> UICloudSharingController {
        controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // Nothing to update
    }
}

// MARK: - Simple singleton delegate for CloudKit sharing
final class SharingDelegate: NSObject, UICloudSharingControllerDelegate {
    static let shared = SharingDelegate()

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Share saved!")
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("Sharing stopped")
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share:", error)
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToStopSharingWithError error: Error) {
        print("Failed to stop sharing:", error)
    }

    // Optional: provide a default permissions UI
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Family Budget"
    }
}
