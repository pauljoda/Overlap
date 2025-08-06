//
//  Questionnaire.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Questionnaire {
    var id = UUID()
    var title: String = ""
    var information: String = ""
    var instructions: String = ""
    var author: String = ""
    var creationDate: Date = Date.now
    var questions: [String] = []
    
    // Visual customization properties
    var iconSystemName: String = "doc.text.fill"
    
    // Simple color storage using RGBA components
    var startColorRed: Double = 0.0
    var startColorGreen: Double = 0.0
    var startColorBlue: Double = 1.0
    var startColorAlpha: Double = 1.0
    
    var endColorRed: Double = 0.5
    var endColorGreen: Double = 0.0
    var endColorBlue: Double = 0.5
    var endColorAlpha: Double = 1.0
    
    // Computed properties for easy Color access
    var startColor: Color {
        get {
            Color(red: startColorRed, green: startColorGreen, blue: startColorBlue, opacity: startColorAlpha)
        }
        set {
            // Extract RGBA components using UIColor/NSColor
            #if os(iOS)
            let uiColor = UIColor(newValue)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            startColorRed = Double(red)
            startColorGreen = Double(green)
            startColorBlue = Double(blue)
            startColorAlpha = Double(alpha)
            #else
            // Fallback for other platforms
            startColorRed = 0.0
            startColorGreen = 0.0
            startColorBlue = 1.0
            startColorAlpha = 1.0
            #endif
        }
    }
    
    var endColor: Color {
        get {
            Color(red: endColorRed, green: endColorGreen, blue: endColorBlue, opacity: endColorAlpha)
        }
        set {
            // Extract RGBA components using UIColor/NSColor
            #if os(iOS)
            let uiColor = UIColor(newValue)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            endColorRed = Double(red)
            endColorGreen = Double(green)
            endColorBlue = Double(blue)
            endColorAlpha = Double(alpha)
            #else
            // Fallback for other platforms
            endColorRed = 0.5
            endColorGreen = 0.0
            endColorBlue = 0.5
            endColorAlpha = 1.0
            #endif
        }
    }
    
    // Favorite status
    var isFavorite: Bool = false

    init(
        id: UUID = UUID(),
        title: String = "",
        information: String = "",
        instructions: String = "",
        author: String = "",
        creationDate: Date = Date.now,
        questions: [String] = [],
        iconSystemName: String = "doc.text.fill",
        startColor: Color = .blue,
        endColor: Color = .purple,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.information = information
        self.instructions = instructions
        self.author = author
        self.creationDate = creationDate
        self.questions = questions
        self.iconSystemName = iconSystemName
        self.isFavorite = isFavorite
        
        // Set colors using the computed properties
        self.startColor = startColor
        self.endColor = endColor
    }
}
