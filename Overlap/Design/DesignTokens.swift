//
//  DesignTokens.swift
//  Overlap
//
//  Centralized spacing, radii, and animation tokens for consistent styling
//

import SwiftUI

enum Tokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let tripleXL: CGFloat = 32
        static let quadXL: CGFloat = 40
    }

    enum Radius {
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let pill: CGFloat = 999
    }

    enum Duration {
        static let fast: Double = 0.2
        static let medium: Double = 0.4
        static let slow: Double = 0.7
    }

    enum Spring {
        static let response: Double = 0.6
        static let damping: Double = 0.8
    }
}

// MARK: - Glass Effect Extensions

extension View {
    /// Standard glass card effect for interactive elements
    func standardGlassCard() -> some View {
        self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Tokens.Radius.m))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// Large glass card effect for sections
    func largeGlassCard() -> some View {
        self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Tokens.Radius.l))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    /// Action button glass effect
    func actionGlassButton(tint: Color = .blue) -> some View {
        self.glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: 18))
    }
}


