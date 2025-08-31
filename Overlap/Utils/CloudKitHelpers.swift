//
//  CloudKitHelpers.swift
//  Overlap
//
//  Small helpers around CloudKit + SharingGRDB metadata.
//

import Foundation
import CloudKit
import SharingGRDB

/// Returns the correct CloudKit database for an `Overlap` record
/// - If the record is owned by the user (no share metadata), uses private database
/// - If the record is shared (participant), uses shared database
func databaseForOverlapRecord(id: UUID, database: any DatabaseReader) throws -> (CKContainer, CKDatabase) {
    let container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
    let isShared: Bool = try database.read { db in
        // If there is a share associated, it's in the shared DB
        let shareRef = try Overlap
            .metadata(for: id)
            .select(\.share)
            .fetchOne(db)
        return (shareRef != nil)
    }
    return (container, isShared ? container.sharedCloudDatabase : container.privateCloudDatabase)
}

/// Extracts displayable participant names from a CKShare
func participantDisplayNames(from share: CKShare) -> [String] {
    let formatter = PersonNameComponentsFormatter()
    let names: [String] = share.participants.compactMap { participant in
        if let components = participant.userIdentity.nameComponents {
            let name = formatter.string(from: components)
            if !name.isEmpty { return name }
        }
        if let email = participant.userIdentity.lookupInfo?.emailAddress { return email }
        if let phone = participant.userIdentity.lookupInfo?.phoneNumber { return phone }
        return nil
    }
    return Array(Set(names)).sorted()
}

/// Fetches the most up-to-date CKRecord for the given Overlap id
/// Chooses the correct database (private/shared) based on ownership.
func fetchLatestRecordForOverlap(id: UUID, database: any DatabaseReader) async throws -> CKRecord? {
    // Get the last known server record ID from metadata
    let lastKnownServerRecord = try await database.read { db in
        try Overlap
            .metadata(for: id)
            .select(\.lastKnownServerRecord)
            .fetchOne(db)
    }
    
    guard let lastKnownServerRecord
    else { return nil }
    
    let (container, _) = try databaseForOverlapRecord(id: id, database: database)

    let ckRecord = try await container.privateCloudDatabase
        .record(for: lastKnownServerRecord!.recordID)
    return ckRecord
}

