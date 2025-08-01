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
        Question(text: "Do you prefer tea over coffee?"),
    ]

    static let sampleQuestionnaire = Questionnaire(
        title: "Sample Questionnaire",
        instructions: "Respond to each question honestly, select the best answer for each one. This questionnaire is for fun only and does not reflect any personal opinions or beliefs. The results are purely statistical and should not be interpreted as any kind of opinion or prediction. Good luck!",
        questions: SampleData.sampleQuestions
    )

    static let sampleParticipants = ["John", "Sally"]

    static let sampleOverlap = Overlap(
        participants: sampleParticipants,
        questionnaire: SampleData.sampleQuestionnaire,
        currentState: .instructions
    )
}
