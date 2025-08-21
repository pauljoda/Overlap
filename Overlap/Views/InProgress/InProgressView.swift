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
    
    // Filter out empty overlaps manually since SwiftData doesn't support .count in predicates
    private var inProgressOverlaps: [Overlap] {
        allInProgressOverlaps.filter { overlap in
            !overlap.participants.isEmpty && !overlap.questions.isEmpty
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
            }
        }
        .navigationTitle("In Progress")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(0)
        .onAppear {
            cleanupEmptyOverlaps()
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
    
    private func cleanupEmptyOverlaps() {
        // Find all overlaps and filter empty ones manually
        let allOverlapsDescriptor = FetchDescriptor<Overlap>()
        
        do {
            let allOverlaps = try modelContext.fetch(allOverlapsDescriptor)
            let emptyOverlaps = allOverlaps.filter { overlap in
                overlap.participants.isEmpty || overlap.questions.isEmpty
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
