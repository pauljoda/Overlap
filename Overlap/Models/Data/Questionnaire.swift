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
class Questionnaire: ColorCustomizable {
    var id = UUID()
    var title: String = ""
    var information: String = ""
    var instructions: String = ""
    var author: String = ""
    var creationDate: Date = Date.now
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
    
    // CloudKit sync support
    var lastKnownRecordData: Data?

    init(
        id: UUID = UUID(),
        title: String = "",
        information: String = "",
        instructions: String = "",
        author: String = "",
        creationDate: Date = Date.now,
        questions: [String] = [],
        iconEmoji: String = "📝",
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
        self.iconEmoji = iconEmoji
        self.isFavorite = isFavorite
    }
}
