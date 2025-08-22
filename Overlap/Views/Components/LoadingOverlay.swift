//
//  LoadingOverlay.swift
//  Overlap
//
//  Loading overlay component for indicating sync status
//

import SwiftUI

struct LoadingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0),
                    value: isAnimating
                )
            
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.2),
                    value: isAnimating
                )
            
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.4),
                    value: isAnimating
                )
        }
        .padding(Tokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.s)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingOverlay()
        .padding()
        .background(Color.gray.opacity(0.3))
}
