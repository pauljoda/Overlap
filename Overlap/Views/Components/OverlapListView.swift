//
//  OverlapListView.swift
//  Overlap
//
//  Reusable list view for displaying overlaps
//

import SwiftUI
import SwiftData

struct OverlapListView: View {
    let overlaps: [Overlap]
    let onDelete: (IndexSet) -> Void
    let listItemBuilder: (Overlap) -> AnyView
    @Environment(\.navigationPath) private var navigationPath
    
    init(
        overlaps: [Overlap],
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder listItemBuilder: @escaping (Overlap) -> some View
    ) {
        self.overlaps = overlaps
        self.onDelete = onDelete
        self.listItemBuilder = { overlap in AnyView(listItemBuilder(overlap)) }
    }
    
    var body: some View {
        List {
            ForEach(overlaps) { overlap in
                Button {
                    navigationPath.wrappedValue.append(overlap)
                } label: {
                    listItemBuilder(overlap)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .onDelete(perform: onDelete)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 25))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

#Preview {
    NavigationStack {
        OverlapListView(
            overlaps: [SampleData.sampleInProgressOverlap],
            onDelete: { _ in },
            listItemBuilder: { overlap in
                InProgressOverlapListItem(overlap: overlap)
            }
        )
    }
    .modelContainer(previewModelContainer)
}
