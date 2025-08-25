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
       
    }
    
    private func cleanupEmptyOverlaps() {
       
    }
}

#Preview {
    NavigationStack {
        InProgressView()
    }
    .modelContainer(previewModelContainer)
}
