//
//  Overlap+Analysis.swift
//  Overlap
//
//  Analysis helpers for aggregating answers
//

import Foundation

extension Overlap {
    /// Gets all responses for analysis purposes.
    func getQuestionsWithResponses() -> [(String, [String: Answer])] {
        return questionsWithResponses
    }

    /// Gets all responses for a specific question by index
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
    func getResponsesForQuestion(_ question: String) -> [String: Answer] {
        guard let index = getQuestionIndex(for: question) else { return [:] }
        return getResponsesForQuestion(at: index)
    }

    /// Gets completion status for the entire session
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
    func isParticipantComplete(_ participant: String) -> Bool {
        guard let responses = participantResponses[participant] else { return false }
        return responses.compactMap { $0 }.count == questions.count
    }
}

