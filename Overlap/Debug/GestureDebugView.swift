//
//  GestureDebugView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// Temporary debug wrapper to help identify gesture timeout issues
/// Wrap problematic views with this to add logging
struct GestureDebugView<Content: View>: View {
    let content: Content
    let label: String
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        content
            .onTapGesture {
                print("DEBUG: Tap gesture recognized on \(label)")
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        print("DEBUG: Simultaneous tap on \(label)")
                    }
            )
            .background(
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("DEBUG: Background tap on \(label)")
                    }
            )
    }
}

// Usage example:
// GestureDebugView(label: "HomeButton") {
//     HomeOptionButton(...)
// }
