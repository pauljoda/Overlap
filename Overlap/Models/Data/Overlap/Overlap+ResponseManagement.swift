//
//  Overlap+ResponseManagement.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation

// MARK: - Response Management
extension Overlap {
    
    /// Saves the provided answer for the current participant and current question.
    ///
    /// This method handles all the internal logic for tracking questions, participants,
    /// and responses, including advancing to the next question or participant.
    ///
    /// - Parameter answer: The `Answer` object to save as the response to the current question
    /// - Returns: Boolean indicating whether the save was successful
    func saveResponse(answer: Answer) -> Bool {
        guard let participant = currentParticipant,
            currentQuestionIndex < questions.count
        else {
            return false
        }

        // Ensure participant has response array initialized
        if participantResponses[participant] == nil {
            initializeResponsesForParticipant(participant)
        }

        // Get the actual question index (considering randomization)
        let actualQuestionIndex = getActualQuestionIndex(
            for: participant,
            displayIndex: currentQuestionIndex
        )

        // Save the answer at the actual question index (this maintains consistent storage)
        participantResponses[participant]![actualQuestionIndex] = answer

        // Advance to next question or participant
        advanceSession()

        // Determine appropriate state based on completion status
        if shouldBeComplete {
            markAsComplete()
        } else if currentQuestionIndex == 0 && isOnline {
            // For online mode, participant finished their questions - go to awaiting responses
            currentState = .awaitingResponses
        } else if currentQuestionIndex == 0 && !isOnline {
            // We moved to the next participant (for offline mode only)
            currentState = .nextParticipant
        }

        return true
    }

    /// Retrieves an answer for a specific participant and question index
    ///
    /// - Parameters:
    ///   - participant: Name of the participant
    ///   - questionIndex: Index of the question (in original order)
    /// - Returns: The answer if found, nil otherwise
    func getAnswer(for participant: String, questionIndex: Int) -> Answer? {
        guard let responses = participantResponses[participant],
            questionIndex < responses.count
        else {
            return nil
        }
        return responses[questionIndex]
    }

    /// Retrieves an answer for a specific participant and question text
    ///
    /// - Parameters:
    ///   - participant: Name of the participant
    ///   - question: The question text to look up
    /// - Returns: The answer if found, nil otherwise
    func getAnswer(for participant: String, question: String) -> Answer? {
        guard let questionIndex = questions.firstIndex(of: question) else {
            return nil
        }
        return getAnswer(for: participant, questionIndex: questionIndex)
    }

    /// Gets all responses for a specific participant
    ///
    /// - Parameter participant: Name of the participant
    /// - Returns: Array of all answers for the participant, or nil if not found
    func getAllResponses(for participant: String) -> [Answer?]? {
        return participantResponses[participant]
    }
}
