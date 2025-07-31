//
//  ParticipantListItem.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable list item component for displaying participants with animation support
/// 
/// Features:
/// - Smooth expand/collapse animations
/// - Glass effect styling
/// - Remove button integration
/// - Configurable animation states
struct ParticipantListItem: View {
    let participant: String
    let index: Int
    let isAnimating: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)

            if !isAnimating {
                Text(participant)
                    .font(.body)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .leading)),
                        removal: .opacity
                    ))

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)),
                    removal: .opacity
                ))
            }
        }
        .padding(.horizontal, isAnimating ? 0 : 16)
        .padding(.vertical, 12)
        .frame(
            width: isAnimating ? 50 : nil,
            height: 50
        )
        .frame(maxWidth: isAnimating ? 50 : .infinity)
        .glassEffect(.regular)
        .cornerRadius(isAnimating ? 25 : 40)
        .animation(.easeInOut(duration: 0.6), value: isAnimating)
    }
}

#Preview {
    VStack(spacing: 8) {
        ParticipantListItem(
            participant: "John Doe",
            index: 0,
            isAnimating: false
        ) {
            print("Remove John Doe")
        }
        
        ParticipantListItem(
            participant: "Jane Smith",
            index: 1,
            isAnimating: true
        ) {
            print("Remove Jane Smith")
        }
    }
    .padding()
}
