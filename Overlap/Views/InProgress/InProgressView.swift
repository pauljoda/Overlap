//
//  InProgressView.swift
//  Overlap
//
//  View showing in-progress overlap sessions
//

import SwiftUI
import SharingGRDB

struct InProgressView: View {
    @Dependency(\.defaultDatabase) var database
    @Environment(\.navigationPath) private var navigationPath
    
    @FetchAll(Overlap.where { $0.isCompleted == false }.order { $0.beginDate.desc() })
    private var inProgressOverlaps: [Overlap]
    
    @State private var isRefreshing = false
    
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
            withErrorReporting {
                try database.write { db in
                    for index in offsets {
                        let overlap = inProgressOverlaps[index]
                        try Overlap.delete(overlap).execute(db)
                    }
                }
            }
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
}

#Preview("With Data") {
    let _ = setupGRDBPreview()
    NavigationStack {
        InProgressView()
    }
}
