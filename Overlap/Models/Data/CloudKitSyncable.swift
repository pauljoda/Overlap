//
//  CloudKitSyncable.swift
//  Overlap
//
//  Simple protocol for CloudKit record tracking with SwiftData models
//  Based on: https://yingjiezhao.com/en/articles/Implementing-iCloud-Sync-by-Combining-SwiftData-with-CKSyncEngine/
//

import Foundation
import CloudKit
import SwiftData

/// Simple protocol for SwiftData models that can be tracked with CloudKit
protocol CloudKitSyncable {
    /// The unique identifier for this model
    var id: UUID { get }
    
    /// Data storage for the last known CloudKit record (for conflict resolution)
    var lastKnownRecordData: Data? { get set }
    
    /// Convert this model to a CloudKit record
    func populateRecord(_ record: CKRecord)
    
    /// Update this model from a CloudKit record
    func mergeFromServerRecord(_ record: CKRecord)
}

extension CloudKitSyncable {
    /// Computed property for easy access to the last known CloudKit record
    var lastKnownRecord: CKRecord? {
        get {
            guard let data = lastKnownRecordData else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKRecord.self,
                from: data
            )
        }
        set {
            guard let record = newValue else {
                lastKnownRecordData = nil
                return
            }
            lastKnownRecordData = try? NSKeyedArchiver.archivedData(
                withRootObject: record,
                requiringSecureCoding: true
            )
        }
    }
}