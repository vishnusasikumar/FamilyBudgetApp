//
//  SharedRoot.swift
//  FamilyBudget
//
//  Created by Admin on 21/08/2025.
//

import Foundation
import CloudKit
import CoreData

extension SharedRoot {

    var record: CKRecord {
        // Use a fixed recordName so the same root is shared
        let recordID = CKRecord.ID(recordName: "SharedRootRecord")
        let ckRecord = CKRecord(recordType: "SharedRoot", recordID: recordID)

        // Example: add properties you want to sync
        // If you have attributes like totalBudget, name, etc., set them here:
        // ckRecord["totalBudget"] = self.totalBudget as CKRecordValue?
        // ckRecord["name"] = self.name as CKRecordValue?

        return ckRecord
    }
}
