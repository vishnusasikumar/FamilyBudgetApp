//
//  CloudSharingView.swift
//  FamilyBudget
//
//  Created by Admin on 21/08/2025.
//

import SwiftUI
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
}

//#Preview {
//    CloudSharingView()
//}
