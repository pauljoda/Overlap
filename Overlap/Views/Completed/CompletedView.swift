//
//  CompletedView.swift
//  Overlap
//
//  View showing completed overlap sessions
//

import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    
    @Query(
        filter: #Predicate<Overlap> { overlap in
            overlap.isCompleted == true
        },
        sort: \Overlap.completeDate,
        order: .reverse
    ) private var completedOverlaps: [Overlap]
    
    var body: some View {
        GlassScreen(scrollable: false) {
            if completedOverlaps.isEmpty {
                EmptyCompletedState {
                    navigationPath.wrappedValue.append("saved")
                }
            } else {
                OverlapListView(
                    overlaps: completedOverlaps,
                    onDelete: deleteOverlaps
                ) { overlap in
                    CompletedOverlapListItem(overlap: overlap)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .refreshable {
                    await refreshOnlineOverlaps()
                }
            }
        }
        .navigationTitle("Completed")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(0)
        .onAppear {
            Task {
                await refreshOnlineOverlaps()
            }
        }
        .toolbar {
            if !completedOverlaps.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteOverlaps(at offsets: IndexSet) {
        withAnimation {
            offsets.map { completedOverlaps[$0] }.forEach(modelContext.delete)
        }
    }
    
    private func refreshOnlineOverlaps() async {
     
    }
}

#Preview {
    NavigationStack {
        CompletedView()
    }
    .modelContainer(previewModelContainer)
}


#Preview {
    NavigationStack {
        CompletedView()
    }
    .modelContainer(previewModelContainer)
}
