//
//  Questionnaire.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftData

@Model
class Questionnaire {
    var id = UUID()
    var title: String = ""
    var information: String = ""
    var instructions: String = ""
    var author: String = ""
    var creationDate: Date = Date.now
    var questions: [String] = []

    init(
        id: UUID = UUID(),
        title: String = "",
        information: String = "",
        instructions: String = "",
        author: String = "",
        creationDate: Date = Date.now,
        questions: [String] = []
    ) {
        self.id = id
        self.title = title
        self.information = information
        self.instructions = instructions
        self.author = author
        self.creationDate = creationDate
        self.questions = questions
    }
}
