//
//  EmptyResultsState.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable empty state component for when no agreements are found
/// 
/// Features:
/// - Consistent empty state styling
/// - Configurable messaging
/// - Animation support
struct EmptyResultsState: View {
    let title: String
    let subtitle: String
    let icon: String
    let isAnimated: Bool
    let animationDelay: Double
    
    init(
        title: String = "No Clear Agreements",
        subtitle: String = "It looks like there weren't any questions where everyone agreed. Try discussing the results!",
        icon: String = "questionmark.circle",
        isAnimated: Bool = false,
        animationDelay: Double = 0.0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isAnimated = isAnimated
        self.animationDelay = animationDelay
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(animationDelay), value: isAnimated)
    }
}

#Preview {
    EmptyResultsState(isAnimated: true)
        .padding()
}
