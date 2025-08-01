//
//  SampleData.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation

class SampleData {
    static let sampleQuestions: [String] = [
        "Do you like pizza?",
        "Is Swift your favorite programming language?",
        "Do you enjoy outdoor activities?",
        "Have you ever traveled abroad?",
        "Do you prefer tea over coffee?",
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
    
    static let sampleRandomizedOverlap = Overlap(
        participants: sampleParticipants,
        questionnaire: SampleData.sampleQuestionnaire,
        randomizeQuestions: true,
        currentState: .instructions
    )
}
