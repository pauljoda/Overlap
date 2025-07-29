//
//  Question.swift
//  Overlap
//
//  Created by Paul Davis on 7/26/25.
//

import Foundation
import SwiftData

struct Question: Codable {
    var id = UUID()
    var text: String
    var answerTexts: [AnswerType : String]
    var orderIndex: Int
    
    init(id: UUID = UUID(), text: String = "", answerTexts: [AnswerType : String] = [AnswerType.no: "No", AnswerType.maybe: "Maybe", AnswerType.yes: "Yes"], orderIndex: Int = 0) {
        self.id = id
        self.text = text
        self.answerTexts = answerTexts
        self.orderIndex = orderIndex
    }
}
