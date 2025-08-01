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
    /// The questionnaire session that manages questions and responses
    var session: QuestionnaireSession
    
    // MARK: Progress
    var currentState: OverlapState = OverlapState.instructions

    init(
        id: UUID = UUID(),
        beginData: Date = Date.now,
        completeDate: Date? = nil,
        participants: [String] = [],
        isOnline: Bool = false,
        questionnaire: Questionnaire,
        randomizeQuestions: Bool = false,
        currentState: OverlapState = .instructions
    ) {
        self.id = id
        self.beginData = beginData
        self.completeDate = completeDate
        self.participants = participants
        self.isOnline = isOnline
        self.session = QuestionnaireSession(questionnaire: questionnaire, participants: participants, randomizeQuestions: randomizeQuestions)
        self.currentState = currentState
    }

    // MARK : Functions

    /// Marks the overlap as complete and sets the completion timestamp.
    ///
    /// This method should be called whenever the questionnaire is completed
    /// to ensure the completion date is properly recorded.
    private func markAsComplete() {
        currentState = .complete
        completeDate = Date.now
    }

    /// Initializes the responses for all current participants.
    ///
    /// This method should be called when the questionnaire begins to ensure all
    /// participants have their response structure initialized.
    func initializeResponses() {
        session.setParticipants(participants)
    }

    /// Saves the provided answer for the current participant and current question.
    ///
    /// This method delegates to the session manager which handles all the internal
    /// logic for tracking questions, participants, and responses.
    ///
    /// - Parameter answer: The `Answer` object to save as the response to the current question
    ///   for the current participant.
    func SaveResponse(answer: Answer) {
        guard session.saveCurrentAnswer(answer) else {
            print("Error: Failed to save answer")
            return
        }
        
        // Check if session is complete
        if session.isComplete {
            markAsComplete()
        } else if session.currentQuestionIndex == 0 {
            // We moved to the next participant
            currentState = .nextParticipant
        }
    }

    /// Returns the current question being answered by the current participant.
    ///
    /// This method delegates to the session manager to get the current question.
    ///
    /// - Returns: The current question string, or nil if no current question exists.
    func GetCurrentQuestion() -> String? {
        return session.currentQuestion
    }
    
    /// Returns the current participant name.
    ///
    /// - Returns: The current participant string, or nil if no current participant exists.
    func getCurrentParticipant() -> String? {
        return session.currentParticipant
    }
    
    /// Gets all responses for analysis purposes.
    ///
    /// - Returns: Array of tuples containing question text and participant responses.
    func getQuestionsWithResponses() -> [(String, [String: Answer])] {
        return session.questionsWithResponses
    }
    
    // MARK: - Randomization Methods
    
    /// Enables question randomization for all participants.
    /// Each participant will get a different random order of questions.
    func enableQuestionRandomization() {
        session.enableRandomization()
    }
    
    /// Disables question randomization, reverting to original question order.
    func disableQuestionRandomization() {
        session.disableRandomization()
    }
    
    /// Checks if question randomization is currently enabled.
    var isQuestionRandomizationEnabled: Bool {
        return session.isRandomized
    }
    
    /// Gets the question order for a specific participant (useful for debugging).
    func getQuestionOrder(for participant: String) -> [String]? {
        return session.getQuestionOrder(for: participant)
    }
}
