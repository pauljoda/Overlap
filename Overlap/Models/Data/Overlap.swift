//
//  Overlap.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftData

enum OverlapState: Codable {
    case instructions
    case answering
    case nextParticipant
    case complete
}

@Model
class Overlap {
    // MARK: Information about Overlap
    /// The ID for this overlap
    var id = UUID()
    /// Start Date
    var beginData: Date = Date.now
    /// When all have completed
    var completeDate: Date?

    // MARK: Colaboration
    /// List of participants
    var participants: [String] = []
    /// Is this an online or local only
    var isOnline: Bool = false

    // MARK: Questions and Responses
    /// The questions asked
    var questionnaire: Questionnaire
    /// The responses
    var responses: [String: Responses] = [:]

    // MARK: Progress
    var currentParticipant: String = ""
    var currentQuestionIndex: Int = 0
    var currentState: OverlapState = OverlapState.instructions

    init(
        id: UUID = UUID(),
        beginData: Date = Date.now,
        completeDate: Date? = nil,
        participants: [String] = [],
        isOnline: Bool = false,
        questionnaire: Questionnaire,
        responses: [String: Responses] = [:],
        currentParticipant: String = "",
        currentQuestionIndex: Int = 0,
        currentState: OverlapState = .instructions
    ) {
        self.id = id
        self.beginData = beginData
        self.completeDate = completeDate
        self.participants = participants
        self.isOnline = isOnline
        self.questionnaire = questionnaire
        self.responses = responses
        self.currentQuestionIndex = currentQuestionIndex
        self.currentState = currentState

        // Set current participant to first participant if not provided and participants exist
        if currentParticipant.isEmpty && !participants.isEmpty {
            self.currentParticipant = participants[0]
        } else {
            self.currentParticipant = currentParticipant
        }

        // Prefill the mapping for users and answers
        for participant in self.participants {
            var initialArray: [UUID: Answer] = [:]
            for question in self.questionnaire.questions {
                initialArray[question.id] = Answer(type: .no, text: "")
            }
            self.responses[participant] = Responses(
                user: participant,
                answers: initialArray
            )
        }
    }

    // MARK : Functions

    /// Saves the provided answer for the current participant and current question.
    ///
    /// This method updates the `responses` dictionary by setting the answer for the current participant
    /// and the question at the current index of the `questionnaire`.
    ///
    /// - Parameter answer: The `Answer` object to save as the response to the current question
    ///   for the current participant.
    func SaveResponse(answer: Answer) {
        // Validate that we have a valid current participant
        guard !currentParticipant.isEmpty, responses[currentParticipant] != nil else {
            print("Error: Invalid current participant '\(currentParticipant)'")
            return
        }
        
        // Validate that we have a valid question index
        guard currentQuestionIndex < questionnaire.questions.count else {
            print("Error: Invalid question index \(currentQuestionIndex)")
            return
        }
        
        // Save the answer for the current question
        responses[currentParticipant]!.answers[
            questionnaire.questions[currentQuestionIndex].id
        ] = answer
        
        // Move to the next question
        currentQuestionIndex += 1

        // Check if we've completed all questions for the current participant
        if currentQuestionIndex >= questionnaire.questions.count {
            currentQuestionIndex = 0
            if currentParticipant == participants.last {
                // All participants have completed all questions
                currentState = .complete
            } else {
                currentState = .nextParticipant
                // Move to the next participant
                if let currentIndex = participants.firstIndex(of: currentParticipant) {
                    currentParticipant = participants[currentIndex + 1]
                }
            }
        }
    }

    /// Returns the current question being answered by the current participant.
    ///
    /// This method retrieves the question from the `questionnaire` at the position indicated by `currentQuestionIndex`.
    ///
    /// - Returns: The `Question` object at the current index within the `questionnaire`.
    func GetCurrentQuestion() -> Question {
        guard currentQuestionIndex < questionnaire.questions.count else {
            fatalError("Current question index \(currentQuestionIndex) is out of bounds for questionnaire with \(questionnaire.questions.count) questions")
        }
        return questionnaire.questions[currentQuestionIndex]
    }

    func FindQuestionByUUID(id: UUID) -> Question? {
        for question in self.questionnaire.questions {
            if question.id == id {
                return question
            }
        }
        return nil
    }
}
