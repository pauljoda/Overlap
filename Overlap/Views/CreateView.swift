//
//  CreateView.swift
//  Overlap
//
//  Created by Paul Davis on 7/26/25.
//

import SwiftUI

struct CreateView: View {
    @State private var blobEmphasis: BlobEmphasis = .none

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: blobEmphasis)
            CardView(
                question: Question(text: "Do you like pizza?"),
                onSwipe: { answer in
                    print("Selected answer: \(answer)")
                },
                onEmphasisChange: { emphasis in
                    blobEmphasis = emphasis
                }
            )
        }
    }
}

#Preview {
    CreateView()
}
