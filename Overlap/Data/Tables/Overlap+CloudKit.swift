//
//  Overlap+CloudKit.swift
//  Overlap
//
//  Created by Paul Davis on 8/31/25.
//

import CloudKit
import SharingGRDB

extension Overlap {

    /// Get our current display name
    func getCurrentUserDisplayName(database: DatabaseReader) async -> String {
        // If there is a share
        do {
            guard let share = try await fetchCKShare(database: database)
            else {
                // Fallback to user preferences
                return UserPreferences.shared.userDisplayName ?? "Anonymous"
            }

            let formatter = PersonNameComponentsFormatter()
            guard let participant = share.currentUserParticipant else {
                return UserPreferences.shared.userDisplayName ?? "Anonymous"
            }
            if let components = participant.userIdentity.nameComponents {
                let name = formatter.string(from: components)
                if !name.isEmpty { return name }
            }
            if let email = participant.userIdentity.lookupInfo?.emailAddress {
                return email
            }
            if let phone = participant.userIdentity.lookupInfo?.phoneNumber {
                return phone
            }
        }
        catch {
            print("Error getting current user identity: \(error)")
        }
        
        // Fallback to the user name
        return UserPreferences.shared.userDisplayName ?? "Anonymous"
    }

    /// Checks if we are the owner
    func isOwner(database: DatabaseReader) async -> Bool {
        // Try and get the share
        do {
            guard let share = try await fetchCKShare(database: database) else {
                return false
            }
            
            return isCurrentUserOwner(of: share)
        }
        catch {
            print("Error checking if owner \(error)")
            
            // If we are unable to get the share, assume owner if local. Otherwise there is some other issue
            return !self.isOnline
        }
    }

    /// Check if the current user is the owner of the share
    private func isCurrentUserOwner(of share: CKShare) -> Bool {
        guard let currentUserParticipant = share.currentUserParticipant else {
            return false
        }
        return currentUserParticipant.role == .owner
    }

    /// Get the CKShare object
    func fetchCKShare(database: DatabaseReader) async throws -> CKShare? {
        let shareRef: CKShare?? = try await database.read { db in
            try Overlap
                .metadata(for: self.id)
                .select(\.share)
                .fetchOne(db)
        }
        // Flatten CKShare?? -> CKShare?
        return shareRef ?? nil
    }

    func fetchLastKnownRecord(database: DatabaseReader) async throws -> CKRecord? {
        let lastKnownRecordRef: CKRecord?? = try await database.read { db in
            try Overlap
                .metadata(for: self.id)
                .select(\.lastKnownServerRecord)
                .fetchOne(db)
        }
        // Flatten CKRecord?? -> CKRecord?
        return lastKnownRecordRef ?? nil
    }

    /// Gets the most recent CKRecord for this Overlap, from the correct database
    func fetchCKRecord(database: DatabaseReader) async -> CKRecord? {
        do {
            guard
                let lastKnownServerRecord =  try await fetchLastKnownRecord(
                    database: database
                )
            else {
                return nil
            }

            let container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")

            return await withErrorReporting {
                let db: CKDatabase =
                    await isOwner(database: database)
                    ? container.privateCloudDatabase
                    : container.sharedCloudDatabase
                return try await db.record(for: lastKnownServerRecord.recordID)
            }
        }
        catch {
            print("Error getting CKRecord for Overlap: \(error)")
            return nil
        }
    }
}
