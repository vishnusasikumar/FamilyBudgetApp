//
//  StorageSelectionView.swift
//  FamilyBudget
//
//  Created by Admin on 20/08/2025.
//

import SwiftUI

struct StorageSelectionView: View {
    var onSelect: (StorageChoice) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Where would you like to store your budgets?")
                .font(.headline)

            Button("Private iCloud") {
                onSelect(.privateICloud)
            }

            Button("Shared iCloud") {
                onSelect(.sharedICloud)
            }
        }
        .padding()
    }
}

#Preview {
    StorageSelectionView { choice in
        debugPrint(choice)
    }
}
