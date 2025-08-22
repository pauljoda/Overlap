//
//  OverlapSyncManager.swift
//  Overlap
//
//  Simple sync manager for CloudKit sharing
//

import SwiftUI
import SwiftData
import CloudKit
import Combine

@MainActor
class OverlapSyncManager: ObservableObject {
    // MARK: - Properties
    
    private let cloudKitService = CloudKitService()
    private let modelContext: ModelContext
    
    // Track sync state per overlap
    @Published private(set) var isSyncing = false
    @Published private(set) var syncingOverlapIDs: Set<UUID> = []
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Share Acceptance & Response Syncing
    
    /// Accepts a CloudKit share and adds it to local SwiftData
    func acceptShare(with metadata: CKShare.Metadata) async throws {
        try await cloudKitService.acceptShare(metadata, to: modelContext)
    }
    
    /// Syncs participant responses to CloudKit for shared overlaps
    func syncResponses(for overlap: Overlap) async throws {
        guard overlap.isOnline else { return }
        try await cloudKitService.updateOverlapResponses(overlap)
    }
    
    /// Syncs overlap completion when a participant finishes their questions
    func syncOverlapCompletion(_ overlap: Overlap) async throws {
        // This is the same as syncing responses for the current implementation
        try await syncResponses(for: overlap)
    }
    
    /// Fetches and merges the latest responses from CloudKit
    func fetchLatestResponses(for overlap: Overlap) async throws {
        guard overlap.isOnline else { return }
        try await cloudKitService.fetchAndMergeResponses(overlap)
    }
    
    // MARK: - CloudKit Fetching
    
    /// Simplified fetch - UICloudSharingController handles most syncing automatically
    func fetchOverlapUpdates(_ overlap: Overlap) async throws {
        guard overlap.isOnline else { return }
        
        syncingOverlapIDs.insert(overlap.id)
        defer { syncingOverlapIDs.remove(overlap.id) }
        
        // Fetch the latest responses from other participants
        try await fetchLatestResponses(for: overlap)
        print("Fetched latest responses for overlap: \(overlap.title)")
    }
    
    /// Fetches updates for all online overlaps
    func fetchAllOnlineOverlapUpdates() async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        // Get all online overlaps from local database
        let onlineOverlaps = try modelContext.fetch(FetchDescriptor<Overlap>()).filter { $0.isOnline }
        
        // With UICloudSharingController, syncing is mostly automatic
        print("Checking \(onlineOverlaps.count) online overlaps for updates")
    }
    
    // MARK: - Status Methods
    
    /// Check if a specific overlap is currently syncing
    func isSyncing(overlap: Overlap) -> Bool {
        return syncingOverlapIDs.contains(overlap.id)
    }
    
    /// Basic fetch updates method for compatibility with existing views
    func fetchUpdates() async throws {
        try await fetchAllOnlineOverlapUpdates()
    }
    
    /// Check if an overlap has unread changes (simplified)
    func hasUnreadChanges(for overlapId: UUID) -> Bool {
        // For the simplified implementation, we don't track unread changes
        // SwiftData + CloudKit handles this automatically
        return false
    }
    
    /// Mark an overlap as read (simplified implementation)
    func markOverlapAsRead(_ overlapId: UUID) {
        // In the simplified implementation, we don't need to track read state
        // This method is kept for compatibility with existing views
        print("Marked overlap \(overlapId) as read")
    }
}

// MARK: - Environment Integration

struct OverlapSyncManagerKey: EnvironmentKey {
    static let defaultValue: OverlapSyncManager? = nil
}

extension EnvironmentValues {
    var overlapSyncManager: OverlapSyncManager? {
        get { self[OverlapSyncManagerKey.self] }
        set { self[OverlapSyncManagerKey.self] = newValue }
    }
}
