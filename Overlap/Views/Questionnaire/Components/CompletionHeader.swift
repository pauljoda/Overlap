//
//  CompletionHeader.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable completion header component for questionnaire results
/// 
/// Features:
/// - Animated checkmark icon
/// - Completion title and subtitle
/// - Consistent animation timing
struct CompletionHeader: View {
    let title: String
    let subtitle: String
    let isAnimated: Bool
    
    init(
        title: String = "Overlap Complete!",
        subtitle: String = "Here's where you align",
        isAnimated: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
                .opacity(isAnimated ? 1 : 0)
                .scaleEffect(isAnimated ? 1 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: isAnimated)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : -20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimated)
            
            Text(subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : -10)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimated)
        }
        .padding(.top, 20)
    }
}

#Preview {
    CompletionHeader(isAnimated: true)
        .padding()
}
