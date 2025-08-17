//
//  CloudKitService.swift
//  Overlap
//
//  CloudKit service for managing shared overlap sessions
//

import CloudKit
import SwiftUI
import SwiftData
import Combine

@MainActor
class CloudKitService: ObservableObject {
    // MARK: - Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    @Published var isAvailable = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var hasUnreadChanges = false
    @Published var userDisplayName: String?
    
    // MARK: - Initialization
    
    init() {
        container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
        Task {
            await checkAccountStatus()
            await fetchUserDisplayName()
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
    
    /// Fetches the current CloudKit user's display name
    func fetchUserDisplayName() async {
        guard isAvailable else { return }
        
        do {
            // Try to get user identity first
            let userRecordID = try await container.userRecordID()
            print("CloudKit: Got user record ID: \(userRecordID.recordName)")
            
            var displayName = "CloudKit User"
            
            // Try to discover user identity (this requires user discoverability to be enabled)
            do {
                let userIdentity = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKUserIdentity, Error>) in
                    container.discoverUserIdentity(withUserRecordID: userRecordID) { identity, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let identity = identity {
                            continuation.resume(returning: identity)
                        } else {
                            continuation.resume(throwing: CKError(.userIdentityLookupFailed))
                        }
                    }
                }
                
                // Successfully got user identity, extract display name
                if let nameComponents = userIdentity.nameComponents {
                    if let givenName = nameComponents.givenName {
                        displayName = givenName
                        if let familyName = nameComponents.familyName {
                            displayName += " \(familyName)"
                        }
                    }
                }
                print("CloudKit: Successfully got user identity display name: \(displayName)")
                
            } catch {
                print("CloudKit: User identity discovery failed (likely discoverability not enabled): \(error)")
                // This is expected if user hasn't enabled discoverability, so continue with fallback
            }
            
            // If we still have the default name, try alternative approaches
            if displayName == "CloudKit User" {
                // Extract a user-friendly ID from the record name if possible
                let recordName = userRecordID.recordName
                if recordName.hasPrefix("_") && recordName.count > 8 {
                    // Take first 8 characters after the underscore for a short ID
                    let shortID = String(recordName.dropFirst().prefix(8))
                    displayName = "User \(shortID)"
                }
                print("CloudKit: Using fallback display name: \(displayName)")
            }
            
            await MainActor.run {
                self.userDisplayName = displayName
            }
            print("CloudKit: Final user display name: \(displayName)")
            
        } catch {
            print("CloudKit: Failed to fetch user record ID: \(error)")
            await MainActor.run {
                self.userDisplayName = "CloudKit User"
            }
        }
    }
    
    // MARK: - Sharing Operations
    
    /// Creates a CloudKit share for an overlap session
    func shareOverlap(_ overlap: Overlap) async throws -> CKShare {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }
        
        print("CloudKit: Starting share creation for overlap: \(overlap.title)")
        
        // Create a custom zone for this overlap
        let zoneID = CKRecordZone.ID(zoneName: overlap.id.uuidString, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        
        print("CloudKit: Creating custom zone: \(zoneID.zoneName)")
        
        // Try to save the zone (ignore if it already exists)
        do {
            let savedZone = try await privateDatabase.save(zone)
            print("CloudKit: Successfully created zone: \(savedZone.zoneID.zoneName)")
        } catch let error as CKError {
            switch error.code {
            case .serverRecordChanged, .unknownItem:
                print("CloudKit: Zone already exists or similar issue, continuing...")
            case .zoneNotFound:
                print("CloudKit: Zone operation issue, continuing...")
            default:
                print("CloudKit: Zone creation error: \(error.localizedDescription), continuing anyway...")
            }
        } catch {
            print("CloudKit: General zone error: \(error.localizedDescription), continuing anyway...")
        }
        
        // Create the overlap record in the custom zone
        let recordID = CKRecord.ID(recordName: overlap.id.uuidString, zoneID: zoneID)
        let overlapRecord = CKRecord(recordType: "Overlap", recordID: recordID)
        
        // Populate the record with overlap data
        try populateRecord(overlapRecord, with: overlap)
        
        print("CloudKit: Created CKRecord with ID: \(overlapRecord.recordID.recordName) in zone: \(zoneID.zoneName)")
        
        // Create share using the record
        let share = CKShare(rootRecord: overlapRecord)
        share[CKShare.SystemFieldKey.title] = overlap.title
        share[CKShare.SystemFieldKey.shareType] = "com.pauljoda.Overlap.overlap"
        share[CKShare.SystemFieldKey.thumbnailImageData] = nil // Could add thumbnail data here
        share.publicPermission = .none
        print("CloudKit: Created CKShare with title: \(overlap.title)")
        
        // Save both record and share together
        let (saveResults, _) = try await privateDatabase.modifyRecords(
            saving: [overlapRecord, share],
            deleting: []
        )
        
        print("CloudKit: Successfully completed save operation with \(saveResults.count) results")
        
        // Extract successful records from the results
        var savedRecords: [CKRecord] = []
        for (recordID, result) in saveResults {
            switch result {
            case .success(let record):
                savedRecords.append(record)
                print("CloudKit: Saved record: \(type(of: record)) - ID: \(recordID.recordName)")
                if let savedShare = record as? CKShare {
                    print("CloudKit: Found CKShare with URL: \(savedShare.url?.absoluteString ?? "no URL yet")")
                    // Return the saved share immediately if we found it
                    print("CloudKit: Share creation completed successfully")
                    return savedShare
                }
            case .failure(let error):
                print("CloudKit: Failed to save record \(recordID.recordName): \(error)")
            }
        }
        
        // Fallback: if we didn't find a saved share, return the original
        print("CloudKit: No saved CKShare found in results, returning original share")
        return share
    }
    
    /// Accepts a CloudKit share invitation
    func acceptShare(with metadata: CKShare.Metadata) async throws -> Overlap {
        let share = try await container.accept(metadata)
        
        // Fetch the root record using the metadata's rootRecordID
        let recordID = metadata.rootRecordID
        let record = try await sharedDatabase.record(for: recordID)
        
        // Convert back to Overlap
        return try Overlap.from(ckRecord: record)
    }
    
    /// Syncs local overlap with CloudKit
    func syncOverlap(_ overlap: Overlap) async throws {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }
        
        print("CloudKit: Syncing overlap: \(overlap.title)")
        let record = try overlap.toCKRecord()
        print("CloudKit: Created record for sync with ID: \(record.recordID.recordName)")
        
        let _ = try await privateDatabase.save(record)
        print("CloudKit: Successfully synced overlap to CloudKit")
    }
    
    /// Fetches updates for shared overlaps
    func fetchSharedOverlapUpdates() async throws -> [Overlap] {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }
        
        // For shared database, we need to fetch shares first, then get the records
        // SharedDB doesn't support zone-wide queries directly
        print("CloudKit: Fetching shared overlap updates...")
        
        var overlaps: [Overlap] = []
        
        // Get all shared record zones
        let zones = try await sharedDatabase.allRecordZones()
        print("CloudKit: Found \(zones.count) shared zones")
        
        for zone in zones {
            // Skip the default zone for shared databases
            if zone.zoneID.zoneName == CKRecordZone.default().zoneID.zoneName {
                continue
            }
            
            // Query for Overlap records in this specific zone
            let query = CKQuery(recordType: "Overlap", predicate: NSPredicate(value: true))
            
            do {
                let (matchResults, _) = try await sharedDatabase.records(
                    matching: query,
                    inZoneWith: zone.zoneID
                )
                
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        do {
                            let overlap = try Overlap.from(ckRecord: record)
                            overlaps.append(overlap)
                        } catch {
                            print("Failed to convert record to overlap: \(error)")
                        }
                    case .failure(let error):
                        print("Failed to fetch record: \(error)")
                    }
                }
            } catch {
                print("Failed to query zone \(zone.zoneID.zoneName): \(error)")
            }
        }
        
        print("CloudKit: Retrieved \(overlaps.count) shared overlaps")
        return overlaps
    }
    
    // MARK: - Private Helper Methods
    
    /// Populates a CKRecord with overlap data
    private func populateRecord(_ record: CKRecord, with overlap: Overlap) throws {
        // Basic properties
        record["title"] = overlap.title
        record["information"] = overlap.information
        record["instructions"] = overlap.instructions
        record["questions"] = overlap.questions
        record["participants"] = overlap.participants
        record["beginDate"] = overlap.beginDate
        record["completeDate"] = overlap.completeDate
        record["isCompleted"] = overlap.isCompleted
        record["isOnline"] = overlap.isOnline
        record["currentState"] = overlap.currentState.rawValue
        record["currentParticipantIndex"] = overlap.currentParticipantIndex
        record["currentQuestionIndex"] = overlap.currentQuestionIndex
        
        // Visual properties
        record["iconEmoji"] = overlap.iconEmoji
        record["startColorRed"] = overlap.startColorRed
        record["startColorGreen"] = overlap.startColorGreen
        record["startColorBlue"] = overlap.startColorBlue
        record["startColorAlpha"] = overlap.startColorAlpha
        record["endColorRed"] = overlap.endColorRed
        record["endColorGreen"] = overlap.endColorGreen
        record["endColorBlue"] = overlap.endColorBlue
        record["endColorAlpha"] = overlap.endColorAlpha
        
        // Randomization
        record["isRandomized"] = overlap.isRandomized
        
        // Responses (convert to JSON)
        if let responsesData = try? JSONEncoder().encode(overlap.getAllResponses()) {
            record["participantResponses"] = String(data: responsesData, encoding: .utf8)
        }
    }
}

// MARK: - CloudKit Error Types

enum CloudKitError: LocalizedError {
    case accountNotAvailable
    case recordConversionFailed
    case shareNotFound
    case zoneCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "CloudKit account is not available"
        case .recordConversionFailed:
            return "Failed to convert data for CloudKit"
        case .shareNotFound:
            return "CloudKit share not found"
        case .zoneCreationFailed:
            return "Failed to create CloudKit zone"
        }
    }
}

// MARK: - Overlap CloudKit Extensions

extension Overlap {
    /// Converts an Overlap to a CKRecord for CloudKit storage
    func toCKRecord(in zoneID: CKRecordZone.ID? = nil) throws -> CKRecord {
        let recordID: CKRecord.ID
        if let zoneID = zoneID {
            recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        } else {
            recordID = CKRecord.ID(recordName: id.uuidString)
        }
        
        let record = CKRecord(recordType: "Overlap", recordID: recordID)
        
        // Basic properties
        record["title"] = title
        record["information"] = information
        record["instructions"] = instructions
        record["questions"] = questions
        record["participants"] = participants
        record["beginDate"] = beginDate
        record["completeDate"] = completeDate
        record["isCompleted"] = isCompleted
        record["isOnline"] = isOnline
        record["currentState"] = currentState.rawValue
        record["currentParticipantIndex"] = currentParticipantIndex
        record["currentQuestionIndex"] = currentQuestionIndex
        
        // Visual properties
        record["iconEmoji"] = iconEmoji
        record["startColorRed"] = startColorRed
        record["startColorGreen"] = startColorGreen
        record["startColorBlue"] = startColorBlue
        record["startColorAlpha"] = startColorAlpha
        record["endColorRed"] = endColorRed
        record["endColorGreen"] = endColorGreen
        record["endColorBlue"] = endColorBlue
        record["endColorAlpha"] = endColorAlpha
        
        // Randomization
        record["isRandomized"] = isRandomized
        
        // Responses (convert to JSON)
        if let responsesData = try? JSONEncoder().encode(getAllResponses()) {
            record["participantResponses"] = String(data: responsesData, encoding: .utf8)
        }
        
        return record
    }
    
    /// Creates an Overlap from a CKRecord
    static func from(ckRecord record: CKRecord) throws -> Overlap {
        guard let title = record["title"] as? String,
              let information = record["information"] as? String,
              let instructions = record["instructions"] as? String,
              let questions = record["questions"] as? [String],
              let participants = record["participants"] as? [String],
              let beginDate = record["beginDate"] as? Date
        else {
            throw CloudKitError.recordConversionFailed
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let completeDate = record["completeDate"] as? Date
        let isCompleted = record["isCompleted"] as? Bool ?? false
        let isOnline = record["isOnline"] as? Bool ?? true
        
        // Parse current state - handle Optional<Any> safely
        let currentState: OverlapState
        if let stateValue = record["currentState"],
           let stateString = stateValue as? String,
           let parsedState = OverlapState(rawValue: stateString) {
            currentState = parsedState
        } else {
            currentState = .instructions // Default fallback
        }
        
        let currentParticipantIndex = record["currentParticipantIndex"] as? Int ?? 0
        let currentQuestionIndex = record["currentQuestionIndex"] as? Int ?? 0
        
        // Visual properties
        let iconEmoji = record["iconEmoji"] as? String ?? "📝"
        let startColorRed = record["startColorRed"] as? Double ?? 0.0
        let startColorGreen = record["startColorGreen"] as? Double ?? 0.0
        let startColorBlue = record["startColorBlue"] as? Double ?? 1.0
        let startColorAlpha = record["startColorAlpha"] as? Double ?? 1.0
        let endColorRed = record["endColorRed"] as? Double ?? 0.5
        let endColorGreen = record["endColorGreen"] as? Double ?? 0.0
        let endColorBlue = record["endColorBlue"] as? Double ?? 0.5
        let endColorAlpha = record["endColorAlpha"] as? Double ?? 1.0
        
        // Randomization
        let isRandomized = record["isRandomized"] as? Bool ?? false
        
        // Use the CloudKit-specific initializer
        let overlap = Overlap(
            id: id,
            beginDate: beginDate,
            completeDate: completeDate,
            participants: participants,
            isOnline: isOnline,
            title: title,
            information: information,
            instructions: instructions,
            questions: questions,
            iconEmoji: iconEmoji,
            startColorRed: startColorRed,
            startColorGreen: startColorGreen,
            startColorBlue: startColorBlue,
            startColorAlpha: startColorAlpha,
            endColorRed: endColorRed,
            endColorGreen: endColorGreen,
            endColorBlue: endColorBlue,
            endColorAlpha: endColorAlpha,
            randomizeQuestions: isRandomized,
            currentState: currentState,
            currentParticipantIndex: currentParticipantIndex,
            currentQuestionIndex: currentQuestionIndex,
            isCompleted: isCompleted
        )
        
        // Parse and restore responses
        if let responsesString = record["participantResponses"] as? String,
           let responsesData = responsesString.data(using: .utf8),
           let responses = try? JSONDecoder().decode([String: [Answer?]].self, from: responsesData) {
            overlap.restoreResponses(responses)
        }
        
        return overlap
    }
}


