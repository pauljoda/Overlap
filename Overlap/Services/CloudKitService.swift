//
//  CloudKitService.swift
//  Overlap
//
//  CloudKit service for managing shared overlap sessions
//

import CloudKit
import SwiftUI
import SwiftData

@MainActor
class CloudKitService: ObservableObject {
    // MARK: - Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    @Published var isAvailable = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var hasUnreadChanges = false
    
    // MARK: - Initialization
    
    init() {
        container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
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
    
    // MARK: - Sharing Operations
    
    /// Creates a CloudKit share for an overlap session
    func shareOverlap(_ overlap: Overlap) async throws -> CKShare {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }
        
        // Convert overlap to CKRecord
        let overlapRecord = try overlap.toCKRecord()
        
        // Create share
        let share = CKShare(rootRecord: overlapRecord)
        share[CKShare.SystemFieldKey.title] = overlap.title
        
        // Save record and share
        let (savedRecords, _) = try await privateDatabase.modifyRecords(
            saving: [overlapRecord, share],
            deleting: []
        )
        
        return savedRecords.compactMap { $0 as? CKShare }.first!
    }
    
    /// Accepts a CloudKit share invitation
    func acceptShare(with metadata: CKShare.Metadata) async throws -> Overlap {
        let share = try await container.accept(metadata)
        
        // Fetch the root record
        let recordID = share.rootRecordID!
        let record = try await sharedDatabase.record(for: recordID)
        
        // Convert back to Overlap
        return try Overlap.from(ckRecord: record)
    }
    
    /// Syncs local overlap with CloudKit
    func syncOverlap(_ overlap: Overlap) async throws {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }
        
        let record = try overlap.toCKRecord()
        let _ = try await privateDatabase.save(record)
    }
    
    /// Fetches updates for shared overlaps
    func fetchSharedOverlapUpdates() async throws -> [Overlap] {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }
        
        let query = CKQuery(recordType: "Overlap", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await sharedDatabase.records(matching: query)
        
        var overlaps: [Overlap] = []
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
        
        return overlaps
    }
}

// MARK: - CloudKit Error Types

enum CloudKitError: LocalizedError {
    case accountNotAvailable
    case recordConversionFailed
    case shareNotFound
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "CloudKit account is not available"
        case .recordConversionFailed:
            return "Failed to convert data for CloudKit"
        case .shareNotFound:
            return "CloudKit share not found"
        }
    }
}

// MARK: - Overlap CloudKit Extensions

extension Overlap {
    /// Converts an Overlap to a CKRecord for CloudKit storage
    func toCKRecord() throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
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
        
        // Parse current state
        let currentStateRaw = record["currentState"] as? String ?? "instructions"
        let currentState = OverlapState(rawValue: currentStateRaw) ?? .instructions
        
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

// Add missing OverlapState rawValue support
extension OverlapState: RawRepresentable {
    public var rawValue: String {
        switch self {
        case .instructions: return "instructions"
        case .answering: return "answering"
        case .nextParticipant: return "nextParticipant"
        case .complete: return "complete"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "instructions": self = .instructions
        case "answering": self = .answering
        case "nextParticipant": self = .nextParticipant
        case "complete": self = .complete
        default: return nil
        }
    }
}