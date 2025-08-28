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
    
    @Column(as: Color.HexRepresentation.self)
    var startColor: Color = .blue
    
    @Column(as: Color.HexRepresentation.self)
    var endColor: Color = .purple
    
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
        self.isFavorite = isFavorite
    }
}
