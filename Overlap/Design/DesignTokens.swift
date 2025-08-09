//
//  DesignTokens.swift
//  Overlap
//
//  Centralized design tokens for consistent styling throughout the app
//

import SwiftUI

enum Tokens {
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4     // Tiny gaps, icon-text spacing
        static let s: CGFloat = 8      // Small gaps, form field spacing
        static let m: CGFloat = 12     // Medium gaps, list item spacing
        static let l: CGFloat = 16     // Standard gaps, section spacing
        static let xl: CGFloat = 20    // Large gaps, card spacing
        static let xxl: CGFloat = 24   // Extra large gaps, major sections
        static let tripleXL: CGFloat = 32  // Screen sections
        static let quadXL: CGFloat = 40    // Major screen spacing
        static let huge: CGFloat = 60      // Special large spacing (home view)
    }

    // MARK: - Corner Radius
    enum Radius {
        static let xs: CGFloat = 6     // Small elements, inner borders
        static let s: CGFloat = 8      // Small icons, buttons
        static let m: CGFloat = 12     // Standard cards, inputs
        static let l: CGFloat = 16     // Large cards, sheets
        static let xl: CGFloat = 24    // Major cards
        static let xxl: CGFloat = 32   // Hero elements
        static let heroCard: CGFloat = 44  // Main interaction cards
        static let actionButton: CGFloat = 18  // Action buttons
        static let pill: CGFloat = 999 // Fully rounded elements
    }

    // MARK: - Dimensions
    enum Size {
        // Icon sizes
        static let iconSmall: CGFloat = 30
        static let iconMedium: CGFloat = 50
        static let iconLarge: CGFloat = 60
        static let iconXL: CGFloat = 80
        static let iconHuge: CGFloat = 120
        
        // Button heights
        static let buttonStandard: CGFloat = 50
        static let buttonCompact: CGFloat = 44
        
        // Layout constraints
        static let maxContentWidth: CGFloat = 400
        static let cardMinHeight: CGFloat = 320
        static let cardMaxHeight: CGFloat = 520
    }

    // MARK: - Typography Scale
    enum FontSize {
        static let hero: CGFloat = 60      // Special large text
        static let extraLarge: CGFloat = 48 // Very large text
        // Use system fonts for other sizes: .largeTitle, .title, .title2, .title3, .headline, .body, .callout, .subheadline, .footnote, .caption
    }

    // MARK: - Shadow
    enum Shadow {
        struct ShadowToken {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
        
        static let subtle = ShadowToken(
            color: .black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = ShadowToken(
            color: .black.opacity(0.1),
            radius: 6,
            x: 0,
            y: 4
        )
        
        static let strong = ShadowToken(
            color: .black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 6
        )
    }

    // MARK: - Border
    enum Border {
        static let thin: CGFloat = 0.5     // Subtle borders
        static let standard: CGFloat = 1   // Standard borders
        static let thick: CGFloat = 3      // Emphasis borders
        
        // Border offsets for concentric designs
        static let concentricOffset: CGFloat = 8
    }

    // MARK: - Opacity
    enum Opacity {
        static let subtle: Double = 0.05
        static let light: Double = 0.1
        static let medium: Double = 0.3
        static let strong: Double = 0.5
        static let prominent: Double = 0.85
    }

    // MARK: - Scale
    enum Scale {
        static let pressed: CGFloat = 0.95     // Button press state
        static let hover: CGFloat = 1.03       // Hover/highlight state
        static let emphasized: CGFloat = 1.05   // Emphasis state
        static let colorPicker: CGFloat = 1.5   // Special scaling
    }

    // MARK: - Animation
    enum Duration {
        static let fast: Double = 0.2
        static let medium: Double = 0.4
        static let slow: Double = 0.7
    }

    enum Spring {
        static let response: Double = 0.6
        static let damping: Double = 0.8
    }

    // MARK: - Layout Grid
    enum Grid {
        static let colorPickerColumns: Int = 6
        static let standardSpacing: CGFloat = 16
    }
}

// MARK: - Glass Effect Extensions

extension View {
    /// Standard glass card effect for interactive elements
    func standardGlassCard() -> some View {
        self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Tokens.Radius.m))
            .shadow(
                color: Tokens.Shadow.subtle.color,
                radius: Tokens.Shadow.subtle.radius,
                x: Tokens.Shadow.subtle.x,
                y: Tokens.Shadow.subtle.y
            )
    }
    
    /// Large glass card effect for major sections
    func largeGlassCard() -> some View {
        self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Tokens.Radius.l))
            .shadow(
                color: Tokens.Shadow.subtle.color,
                radius: Tokens.Shadow.subtle.radius,
                x: Tokens.Shadow.subtle.x,
                y: Tokens.Shadow.subtle.y
            )
    }
    
    /// Hero glass card effect for main interaction cards
    func heroGlassCard() -> some View {
        self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Tokens.Radius.heroCard))
            .shadow(
                color: Tokens.Shadow.strong.color,
                radius: Tokens.Shadow.strong.radius,
                x: Tokens.Shadow.strong.x,
                y: Tokens.Shadow.strong.y
            )
    }
    
    /// Action button glass effect
    func actionGlassButton(tint: Color = .blue) -> some View {
        self.glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: Tokens.Radius.actionButton))
    }
    
    /// Apply concentric border design commonly used in cards
    func concentricBorder(cornerRadius: CGFloat = Tokens.Radius.heroCard) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius - Tokens.Border.concentricOffset / 2)
                .stroke(Color(.separator).opacity(Tokens.Opacity.strong), lineWidth: Tokens.Border.thin)
                .padding(Tokens.Border.concentricOffset / 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(.separator), lineWidth: Tokens.Border.standard)
        )
    }
}

// MARK: - Shadow Extensions

extension View {
    func subtleShadow() -> some View {
        let shadow = Tokens.Shadow.subtle
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func mediumShadow() -> some View {
        let shadow = Tokens.Shadow.medium
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func strongShadow() -> some View {
        let shadow = Tokens.Shadow.strong
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}


