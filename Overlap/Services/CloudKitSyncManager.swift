//
//  CloudKitSyncManager.swift
//  Overlap
//
//  Simple CloudKit sync manager for Overlap records
//  Based on: https://yingjiezhao.com/en/articles/Implementing-iCloud-Sync-by-Combining-SwiftData-with-CKSyncEngine/
//

import Foundation
import CloudKit
import SwiftData
import SwiftUI
import os.log

/// Simple manager that interfaces with SwiftData's backing CloudKit private database for Overlaps
@MainActor
final class CloudKitSyncManager: ObservableObject {
    
    // MARK: - Properties
    
    private let ckContainer: CKContainer
    private var syncEngine: CKSyncEngine?
    private let modelContainer: ModelContainer
    private let logger = Logger(subsystem: "com.pauljoda.overlap", category: "CloudKitSync")
    
    @Published private(set) var isSyncEnabled: Bool = false
    @Published private(set) var syncStatus: SyncStatus = .idle
    
    // MARK: - Types
    
    enum SyncStatus {
        case idle
        case syncing
        case error
    }
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.ckContainer = CKContainer(identifier: "iCloud.com.pauljoda.overlap")
        
        Task {
            await checkCloudKitAvailability()
            if isSyncEnabled {
                await setupSyncEngine()
            }
        }
    }
    
    // MARK: - CloudKit Availability
    
    private func checkCloudKitAvailability() async {
        do {
            let status = try await ckContainer.accountStatus()
            await MainActor.run {
                self.isSyncEnabled = status == .available
            }
            
            if status != .available {
                logger.warning("CloudKit not available: \(String(describing: status))")
            }
        } catch {
            logger.error("Failed to check CloudKit status: \(error)")
            await MainActor.run {
                self.isSyncEnabled = false
            }
        }
    }
    
    // MARK: - Sync Engine Setup
    
    private func setupSyncEngine() async {
        guard isSyncEnabled else { return }
        
        do {
            let configuration = CKSyncEngine.Configuration(
                database: ckContainer.privateCloudDatabase,
                stateSerialization: loadSyncEngineState(),
                delegate: self
            )
            
            syncEngine = CKSyncEngine(configuration)
            logger.info("CKSyncEngine initialized successfully")
            
        } catch {
            logger.error("Failed to setup CKSyncEngine: \(error)")
            await MainActor.run {
                self.syncStatus = .error
            }
        }
    }
    
    // MARK: - State Persistence
    
    private func loadSyncEngineState() -> CKSyncEngine.State.Serialization? {
        guard let data = UserDefaults.standard.data(forKey: "CKSyncEngineState") else {
            return nil
        }
        
        do {
            return try CKSyncEngine.State.Serialization(data: data)
        } catch {
            logger.error("Failed to load sync engine state: \(error)")
            return nil
        }
    }
    
    private func saveSyncEngineState(_ serialization: CKSyncEngine.State.Serialization) {
        do {
            let data = try serialization.data()
            UserDefaults.standard.set(data, forKey: "CKSyncEngineState")
        } catch {
            logger.error("Failed to save sync engine state: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    /// Get all private Overlap records from CloudKit
    func getOverlapRecords() async throws -> [CKRecord] {
        guard isSyncEnabled else {
            throw CloudKitSyncError.syncNotAvailable
        }
        
        let zoneID = CKRecordZone.ID(zoneName: "Overlap", ownerName: CKCurrentUserDefaultName)
        let query = CKQuery(recordType: "Overlap", predicate: NSPredicate(value: true))
        
        do {
            let (matchResults, _) = try await ckContainer.privateCloudDatabase.records(matching: query, inZoneWith: zoneID)
            
            var records: [CKRecord] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    records.append(record)
                case .failure(let error):
                    logger.error("Failed to fetch record: \(error)")
                }
            }
            
            logger.info("Fetched \(records.count) Overlap records")
            return records
            
        } catch {
            logger.error("Failed to query Overlap records: \(error)")
            throw error
        }
    }
    
    /// Get a specific Overlap record by ID
    func getOverlapRecord(for overlapId: UUID) async throws -> CKRecord? {
        let records = try await getOverlapRecords()
        return records.first { $0.recordID.recordName == overlapId.uuidString }
    }
}

// MARK: - CKSyncEngineDelegate

extension CloudKitSyncManager: CKSyncEngineDelegate {
    
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            saveSyncEngineState(update.stateSerialization)
            
        case .fetchedRecordZoneChanges(let changes):
            logger.info("Fetched \(changes.modifications.count) modifications, \(changes.deletions.count) deletions")
            
        case .willFetchChanges:
            await MainActor.run {
                self.syncStatus = .syncing
            }
            
        case .didFetchRecordZoneChanges:
            await MainActor.run {
                self.syncStatus = .idle
            }
            
        default:
            break
        }
    }
    
    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        // We're primarily reading from the private database
        // SwiftData handles the actual syncing
        return nil
    }
}

// MARK: - Error Types

enum CloudKitSyncError: LocalizedError {
    case syncNotAvailable
    case recordNotFound
    
    var errorDescription: String? {
        switch self {
        case .syncNotAvailable:
            return "CloudKit sync is not available"
        case .recordNotFound:
            return "Record not found in CloudKit"
        }
    }
}