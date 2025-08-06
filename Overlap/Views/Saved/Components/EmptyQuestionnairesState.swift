//
//  EmptyQuestionnairesState.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct EmptyQuestionnairesState: View {
    let onCreateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple.gradient)

                Text("No Saved Overlays")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Create your first overlay to get started!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Create Overlay") {
                onCreateTapped()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    EmptyQuestionnairesState {
        print("Create tapped")
    }
}
