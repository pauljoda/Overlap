//
//  Questionnaire.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftData
import Foundation

@Model
class Questionnaire {
    var id = UUID()
    var title: String = ""
    var instructions: String = ""
    var author: String = ""
    var creationDate: Date = Date.now
    var questions: [Question] = []
    
    init(id: UUID = UUID(), title: String = "", instructions: String = "", author: String = "", creationDate: Date = Date.now, questions: [Question] = []) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.author = author
        self.creationDate = creationDate
        self.questions = questions
    }
}
