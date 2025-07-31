//
//  InstructionCard.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable instruction card component with icon and text
/// 
/// Features:
/// - Configurable icon and text
/// - Consistent glass-effect styling
/// - Animation support
/// - Accent color theming
struct InstructionCard: View {
    let icon: String
    let text: String
    let accentColor: Color
    let isAnimated: Bool
    let animationDelay: Double
    
    init(
        icon: String,
        text: String,
        accentColor: Color = .accentColor,
        isAnimated: Bool = false,
        animationDelay: Double = 0.0
    ) {
        self.icon = icon
        self.text = text
        self.accentColor = accentColor
        self.isAnimated = isAnimated
        self.animationDelay = animationDelay
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)

                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
        .padding()
        .background(accentColor.opacity(0.1))
        .cornerRadius(40)
        .opacity(isAnimated ? 1 : 0)
        .offset(x: isAnimated ? 0 : -50)
        .animation(
            .easeOut(duration: 0.7).delay(animationDelay),
            value: isAnimated
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        InstructionCard(
            icon: "hand.point.right.fill",
            text: "Pass to the next participant",
            isAnimated: true,
            animationDelay: 0.0
        )
        
        InstructionCard(
            icon: "info.circle.fill",
            text: "This is another instruction with different styling"
        )
    }
    .padding()
}
