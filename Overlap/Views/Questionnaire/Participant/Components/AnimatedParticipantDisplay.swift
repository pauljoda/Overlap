//
//  AnimatedParticipantDisplay.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable animated participant display component
/// 
/// Features:
/// - Large participant name display from Overlap
/// - Smooth animation entrance
/// - Consistent typography and styling
/// - Configurable subtitle
struct AnimatedParticipantDisplay: View {
    let overlap: Overlap
    let subtitle: String
    let isAnimated: Bool
    
    init(
        overlap: Overlap,
        subtitle: String = "Next Participant",
        isAnimated: Bool = false
    ) {
        self.overlap = overlap
        self.subtitle = subtitle
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.s) {
            Text(subtitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : -20)
                .animation(
                    .easeOut(duration: Tokens.Duration.medium).delay(0.1),
                    value: isAnimated
                )

            Text(overlap.currentParticipant ?? "Unknown")
                .font(
                    .system(
                        size: 48,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .opacity(isAnimated ? 1 : 0)
                .scaleEffect(isAnimated ? 1 : 0.8)
                .animation(
                    .spring(
                        response: Tokens.Spring.response,
                        dampingFraction: Tokens.Spring.damping
                    ).delay(Tokens.Duration.fast),
                    value: isAnimated
                )
        }
    }
}

#Preview {
    VStack(spacing: Tokens.Spacing.quadXL) {
        AnimatedParticipantDisplay(
            overlap: SampleData.sampleOverlap,
            isAnimated: true
        )
        
        AnimatedParticipantDisplay(
            overlap: SampleData.sampleOverlap,
            subtitle: "Current Player",
            isAnimated: false
        )
    }
    .padding()
}
