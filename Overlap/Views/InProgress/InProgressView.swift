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
    ) private var inProgressOverlaps: [Overlap]
    
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
}

#Preview {
    NavigationStack {
        InProgressView()
    }
    .modelContainer(previewModelContainer)
}
