//
//  ColorCustomization.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation
import SwiftUI

/// Protocol for models that support color customization with SwiftData-compatible storage
protocol ColorCustomizable {
    // MARK: - Color Storage Properties (SwiftData compatible)
    var startColorRed: Double { get set }
    var startColorGreen: Double { get set }
    var startColorBlue: Double { get set }
    var startColorAlpha: Double { get set }
    
    var endColorRed: Double { get set }
    var endColorGreen: Double { get set }
    var endColorBlue: Double { get set }
    var endColorAlpha: Double { get set }
}

extension ColorCustomizable {
    /// Computed property for easy Color access to start color
    var startColor: Color {
        get {
            Color(red: startColorRed, green: startColorGreen, blue: startColorBlue, opacity: startColorAlpha)
        }
        set {
            let components = extractColorComponents(from: newValue)
            startColorRed = components.red
            startColorGreen = components.green
            startColorBlue = components.blue
            startColorAlpha = components.alpha
        }
    }
    
    /// Computed property for easy Color access to end color
    var endColor: Color {
        get {
            Color(red: endColorRed, green: endColorGreen, blue: endColorBlue, opacity: endColorAlpha)
        }
        set {
            let components = extractColorComponents(from: newValue)
            endColorRed = components.red
            endColorGreen = components.green
            endColorBlue = components.blue
            endColorAlpha = components.alpha
        }
    }
    
    /// Helper method to extract color components
    private func extractColorComponents(from color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        #if os(iOS)
        let uiColor = UIColor(color)
        var redCG: CGFloat = 0
        var greenCG: CGFloat = 0
        var blueCG: CGFloat = 0
        var alphaCG: CGFloat = 0
        uiColor.getRed(&redCG, green: &greenCG, blue: &blueCG, alpha: &alphaCG)
        return (red: Double(redCG), green: Double(greenCG), blue: Double(blueCG), alpha: Double(alphaCG))
        #else
        // Fallback for other platforms
        return (red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        #endif
    }
}
