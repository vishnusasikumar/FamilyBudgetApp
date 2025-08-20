//
//  BudgetMonth+CoreData.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import Foundation
import CoreData

extension BudgetMonth {
    var monthName: String { Calendar.current.monthSymbols[Int(monthIndex) - 1] }
    var title: String { "\(monthName) \(year?.year ?? 0)" }
    var entriesArray: [Entry] {
        (entries?.allObjects as? [Entry] ?? []).sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }
    var totalIncome: Double {
        entriesArray
            .filter { $0.kind == "income" }
            .reduce(0) { $0 + $1.amount }
    }
    var totalExpense: Double {
        entriesArray
            .filter { $0.kind == "expense" }
            .reduce(0) { $0 + $1.amount }
    }
    var totalSavings: Double {
        entriesArray
            .filter { $0.kind == "saving" }
            .reduce(0) { $0 + $1.amount }
    }
    var netBalance: Double { startingBalance + totalIncome - totalExpense - totalSavings }
    var endingBalance: Double { netBalance }
}
