//
//  SummaryHeader.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import SwiftUI
import CoreData

struct SummaryHeader: View {
    var monthID: NSManagedObjectID
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        if let month = try? viewContext.existingObject(with: monthID) as? BudgetMonth {

            // Precompute values before rendering
            let currencyCode = Locale.current.currency?.identifier ?? "USD"
            let formatter = FloatingPointFormatStyle<Double>.Currency(code: currencyCode)

            let starting = month.startingBalance
            let income = month.totalIncome
            let expenses = month.totalExpense

            let net = month.netBalance
            let ending = month.endingBalance

            VStack(alignment: .leading, spacing: 8) {
                Text("Starting: \(starting, format: formatter)")
                Text("Income: \(income, format: formatter)")
                Text("Expenses: \(expenses, format: formatter)")
                Divider()
                Text("Net: \(net, format: formatter)").bold()
                Text("Ending: \(ending, format: formatter)")
                    .font(.headline)
            }
        }
    }
}

#Preview {
    let month = BudgetMonth.mock(
        monthIndex: 1,
        yearValue: 2025,
        startingBalance: 1000,
        incomes: [1500],
        expenses: [500]
    )
    SummaryHeader(monthID: month.objectID)
}
