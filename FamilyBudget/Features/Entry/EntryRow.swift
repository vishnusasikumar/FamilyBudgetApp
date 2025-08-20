//
//  EntryRow.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI

struct EntryRow: View {
    let entry: Entry
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.title ?? "Untitled")
                Text(entry.date ?? Date(), style: .date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.amount as NSNumber, formatter: currencyFormatter)
        }
    }
}

#Preview {
    VStack {
        EntryRow(entry: .mock(title: "Groceries", amount: 120.50, kind: "expense"))
        EntryRow(entry: .mock(title: "Salary", amount: 3000.00, kind: "income"))
        EntryRow(entry: .mock(title: "Savings Transfer", amount: 500.00, kind: "saving"))
    }
    .padding()
}
