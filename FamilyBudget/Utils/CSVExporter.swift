//
//  CSVExporter.swift
//  FamilyBudget
//
//  Created by Admin on 19/08/2025.
//

import Foundation
import UIKit

enum CSVExporter {
    static func exportEntries(_ entries: [Entry]) {
        var csv = "Title,Date,Type,Amount,Note,IsCarryover\n"
        let dateFormatter = ISO8601DateFormatter()
        for entry in entries {
            let row = [
                escape(entry.title ?? ""),
                dateFormatter.string(from: entry.date ?? Date()),
                entry.kind ?? "",
                String(format: "%.2f", entry.amount),
                escape(entry.note ?? ""),
                entry.isCarryover ? "true" : "false"
            ].joined(separator: ",")
            csv.append(row + "\n")
        }
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                            .appendingPathComponent("BudgetExport_\(Int(Date().timeIntervalSince1970)).csv")
        try? csv.data(using: .utf8)?.write(to: tmp)
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?
                .keyWindow?.rootViewController?.present(activityViewController, animated: true)
        }
    }

    private static func escape(_ string: String) -> String {
        string.contains(",") ? "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\"" : string
    }
}
