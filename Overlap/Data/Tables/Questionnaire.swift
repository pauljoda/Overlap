//
//  QuestionnaireTable.swift
//  Overlap
//
//  Created by Paul Davis on 8/23/25.
//

import SharingGRDB
import Foundation
import SwiftUI

@Table
struct Questionnaire: Hashable, Identifiable {
    let id: UUID
    var title: String = ""
    var description: String = ""
    var instructions: String = ""
    var author: String = "Anonymous"
    var creationDate: Date = Date.now
    
    @Column(as: [String].JSONRepresentation.self)
    var questions: [String] = []
    
    // Visual customization properties
    var iconEmoji: String = "📝"
    
    // Simple color storage using RGBA components
    var startColorRed: Double = 0.0
    var startColorGreen: Double = 0.0
    var startColorBlue: Double = 1.0
    var startColorAlpha: Double = 1.0
    
    var endColorRed: Double = 0.5
    var endColorGreen: Double = 0.0
    var endColorBlue: Double = 0.5
    var endColorAlpha: Double = 1.0
    
    // Favorite status
    var isFavorite: Bool = false
    
    // Default initializer that generates a UUID automatically
    init(
        id: UUID = UUID(),
        title: String = "",
        description: String = "",
        instructions: String = "",
        author: String = "Anonymous",
        creationDate: Date = Date.now,
        questions: [String] = [],
        iconEmoji: String = "📝",
        startColorRed: Double = 0.0,
        startColorGreen: Double = 0.0,
        startColorBlue: Double = 1.0,
        startColorAlpha: Double = 1.0,
        endColorRed: Double = 0.5,
        endColorGreen: Double = 0.0,
        endColorBlue: Double = 0.5,
        endColorAlpha: Double = 1.0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.instructions = instructions
        self.author = author
        self.creationDate = creationDate
        self.questions = questions
        self.iconEmoji = iconEmoji
        self.startColorRed = startColorRed
        self.startColorGreen = startColorGreen
        self.startColorBlue = startColorBlue
        self.startColorAlpha = startColorAlpha
        self.endColorRed = endColorRed
        self.endColorGreen = endColorGreen
        self.endColorBlue = endColorBlue
        self.endColorAlpha = endColorAlpha
        self.isFavorite = isFavorite
    }
    
    // Computed properties for easy Color access
    var startColor: Color {
        get {
            Color(
                red: startColorRed,
                green: startColorGreen,
                blue: startColorBlue,
                opacity: startColorAlpha
            )
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
            Color(
                red: endColorRed,
                green: endColorGreen,
                blue: endColorBlue,
                opacity: endColorAlpha
            )
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
}
