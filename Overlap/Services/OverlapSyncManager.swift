//
//  OverlapSyncManager.swift
//  Overlap
//
//  Manages synchronization and notification for overlap sessions
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
    
    // Track overlaps that have unread changes
    @Published private(set) var overlapsWithUnreadChanges: Set<UUID> = []
    
    // Sync status tracking
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Start background sync for shared overlaps
        Task {
            await startPeriodicSync()
        }
    }
    
    // MARK: - Sync Operations
    
    /// Syncs an overlap to CloudKit when a participant completes their questions
    func syncOverlapCompletion(_ overlap: Overlap) async throws {
        guard overlap.isOnline else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        try await cloudKitService.syncOverlap(overlap)
        
        // Mark local changes as synced
        overlapsWithUnreadChanges.remove(overlap.id)
        lastSyncDate = Date()
        
        // Update the overlap in SwiftData
        try? modelContext.save()
    }
    
    /// Fetches updates from CloudKit for shared overlaps
    func fetchUpdates() async throws {
        guard cloudKitService.isAvailable else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Fetch both types of shared overlaps:
        // 1. Overlaps shared to us (from shared database)
        let sharedToUsOverlaps = try await cloudKitService.fetchSharedOverlapUpdates()
        
        // 2. Overlaps we own and have shared (from private database) 
        let ownSharedOverlaps = try await cloudKitService.fetchOwnSharedOverlapUpdates()
        
        // Combine and process all remote overlaps
        let allRemoteOverlaps = sharedToUsOverlaps + ownSharedOverlaps
        
        for remoteOverlap in allRemoteOverlaps {
            await processRemoteOverlapUpdate(remoteOverlap)
        }
        
        lastSyncDate = Date()
    }
    
    /// Processes a remote overlap update and merges with local data
    private func processRemoteOverlapUpdate(_ remoteOverlap: Overlap) async {
        // Find the local overlap
        let remoteId = remoteOverlap.id
        let localOverlapRequest = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { overlap in
                overlap.id == remoteId
            }
        )
        
        guard let localOverlaps = try? modelContext.fetch(localOverlapRequest),
              let localOverlap = localOverlaps.first else {
            // New overlap - add it
            modelContext.insert(remoteOverlap)
            overlapsWithUnreadChanges.insert(remoteOverlap.id)
            return
        }
        
        // Check if there are new responses
        let hasNewResponses = mergeOverlapResponses(local: localOverlap, remote: remoteOverlap)
        
        if hasNewResponses {
            overlapsWithUnreadChanges.insert(localOverlap.id)
        }
        
        // Update other properties if needed
        if remoteOverlap.currentState != localOverlap.currentState ||
           remoteOverlap.currentParticipantIndex != localOverlap.currentParticipantIndex ||
           remoteOverlap.currentQuestionIndex != localOverlap.currentQuestionIndex {
            
            localOverlap.currentState = remoteOverlap.currentState
            localOverlap.currentParticipantIndex = remoteOverlap.currentParticipantIndex
            localOverlap.currentQuestionIndex = remoteOverlap.currentQuestionIndex
            localOverlap.isCompleted = remoteOverlap.isCompleted
            localOverlap.completeDate = remoteOverlap.completeDate
            
            overlapsWithUnreadChanges.insert(localOverlap.id)
        }
        
        try? modelContext.save()
    }
    
    /// Merges responses from remote overlap into local overlap
    /// Returns true if new responses were found
    private func mergeOverlapResponses(local: Overlap, remote: Overlap) -> Bool {
        let localResponses = local.getAllResponses()
        let remoteResponses = remote.getAllResponses()
        
        var hasNewResponses = false
        var mergedResponses = localResponses
        
        for (participant, responses) in remoteResponses {
            if let localParticipantResponses = localResponses[participant] {
                // Merge responses for existing participant
                for (index, response) in responses.enumerated() {
                    if index < localParticipantResponses.count {
                        if localParticipantResponses[index] == nil && response != nil {
                            mergedResponses[participant]?[index] = response
                            hasNewResponses = true
                        }
                    } else {
                        // New response beyond current range
                        while mergedResponses[participant]!.count <= index {
                            mergedResponses[participant]?.append(nil)
                        }
                        mergedResponses[participant]?[index] = response
                        hasNewResponses = true
                    }
                }
            } else {
                // New participant responses
                mergedResponses[participant] = responses
                hasNewResponses = true
            }
        }
        
        if hasNewResponses {
            local.restoreResponses(mergedResponses)
        }
        
        return hasNewResponses
    }
    
    /// Marks an overlap's changes as read
    func markOverlapAsRead(_ overlapId: UUID) {
        overlapsWithUnreadChanges.remove(overlapId)
    }
    
    /// Checks if an overlap has unread changes
    func hasUnreadChanges(for overlapId: UUID) -> Bool {
        return overlapsWithUnreadChanges.contains(overlapId)
    }
    
    // MARK: - Periodic Sync
    
    private func startPeriodicSync() async {
        while true {
            // Sync every 30 seconds for active shared overlaps
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            do {
                try await fetchUpdates()
            } catch {
                print("Periodic sync failed: \(error)")
            }
        }
    }
}

// MARK: - Environment Key

struct OverlapSyncManagerKey: EnvironmentKey {
    static let defaultValue: OverlapSyncManager? = nil
}

extension EnvironmentValues {
    var overlapSyncManager: OverlapSyncManager? {
        get { self[OverlapSyncManagerKey.self] }
        set { self[OverlapSyncManagerKey.self] = newValue }
    }
}