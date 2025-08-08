//
//  GlassScreen.swift
//  Overlap
//
//  A reusable screen container that applies the blob background, optional scrolling
//  content, and an overlay slot for floating glass buttons.
//

import SwiftUI

struct GlassScreen<Content: View>: View {
    let scrollable: Bool
    let emphasis: BlobEmphasis
    @ViewBuilder var content: () -> Content

    init(
        scrollable: Bool = true,
        emphasis: BlobEmphasis = .none,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.scrollable = scrollable
        self.emphasis = emphasis
        self.content = content
    }

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: emphasis)
            Group {
                if scrollable {
                    ScrollView { content() }
                        .scrollDismissesKeyboard(.interactively)
                } else {
                    content()
                }
            }
        }
    }
}


#Preview("Scrollable") {
    GlassScreen(scrollable: true, emphasis: .none) {
        VStack(spacing: 16) {
            ForEach(0..<20) { i in
                Text("Row \(i)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

#Preview("Non-scrollable") {
    GlassScreen(scrollable: false, emphasis: .none) {
        VStack(spacing: 16) {
            Text("Static Content")
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}


