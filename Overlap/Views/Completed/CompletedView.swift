//
//  CompletedView.swift
//  Overlap
//
//  View showing completed overlap sessions
//

import SharingGRDB
import SwiftUI

struct CompletedView: View {
    @Dependency(\.defaultDatabase) var database

    @Environment(\.navigationPath) private var navigationPath

    @FetchAll(Overlap.where(\.isCompleted))
    private var completedOverlaps: [Overlap]

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
            withErrorReporting {
                try database.write { db in
                    for index in offsets {
                        let overlap = completedOverlaps[index]
                        try Overlap.delete(overlap).execute(db)
                    }
                }
            }
        }
    }

    private func refreshOnlineOverlaps() async {

    }
}

#Preview {
    NavigationStack {
        CompletedView()
    }
}

#Preview("With Data") {
    let _ = setupGRDBPreview()
    NavigationStack {
        CompletedView()
    }
}
