//
//  Extensions.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import Foundation
import UIKit
import CoreData

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - Preview Helpers
extension Entry {
    static func mock(
        context: NSManagedObjectContext = PersistenceController.preview.container.viewContext,
        title: String = "Sample Entry",
        amount: Double = 123.45,
        kind: String = "expense",
        date: Date = .now
    ) -> Entry {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.title = title
        entry.amount = amount
        entry.kind = kind
        entry.date = date
        try? context.save()
        return entry
    }
}

extension BudgetYear {
    static func mock(
        context: NSManagedObjectContext = PersistenceController.preview.container.viewContext,
        yearValue: Int
    ) -> BudgetYear {
        let year = BudgetYear(context: context)
        year.id = UUID()
        year.year = Int64(yearValue)
        try? context.save()
        return year
    }
}

extension BudgetMonth {
    static func mock(
        context: NSManagedObjectContext = PersistenceController.preview.container.viewContext,
        monthIndex: Int,
        yearValue: Int,
        startingBalance: Double = 0,
        incomes: [Double] = [],
        expenses: [Double] = [],
        savings: [Double] = []
    ) -> BudgetMonth {
        let year = BudgetYear.mock(context: context, yearValue: yearValue)

        let month = BudgetMonth(context: context)
        month.id = UUID()
        month.monthIndex = Int16(monthIndex) // must align with monthName calculation
        month.year = year
        month.startingBalance = startingBalance

        // add entries
        incomes.forEach {
            let entry = Entry(context: context)
            entry.id = UUID()
            entry.amount = $0
            entry.kind = "income"
            entry.date = Date()
            entry.month = month
        }
        expenses.forEach {
            let entry = Entry(context: context)
            entry.id = UUID()
            entry.amount = $0
            entry.kind = "expense"
            entry.date = Date()
            entry.month = month
        }
        savings.forEach {
            let entry = Entry(context: context)
            entry.id = UUID()
            entry.amount = $0
            entry.kind = "saving"
            entry.date = Date()
            entry.month = month
        }

        try? context.save()
        return month
    }
}

let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = .current
    return formatter
}()
