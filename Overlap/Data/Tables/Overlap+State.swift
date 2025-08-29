//
//  Overlap+State.swift
//  Overlap
//
//  Computed properties and state helpers for Overlap
//

import Foundation

extension Overlap {
    /// The currently active participant
    var currentParticipant: String? {
        guard currentParticipantIndex < participants.count else { return nil }
        return participants[currentParticipantIndex]
    }

    /// The current question text for the active participant
    var currentQuestion: String? {
        guard currentQuestionIndex < questions.count,
              let participant = currentParticipant
        else { return nil }

        if isRandomized {
            guard let questionOrder = participantQuestionOrders[participant],
                  currentQuestionIndex < questionOrder.count
            else { return nil }
            let actualQuestionIndex = questionOrder[currentQuestionIndex]
            return questions[actualQuestionIndex]
        } else {
            return questions[currentQuestionIndex]
        }
    }

    /// Whether all participants have completed all questions
    var isComplete: Bool {
        return currentParticipantIndex >= participants.count
    }

    /// Whether the overlap should be marked as complete based on online/offline mode
    ///
    /// For online overlaps: Requires at least 2 participants to have completed AND all participants finished
    /// For offline overlaps: Uses the original sequential logic (all local participants done)
    var shouldBeComplete: Bool {
        if isOnline {
            let completedParticipants = participants.filter { isParticipantComplete($0) }
            return completedParticipants.count >= 2 && completedParticipants.count == participants.count
        } else {
            return isComplete
        }
    }

    /// Whether the overlap should be in awaiting responses state (online only)
    var shouldAwaitResponses: Bool {
        if isOnline {
            let completedParticipants = participants.filter { isParticipantComplete($0) }
            return completedParticipants.count >= 1 && completedParticipants.count < participants.count
        }
        return false
    }

    /// Total number of questions in the questionnaire
    var totalQuestions: Int { questions.count }

    /// Get all questions with their current responses for analysis
    var questionsWithResponses: [(String, [String: Answer])] {
        return questions.enumerated().map { index, question in
            (question, getResponsesForQuestion(at: index))
        }
    }

    /// Get completion percentage (0.0 to 1.0)
    var completionPercentage: Double {
        let status = getCompletionStatus()
        guard status.total > 0 else { return 0 }
        return Double(status.completed) / Double(status.total)
    }
}

