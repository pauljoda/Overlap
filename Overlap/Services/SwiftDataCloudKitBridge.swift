//
//  SwiftDataCloudKitBridge.swift
//  Overlap
//
//  Simple service that bridges SwiftData operations with CloudKit for Overlaps
//

import Foundation
import SwiftData
import CloudKit
import SwiftUI
import os.log

/// Simple service that bridges SwiftData operations with CloudKit private database access for Overlaps
@MainActor
final class SwiftDataCloudKitBridge: ObservableObject {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let syncManager: CloudKitSyncManager
    private let logger = Logger(subsystem: "com.pauljoda.overlap", category: "SwiftDataCloudKitBridge")
    
    @Published var isCloudKitAvailable: Bool = false
    @Published var syncStatus: CloudKitSyncManager.SyncStatus = .idle
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.syncManager = CloudKitSyncManager(modelContainer: modelContainer)
        
        // Set initial values
        self.isCloudKitAvailable = syncManager.isSyncEnabled
        self.syncStatus = syncManager.syncStatus
        
        // Observe sync manager changes
        Task { @MainActor in
            for await isSyncEnabled in syncManager.$isSyncEnabled.values {
                self.isCloudKitAvailable = isSyncEnabled
            }
        }
        
        Task { @MainActor in
            for await status in syncManager.$syncStatus.values {
                self.syncStatus = status
            }
        }
    }
    
    // MARK: - CloudKit Record Access
    
    /// Get the CloudKit record for a specific Overlap
    /// This is useful for setting up sharing
    func getCloudKitRecord(for overlap: Overlap) async throws -> CKRecord? {
        guard isCloudKitAvailable else {
            throw CloudKitSyncError.syncNotAvailable
        }
        
        return try await syncManager.getOverlapRecord(for: overlap.id)
    }
    
    /// Get all CloudKit records for Overlaps
    func getAllOverlapRecords() async throws -> [CKRecord] {
        guard isCloudKitAvailable else {
            throw CloudKitSyncError.syncNotAvailable
        }
        
        return try await syncManager.getOverlapRecords()
    }
    
    /// Prepare an Overlap for sharing by ensuring it's synced to CloudKit
    /// Returns the CloudKit record that can be used for sharing
    func prepareForSharing(_ overlap: Overlap) async throws -> CKRecord {
        // Get the CloudKit record
        guard let record = try await getCloudKitRecord(for: overlap) else {
            throw CloudKitSyncError.recordNotFound
        }
        
        logger.info("Prepared Overlap \(overlap.title) for sharing")
        return record
    }
}

// MARK: - SwiftUI Environment

extension EnvironmentValues {
    @Entry var swiftDataCloudKitBridge: SwiftDataCloudKitBridge? = nil
}

extension View {
    func swiftDataCloudKitBridge(_ bridge: SwiftDataCloudKitBridge) -> some View {
        environment(\.swiftDataCloudKitBridge, bridge)
    }
}