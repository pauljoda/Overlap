//
//  CloudKitService.swift
//  Overlap
//
//  Simple CloudKit sharing using UICloudSharingController
//

import CloudKit
import Combine
import Foundation
import SwiftData
import SwiftUI

// Environment key for CloudKitService
private struct CloudKitServiceKey: EnvironmentKey {
    static let defaultValue = CloudKitService()
}

extension EnvironmentValues {
    var cloudKitService: CloudKitService {
        get { self[CloudKitServiceKey.self] }
        set { self[CloudKitServiceKey.self] = newValue }
    }
}

@MainActor
@Observable
class CloudKitService: ObservableObject {
    // MARK: - Properties

    let container: CKContainer
    private let privateDatabase: CKDatabase

    var isAvailable = false
    var accountStatus: CKAccountStatus = .couldNotDetermine

    // MARK: - Initialization

    init() {
        container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
        privateDatabase = container.privateCloudDatabase

        Task {
            await checkAccountStatus()
        }
    }

    // MARK: - Account Management

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                accountStatus = status
                isAvailable = (status == .available)
            }
        } catch {
            print("CloudKit account status error: \(error)")
            await MainActor.run {
                accountStatus = .couldNotDetermine
                isAvailable = false
            }
        }
    }

    // MARK: - Zone-based Sharing

    /// Creates a custom zone and prepares an overlap for sharing using UICloudSharingController
    func prepareOverlapForSharing(_ overlap: Overlap) async throws -> (
        record: CKRecord, share: CKShare
    ) {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }

        print("Preparing overlap \(overlap.id) for sharing...")

        // Create custom zone for this overlap
        let zoneID = CKRecordZone.ID(
            zoneName: "iCloud.com.pauljoda.Overlap.\(overlap.id.uuidString)"
        )
        let customZone = CKRecordZone(zoneID: zoneID)

        // Save the custom zone (handle case where it already exists)
        do {
            _ = try await privateDatabase.save(customZone)
            print("Created custom zone: \(zoneID.zoneName)")
        } catch let error as CKError {
            if error.code == .serverRecordChanged
                || error.code == .alreadyShared
            {
                // Zone might already exist, which is fine for our use case
                print(
                    "Custom zone already exists or similar conflict: \(zoneID.zoneName)"
                )
            } else {
                print("Failed to create custom zone: \(error)")
                throw error
            }
        } catch {
            print("Unexpected error creating zone: \(error)")
            throw error
        }

        // Create the overlap record in the custom zone
        let record = try createOverlapRecord(from: overlap, in: zoneID)

        // Create the share for the root record
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = overlap.title
        share.publicPermission = .none

        // Save both the record and share together with better error handling
        let operation = CKModifyRecordsOperation(
            recordsToSave: [record, share],
            recordIDsToDelete: nil
        )
        operation.savePolicy =
            CKModifyRecordsOperation.RecordSavePolicy.changedKeys
        operation.qualityOfService = QualityOfService.userInitiated

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsCompletionBlock = {
                (
                    savedRecords: [CKRecord]?,
                    deletedRecordIDs: [CKRecord.ID]?,
                    error: Error?
                ) in
                if let error = error {
                    print("CloudKit modify records error: \(error)")
                    // Check for specific error types
                    if let ckError = error as? CKError {
                        print("CKError code: \(ckError.code.rawValue)")
                        print(
                            "CKError description: \(ckError.localizedDescription)"
                        )
                    }
                    continuation.resume(throwing: error)
                } else {
                    print(
                        "Successfully saved \(savedRecords?.count ?? 0) records"
                    )
                    continuation.resume(returning: ())
                }
            }

            operation.perRecordCompletionBlock = {
                (record: CKRecord, error: Error?) in
                if let error = error {
                    print("Per-record error for \(record.recordID): \(error)")
                } else {
                    print("Successfully saved record: \(record.recordID)")
                }
            }

            privateDatabase.add(operation)
        }

        // Update the overlap with share information
        overlap.shareRecordName = share.recordID.recordName
        overlap.cloudKitRecordID = overlap.id.uuidString  // Use the overlap's own ID
        overlap.cloudKitZoneID = zoneID.zoneName
        overlap.isSharedToMe = false  // Current user is the owner, not a participant

        print("Successfully prepared overlap for sharing")
        return (record: record, share: share)
    }

    /// Gets the share for an already shared overlap
    func getShare(for overlap: Overlap) async throws -> CKShare? {
        guard let shareRecordName = overlap.shareRecordName,
            let cloudKitZoneID = overlap.cloudKitZoneID
        else {
            return nil
        }

        let zoneID = CKRecordZone.ID(zoneName: cloudKitZoneID)
        let shareRecordID = CKRecord.ID(
            recordName: shareRecordName,
            zoneID: zoneID
        )

        // IMPORTANT: For CloudKit sharing:
        // - Owners access shares and records through their private database
        // - Participants access shared records through the shared database
        // - But shares themselves are accessed differently depending on context
        
        // If this is shared to me, I need to get it from the shared database
        // If I own it, I get it from my private database
        let database = overlap.isSharedToMe 
            ? container.sharedCloudDatabase 
            : privateDatabase

        print("🔍 getShare Debug:")
        print("  - overlap.isSharedToMe: \(overlap.isSharedToMe)")
        print("  - cloudKitZoneID: \(cloudKitZoneID)")
        print("  - shareRecordName: \(shareRecordName)")
        print("  - Looking for share record: \(shareRecordID)")

        do {
            // ROBUST APPROACH: Try the appropriate database first, then fallback
            // Share records in custom zones are complex - let's handle all cases
            
            if overlap.isSharedToMe {
                print("  - Trying shared database first (participant)")
                // For participants, try shared database first
                do {
                    let record = try await container.sharedCloudDatabase.record(for: shareRecordID)
                    print("  - ✅ Found share in shared database")
                    return record as? CKShare
                } catch let error as CKError where error.code == .invalidArguments {
                    // Expected error: "Only shared zones can be accessed in the shared DB"
                    // This means we need to try a different approach for custom zones
                    print("  - ⚠️ Shared database doesn't support custom zones, trying alternative approach")
                    
                    // For custom zones, participants might need to access shares differently
                    // Try getting the share from the default zone instead
                    let defaultZoneShareID = CKRecord.ID(
                        recordName: shareRecordName,
                        zoneID: CKRecordZone.ID.default
                    )
                    do {
                        let record = try await container.sharedCloudDatabase.record(for: defaultZoneShareID)
                        print("  - ✅ Found share in shared database default zone")
                        return record as? CKShare
                    } catch {
                        print("  - ❌ Failed to find share in default zone: \(error)")
                        throw error
                    }
                } catch {
                    print("  - ❌ Unexpected error accessing shared database: \(error)")
                    throw error
                }
            } else {
                print("  - Using private database (owner)")
                // For owners, always use private database
                let record = try await privateDatabase.record(for: shareRecordID)
                print("  - ✅ Found share in private database")
                return record as? CKShare
            }
        } catch {
            print("Failed to fetch share: \(error)")
            // If the share doesn't exist anymore or can't be accessed, clear the share info
            if let ckError = error as? CKError,
                (ckError.code == .unknownItem || ckError.code == .invalidArguments)
            {
                print("Share no longer exists or can't be accessed, clearing share information")
                overlap.shareRecordName = nil
                overlap.cloudKitRecordID = nil
                overlap.cloudKitZoneID = nil
                overlap.cloudKitParticipants = nil
            }
            return nil
        }
    }

    /// Validates all shared overlaps and clears share info for deleted shares
    func validateSharedOverlaps(in modelContext: ModelContext) async {
        guard isAvailable else { return }

        let descriptor = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { overlap in
                overlap.shareRecordName != nil
            }
        )

        do {
            let sharedOverlaps = try modelContext.fetch(descriptor)
            print("🔍 Validating \(sharedOverlaps.count) shared overlaps...")

            for overlap in sharedOverlaps {
                let existingShare = try await getShare(for: overlap)
                if existingShare == nil {
                    print(
                        "🗑️ Share for overlap '\(overlap.title)' no longer exists, clearing share info"
                    )
                    // Share info was already cleared in getShare method
                }
            }

            try modelContext.save()
            print("✅ Completed validation of shared overlaps")
        } catch {
            print("⚠️ Failed to validate shared overlaps: \(error)")
        }
    }

    /// Updates participant responses for a shared overlap
    func updateOverlapResponses(_ overlap: Overlap) async throws {
        guard isAvailable, overlap.isOnline else { return }

        guard let cloudKitRecordID = overlap.cloudKitRecordID,
            let cloudKitZoneID = overlap.cloudKitZoneID
        else {
            throw CloudKitError.sharingFailed
        }

        // Debug logging
        print("🔍 updateOverlapResponses Debug:")
        print("  - overlap.isSharedToMe: \(overlap.isSharedToMe)")
        print("  - cloudKitZoneID: \(cloudKitZoneID)")
        print("  - cloudKitRecordID: \(cloudKitRecordID)")
        print(
            "  - overlap.shareRecordName: \(overlap.shareRecordName ?? "nil")"
        )
        print("  - overlap.participants: \(overlap.participants)")
        print("  - overlap.currentParticipant: \(overlap.currentParticipant ?? "nil")")
        print("  - overlap.currentParticipantIndex: \(overlap.currentParticipantIndex)")

        // CORRECT CloudKit sharing pattern per Apple documentation:
        // - Owner: uses privateDatabase (their own data)
        // - Participants: use sharedCloudDatabase (view into owner's private database)
        let database =
            overlap.isSharedToMe
            ? container.sharedCloudDatabase : privateDatabase
        print(
            "  - Using database: \(overlap.isSharedToMe ? "shared (participant)" : "private (owner)")"
        )

        // Create zone ID and record ID
        let zoneID = CKRecordZone.ID(zoneName: cloudKitZoneID)
        let recordID = CKRecord.ID(recordName: cloudKitRecordID, zoneID: zoneID)

        // Get the existing record
        let record = try await database.record(for: recordID)

        // Update the participant responses as JSON string
        let allResponses = overlap.getAllResponses()
        print("🔍 updateOverlapResponses - Raw participantResponses from overlap:")
        print("  - participantResponses keys: \(overlap.participantResponses.keys.sorted())")
        for (participant, responses) in overlap.participantResponses {
            print("  - \(participant): \(responses)")
        }
        
        print("🔍 updateOverlapResponses - getAllResponses() result:")
        for (participant, responses) in allResponses {
            let answeredCount = responses.compactMap { $0 }.count
            print("  - \(participant): \(answeredCount)/\(responses.count) answered")
            for (index, response) in responses.enumerated() {
                print("    Question \(index): \(response?.rawValue ?? "nil")")
            }
        }
        
        let responsesData = try JSONEncoder().encode(allResponses)
        let responsesString = String(data: responsesData, encoding: .utf8) ?? "{}"
        print("🔍 updateOverlapResponses - Encoded JSON: \(responsesString)")
        
        record["participantResponses"] = responsesString
        record["lastUpdated"] = Date()

        // Save the updated record
        let savedRecord = try await database.save(record)
        print("✅ Updated responses for overlap in zone: \(cloudKitZoneID)")
        print("✅ Database used: \(overlap.isSharedToMe ? "shared" : "private")")
        print("✅ Saved record ID: \(savedRecord.recordID)")
        
        // Verify the saved data
        if let verifyString = savedRecord["participantResponses"] as? String {
            print("🔍 Verification - Saved participantResponses: \(verifyString)")
        }

        // Add a small delay to ensure CloudKit has processed the update
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // After uploading our responses, fetch any new responses from other participants
        print("🔍 updateOverlapResponses: Fetching latest responses to merge with other participants")
        try await fetchAndMergeResponses(overlap)
    }

    /// Fetches the latest responses from CloudKit and merges them with local data
    func fetchAndMergeResponses(_ overlap: Overlap) async throws {
        guard isAvailable, overlap.isOnline else { return }

        guard let cloudKitRecordID = overlap.cloudKitRecordID,
            let cloudKitZoneID = overlap.cloudKitZoneID
        else {
            throw CloudKitError.sharingFailed
        }

        // Debug logging
        print("🔍 fetchAndMergeResponses Debug:")
        print("  - overlap.isSharedToMe: \(overlap.isSharedToMe)")
        print("  - cloudKitZoneID: \(cloudKitZoneID)")
        print("  - cloudKitRecordID: \(cloudKitRecordID)")
        print(
            "  - overlap.shareRecordName: \(overlap.shareRecordName ?? "nil")"
        )

        // CORRECT CloudKit sharing pattern per Apple documentation:
        // - Owner: uses privateDatabase (their own data)
        // - Participants: use sharedCloudDatabase (view into owner's private database)
        let database =
            overlap.isSharedToMe
            ? container.sharedCloudDatabase : privateDatabase
        print(
            "  - Using database: \(overlap.isSharedToMe ? "shared (participant)" : "private (owner)")"
        )

        // Create zone ID and record ID
        let zoneID = CKRecordZone.ID(zoneName: cloudKitZoneID)
        let recordID = CKRecord.ID(recordName: cloudKitRecordID, zoneID: zoneID)

        // Get the latest record from CloudKit
        let record = try await database.record(for: recordID)
        print(
            "Fetched latest record from \(overlap.isSharedToMe ? "shared (participant)" : "private (owner)") database"
        )

        // Extract and merge the participant responses
        if let responsesString = record["participantResponses"] as? String,
            let responsesData = responsesString.data(using: .utf8)
        {
            print("🔍 fetchAndMergeResponses - Raw JSON from CloudKit: \(responsesString)")
            do {
                let cloudResponses = try JSONDecoder().decode(
                    [String: [Answer?]].self,
                    from: responsesData
                )
                
                print("🔍 fetchAndMergeResponses - Decoded responses from CloudKit:")
                for (participant, responses) in cloudResponses {
                    let answeredCount = responses.compactMap { $0 }.count
                    print("  - \(participant): \(answeredCount)/\(responses.count) answered")
                    for (index, response) in responses.enumerated() {
                        print("    Question \(index): \(response?.rawValue ?? "nil")")
                    }
                }

                // Merge CloudKit responses with local responses
                for (participant, cloudResponses) in cloudResponses {
                    if overlap.participants.contains(participant) {
                        // Get current local responses for this participant
                        let localResponses = overlap.getAllResponses(for: participant) ?? []
                        
                        print("🔍 fetchAndMergeResponses - Merging for participant '\(participant)':")
                        print("  - Local responses: \(localResponses)")
                        print("  - Cloud responses: \(cloudResponses)")
                        
                        // Intelligent merging: prefer non-nil values from either source
                        var mergedResponses = localResponses
                        for (index, cloudResponse) in cloudResponses.enumerated() {
                            if index < mergedResponses.count {
                                // If cloud has a non-nil response and local is nil, use cloud
                                // If both have responses, prefer local (more recent)
                                // If local has response and cloud is nil, keep local
                                if cloudResponse != nil && mergedResponses[index] == nil {
                                    mergedResponses[index] = cloudResponse
                                    print("    - Merged question \(index): using cloud response \(cloudResponse!.rawValue)")
                                } else if mergedResponses[index] != nil {
                                    print("    - Merged question \(index): keeping local response \(mergedResponses[index]!.rawValue)")
                                } else {
                                    print("    - Merged question \(index): both nil, keeping nil")
                                }
                            }
                        }
                        
                        // Update local responses with merged data
                        overlap.setResponsesForParticipant(participant, responses: mergedResponses)
                        print("CloudKitService: Intelligently merged responses for participant '\(participant)'")
                    }
                }
                print(
                    "CloudKitService: Successfully merged responses from \(cloudResponses.count) participants"
                )
            } catch {
                print(
                    "CloudKitService: Failed to decode responses from CloudKit: \(error)"
                )
            }
        }
    }

    // MARK: - Share Acceptance (Tutorial Method)

    func shareAccepted(_ shareMetadata: CKShare.Metadata) async throws {
        print("☁️ CloudKitService: shareAccepted called")

        try await checkAccountStatus()

        // checking the participantStatus of the provided metadata. If the status is pending, accept participation in the share.
        // trying to accept the share as an owner will throw an error
        if shareMetadata.participantRole != .owner
            && shareMetadata.participantStatus == .pending
        {
            let _ = try await container.accept(shareMetadata)
            print(
                "☁️ CloudKitService: Successfully accepted share participation"
            )
        }

        // shareMetadata.rootRecord is only present if the share metadata was returned from a CKFetchShareMetadataOperation with shouldFetchRootRecord set to YES
        guard let rootRecordId = shareMetadata.hierarchicalRootRecordID else {
            throw CloudKitError.sharingFailed
        }

        // root record shows up in sharedCloudDatabase for participant and privateDatabase for owner
        let database =
            shareMetadata.participantRole == .owner
            ? privateDatabase : container.sharedCloudDatabase

        let record = try await database.record(for: rootRecordId)
        print("☁️ CloudKitService: Retrieved shared record: \(record.recordID)")

        // Create local overlap instance and add to database
        // This will be handled by the existing notification system
    }

    /// Accepts a CloudKit share and adds the overlap to the local database
    func acceptShare(
        _ shareMetadata: CKShare.Metadata,
        to modelContext: ModelContext
    ) async throws {
        print(
            "☁️ CloudKitService: Accepting share for record: \(shareMetadata.share.recordID)"
        )
        print(
            "☁️ CloudKitService: Share URL: \(shareMetadata.share.url?.absoluteString ?? "No URL")"
        )
        print("🔍 acceptShare Debug:")
        print("  - Share Zone ID: \(shareMetadata.share.recordID.zoneID)")
        print("  - Share Record ID: \(shareMetadata.share.recordID.recordName)")

        // Accept the share using CKAcceptSharesOperation (preferred method)
        let acceptOperation = CKAcceptSharesOperation(shareMetadatas: [
            shareMetadata
        ])

        let acceptedShare: CKShare = try await withCheckedThrowingContinuation {
            continuation in
            acceptOperation.acceptSharesCompletionBlock = { error in
                if let error = error {
                    print("CloudKitService: Error accepting share: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("CloudKitService: Successfully accepted share")
                    // The share is now accepted, get it from the shared database
                    Task {
                        do {
                            let sharedDatabase = self.container
                                .sharedCloudDatabase
                            let share =
                                try await sharedDatabase.record(
                                    for: shareMetadata.share.recordID
                                ) as! CKShare
                            continuation.resume(returning: share)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

            container.add(acceptOperation)
        }

        // Get the shared database
        let sharedDatabase = container.sharedCloudDatabase

        // Get the share's zone ID from the accepted share
        let shareZoneID = acceptedShare.recordID.zoneID
        print("🔍 acceptShare Zone Debug:")
        print("  - Accepted share zone ID: \(shareZoneID)")
        print("  - Looking for Overlap records in shared database...")

        // Query for the overlap record in the shared zone
        let query = CKQuery(
            recordType: "Overlap",
            predicate: NSPredicate(value: true)
        )
        let results = try await sharedDatabase.records(
            matching: query,
            inZoneWith: shareZoneID
        )
        print("🔍 acceptShare Query Results:")
        print("  - Found \(results.matchResults.count) records in shared zone")
        for (recordID, result) in results.matchResults {
            switch result {
            case .success(_):
                print("  - Record: \(recordID), Success: true")
            case .failure(let error):
                print(
                    "  - Record: \(recordID), Success: false, Error: \(error)"
                )
            }

            guard let (_, result) = results.matchResults.first,
                case .success(let record) = result
            else {
                throw CloudKitError.sharingFailed
            }

            // Create local overlap instance
            let overlap = try createOverlap(from: record)
            overlap.isSharedToMe = true
            overlap.shareRecordName = acceptedShare.recordID.recordName
            overlap.cloudKitRecordID = overlap.id.uuidString  // Use the overlap's ID which matches the record name
            overlap.cloudKitZoneID = shareZoneID.zoneName
            overlap.isOnline = true  // Mark as online since it's a shared overlap

            print("🔍 acceptShare Created Overlap:")
            print("  - Overlap ID: \(overlap.id)")
            print("  - CloudKit Zone ID: \(overlap.cloudKitZoneID ?? "nil")")
            print(
                "  - CloudKit Record ID: \(overlap.cloudKitRecordID ?? "nil")"
            )
            print("  - Share Record Name: \(overlap.shareRecordName ?? "nil")")
            print("  - isSharedToMe: \(overlap.isSharedToMe)")
            print("  - isOnline: \(overlap.isOnline)")

            // Add the current user as a participant if they're not already in the list
            let displayName =
                UserPreferences.shared.userDisplayName ?? "Anonymous User"
            await addCurrentUserAsParticipant(to: overlap)

            // Set the state for shared users - they should go directly to answering
            overlap.currentState = .answering
            // Set the current participant to the user who just joined
            if let userIndex = overlap.participants.firstIndex(of: displayName)
            {
                overlap.currentParticipantIndex = userIndex
                print(
                    "CloudKitService: Set current participant to '\(displayName)' at index \(userIndex)"
                )
            } else {
                overlap.currentParticipantIndex = 0  // Fallback
                print(
                    "CloudKitService: Warning - couldn't find user in participants, using index 0"
                )
            }
            overlap.currentQuestionIndex = 0

            print(
                "CloudKitService: Overlap state set to answering. Participants: \(overlap.participants)"
            )
            print(
                "CloudKitService: Current participant index: \(overlap.currentParticipantIndex), question index: \(overlap.currentQuestionIndex)"
            )

            // Add to local database
            modelContext.insert(overlap)
            try modelContext.save()

            print(
                "CloudKitService: Successfully joined overlap '\(overlap.title)' in zone: \(shareZoneID.zoneName)"
            )
            print(
                "CloudKitService: User added as participant, ready to answer questions"
            )
        }
    }

    /// Adds the current user as a participant to a shared overlap
    private func addCurrentUserAsParticipant(to overlap: Overlap) async {
        // Get the user's display name, defaulting to "Me" if not set
        let displayName =
            UserPreferences.shared.userDisplayName ?? "Anonymous User"

        // Check if user is already a participant
        if !overlap.participants.contains(displayName) {
            // Use the overlap's addParticipant method to properly initialize responses
            overlap.addParticipant(displayName)
            print(
                "CloudKitService: Added '\(displayName)' as participant with initialized responses"
            )
        } else {
            print(
                "CloudKitService: User '\(displayName)' already in participants list"
            )
        }
    }

    // MARK: - User Display Name

    func setManualDisplayName(_ name: String) {
        UserPreferences.shared.setDisplayName(name)
    }

    // MARK: - Record Conversion

    private func createOverlapRecord(
        from overlap: Overlap,
        in zoneID: CKRecordZone.ID
    ) throws -> CKRecord {
            let recordID = CKRecord.ID(
                recordName: overlap.id.uuidString,
                zoneID: zoneID
            )
            let record = CKRecord(recordType: "Overlap", recordID: recordID)

            // Basic properties
            record["title"] = overlap.title
            record["information"] = overlap.information
            record["instructions"] = overlap.instructions
            record["iconEmoji"] = overlap.iconEmoji
            record["beginDate"] = overlap.beginDate
            record["completeDate"] = overlap.completeDate

            // Participants and questions as arrays
            record["participants"] = overlap.participants
            record["questions"] = overlap.questions

            // Visual customization
            record["startColorRed"] = overlap.startColorRed
            record["startColorGreen"] = overlap.startColorGreen
            record["startColorBlue"] = overlap.startColorBlue
            record["startColorAlpha"] = overlap.startColorAlpha
            record["endColorRed"] = overlap.endColorRed
            record["endColorGreen"] = overlap.endColorGreen
            record["endColorBlue"] = overlap.endColorBlue
            record["endColorAlpha"] = overlap.endColorAlpha

            // Store participant responses as JSON string
            let responsesData = try JSONEncoder().encode(
                overlap.getAllResponses()
            )
            let responsesString =
                String(data: responsesData, encoding: .utf8) ?? "{}"
            record["participantResponses"] = responsesString

            // Add metadata
            record["lastUpdated"] = Date()

        return record
    }

    private func createOverlap(from record: CKRecord) throws -> Overlap {
            // Extract data from CloudKit record
            let title = record["title"] as? String ?? ""
            let information = record["information"] as? String ?? ""
            let instructions = record["instructions"] as? String ?? ""
            let questions = record["questions"] as? [String] ?? []
            let iconEmoji = record["iconEmoji"] as? String ?? "📝"
            let beginDate = record["beginDate"] as? Date ?? Date()
            let completeDate = record["completeDate"] as? Date
            let participants = record["participants"] as? [String] ?? []

            // IMPORTANT: Use the record's recordName as the overlap ID to maintain consistency
            let overlapID = UUID(uuidString: record.recordID.recordName) ?? UUID()

            // Create overlap using the convenience initializer
            let overlap = Overlap(
                id: overlapID,
                beginDate: beginDate,
                completeDate: completeDate,
                participants: participants,
                isOnline: false,  // Will be set correctly by the caller
                title: title,
                information: information,
                instructions: instructions,
                questions: questions,
                iconEmoji: iconEmoji
            )

        // Apply any additional record data
        updateOverlapFromRecord(overlap, record: record)
        return overlap
    }

    private func updateOverlapFromRecord(
        _ overlap: Overlap,
        record: CKRecord
    ) {
            // Visual customization (not handled by initializer)
            overlap.startColorRed = record["startColorRed"] as? Double ?? 0.0
            overlap.startColorGreen =
                record["startColorGreen"] as? Double ?? 0.0
            overlap.startColorBlue = record["startColorBlue"] as? Double ?? 1.0
            overlap.startColorAlpha =
                record["startColorAlpha"] as? Double ?? 1.0
            overlap.endColorRed = record["endColorRed"] as? Double ?? 0.5
            overlap.endColorGreen = record["endColorGreen"] as? Double ?? 0.0
            overlap.endColorBlue = record["endColorBlue"] as? Double ?? 0.5
            overlap.endColorAlpha = record["endColorAlpha"] as? Double ?? 1.0

            // Restore participant responses from JSON string
            if let responsesString = record["participantResponses"] as? String,
                let responsesData = responsesString.data(using: .utf8)
            {
                do {
                    let responses = try JSONDecoder().decode(
                        [String: [Answer?]].self,
                        from: responsesData
                    )
                    overlap.restoreResponses(responses)
                } catch {
                    print("Failed to decode participant responses: \(error)")
                }
            }
    }
}

// MARK: - Error Type

enum CloudKitError: LocalizedError {
    case accountNotAvailable
    case sharingFailed

    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return
                "CloudKit account is not available. Please sign in to iCloud in Settings."
        case .sharingFailed:
            return "Failed to share content."
        }
    }
}
