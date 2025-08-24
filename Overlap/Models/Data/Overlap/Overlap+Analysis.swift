//
//  Overlap+Analysis.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation

// MARK: - Analysis and Reporting
extension Overlap {
    
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
    
    /// Gets all responses for analysis purposes.
    ///
    /// - Returns: Array of tuples containing question text and participant responses.
    func getQuestionsWithResponses() -> [(String, [String: Answer])] {
        return questionsWithResponses
    }

    /// Gets all responses for a specific question by index
    ///
    /// - Parameter index: Index of the question in the original questionnaire
    /// - Returns: Dictionary mapping participant names to their answers
    func getResponsesForQuestion(at index: Int) -> [String: Answer] {
        guard index < questions.count else { return [:] }

        var responses: [String: Answer] = [:]
        for participant in participants {
            if let answer = getAnswer(for: participant, questionIndex: index) {
                responses[participant] = answer
            }
        }
        return responses
    }

    /// Gets all responses for a specific question by text
    ///
    /// - Parameter question: The question text
    /// - Returns: Dictionary mapping participant names to their answers
    func getResponsesForQuestion(_ question: String) -> [String: Answer] {
        guard let index = getQuestionIndex(for: question) else { return [:] }
        return getResponsesForQuestion(at: index)
    }

    /// Gets completion status for the entire session
    ///
    /// - Returns: Tuple with completed response count and total expected responses
    func getCompletionStatus() -> (completed: Int, total: Int) {
        let totalExpected = participants.count * questions.count
        var completedCount = 0

        for participant in participants {
            if let responses = participantResponses[participant] {
                completedCount += responses.compactMap { $0 }.count
            }
        }

        return (completed: completedCount, total: totalExpected)
    }
    
    /// Checks if a participant has completed all questions
    ///
    /// - Parameter participant: Name of the participant to check
    /// - Returns: True if participant has answered all questions
    func isParticipantComplete(_ participant: String) -> Bool {
        guard let responses = participantResponses[participant] else { return false }
        return responses.compactMap { $0 }.count == questions.count
    }
}
