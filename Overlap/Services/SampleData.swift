//
//  SampleData.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation

class SampleData {
    static let sampleQuestions: [Question] = [
        Question(text: "Do you like pizza?"),
        Question(text: "Is Swift your favorite programming language?"),
        Question(text: "Do you enjoy outdoor activities?"),
        Question(text: "Have you ever traveled abroad?"),
        Question(text: "Do you prefer tea over coffee?", answerTexts: [
            .no: "Tea",
            .maybe: "Both/Neither",
            .yes: "Coffee"
        ])
    ]
    
    static let sampleQuestionnaire = Questionnaire(questions: SampleData.sampleQuestions)
    
    static let sampleOverlap = Overlap(questionnaire: SampleData.sampleQuestionnaire)
}
