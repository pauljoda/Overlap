//
//  InProgressView.swift
//  Overlap
//
//  View showing in-progress overlap sessions
//

import SwiftUI
import SwiftData

struct InProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @Environment(\.overlapSyncManager) private var syncManager
    
    @Query(
        filter: #Predicate<Overlap> { overlap in
            overlap.isCompleted == false
        },
        sort: \Overlap.beginDate,
        order: .reverse
    ) private var allInProgressOverlaps: [Overlap]
    
    @State private var isRefreshing = false
    
    // Filter out empty overlaps manually since SwiftData doesn't support .count in predicates
    private var inProgressOverlaps: [Overlap] {
        allInProgressOverlaps.filter { overlap in
            // Always include shared overlaps, even if they appear empty locally
            if overlap.isSharedToMe || overlap.shareRecordName != nil || overlap.cloudKitRecordID != nil {
                return true
            }
            // For local overlaps, ensure they have participants and questions
            return !overlap.participants.isEmpty && !overlap.questions.isEmpty
        }
    }
    
    var body: some View {
        GlassScreen(scrollable: false) {
            if inProgressOverlaps.isEmpty {
                EmptyInProgressState {
                    navigationPath.wrappedValue.append("saved")
                }
            } else {
                OverlapListView(
                    overlaps: inProgressOverlaps,
                    onDelete: deleteOverlaps
                ) { overlap in
                    InProgressOverlapListItem(overlap: overlap)
                        .overlay(
                            // Loading indicator for online overlaps
                            syncManager?.isSyncing(overlap: overlap) == true ? 
                            LoadingOverlay() : nil
                        )
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable {
                    await refreshOnlineOverlaps()
                }
            }
        }
        .navigationTitle("In Progress")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(0)
        .onAppear {
            cleanupEmptyOverlaps()
            Task {
                await refreshOnlineOverlaps()
            }
        }
        .toolbar {
            if !inProgressOverlaps.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteOverlaps(at offsets: IndexSet) {
        withAnimation {
            offsets.map { inProgressOverlaps[$0] }.forEach(modelContext.delete)
        }
    }
    
    private func refreshOnlineOverlaps() async {
        guard let syncManager = syncManager else { return }
        
        do {
            // Fetch updates for all online overlaps
            for overlap in inProgressOverlaps.filter({ $0.isOnline }) {
                try await syncManager.fetchOverlapUpdates(overlap)
            }
        } catch {
            print("Failed to refresh online overlaps: \(error)")
        }
    }
    
    private func cleanupEmptyOverlaps() {
        // Find all overlaps and filter empty ones manually
        let allOverlapsDescriptor = FetchDescriptor<Overlap>()
        
        do {
            let allOverlaps = try modelContext.fetch(allOverlapsDescriptor)
            let emptyOverlaps = allOverlaps.filter { overlap in
                // Don't clean up shared overlaps - they might appear empty locally but have content in CloudKit
                if overlap.isSharedToMe || overlap.shareRecordName != nil || overlap.cloudKitRecordID != nil {
                    return false
                }
                // Only clean up truly local empty overlaps
                return overlap.participants.isEmpty || overlap.questions.isEmpty
            }
            
            if !emptyOverlaps.isEmpty {
                print("🧹 InProgressView: Found \(emptyOverlaps.count) empty overlaps to clean up")
                for emptyOverlap in emptyOverlaps {
                    print("🗑️ Removing empty overlap: ID=\(emptyOverlap.id), participants=\(emptyOverlap.participants.count), questions=\(emptyOverlap.questions.count)")
                    modelContext.delete(emptyOverlap)
                }
                try modelContext.save()
                print("✅ InProgressView: Successfully cleaned up \(emptyOverlaps.count) empty overlaps")
            } else {
                print("✅ InProgressView: No empty overlaps found - database is clean")
            }
        } catch {
            print("⚠️ Failed to cleanup empty overlaps: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        InProgressView()
    }
    .modelContainer(previewModelContainer)
}
