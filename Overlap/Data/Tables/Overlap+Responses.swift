//
//  Overlap+Responses.swift
//  Overlap
//
//  Response capture and retrieval
//

import Foundation

extension Overlap {
    /// Saves the provided answer for the current participant and current question.
    mutating func saveResponse(answer: Answer) -> Bool {
        guard let participant = currentParticipant,
              currentQuestionIndex < questions.count
        else { return false }

        // Ensure participant has response array initialized
        if participantResponses[participant] == nil { initializeResponsesForParticipant(participant) }

        // Save the answer at the actual question index (this maintains consistent storage)
        let actualQuestionIndex = getActualQuestionIndex(for: participant, displayIndex: currentQuestionIndex)
        participantResponses[participant]![actualQuestionIndex] = answer

        // Advance to next question or participant
        advanceSession()

        // Determine appropriate state based on completion status
        if shouldBeComplete {
            markAsComplete()
        } else if currentQuestionIndex == 0 && isOnline {
            currentState = .awaitingResponses
        } else if currentQuestionIndex == 0 && !isOnline {
            currentState = .nextParticipant
        }

        return true
    }

    /// Retrieves an answer for a specific participant and question index
    func getAnswer(for participant: String, questionIndex: Int) -> Answer? {
        guard let responses = participantResponses[participant], questionIndex < responses.count else { return nil }
        return responses[questionIndex]
    }

    /// Retrieves an answer for a specific participant and question text
    func getAnswer(for participant: String, question: String) -> Answer? {
        guard let questionIndex = questions.firstIndex(of: question) else { return nil }
        return getAnswer(for: participant, questionIndex: questionIndex)
    }

    /// Gets all responses for a specific participant
    func getAllResponses(for participant: String) -> [Answer?]? {
        return participantResponses[participant]
    }
}

