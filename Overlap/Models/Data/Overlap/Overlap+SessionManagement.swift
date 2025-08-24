//
//  Overlap+SessionManagement.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation

// MARK: - Session Management
extension Overlap {
    
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
            // For online overlaps, require at least 2 participants to have completed
            let completedParticipants = participants.filter { isParticipantComplete($0) }
            return completedParticipants.count >= 2 && completedParticipants.count == participants.count
        } else {
            // For offline overlaps, use the original logic
            return isComplete
        }
    }
    
    /// Whether the overlap should be in awaiting responses state
    /// 
    /// Only applies to online overlaps when at least one participant has completed
    /// but not all participants have finished their responses
    var shouldAwaitResponses: Bool {
        if isOnline {
            let completedParticipants = participants.filter { isParticipantComplete($0) }
            return completedParticipants.count >= 1 && completedParticipants.count < participants.count
        }
        return false
    }

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

    /// Total number of questions in the questionnaire
    var totalQuestions: Int {
        return questions.count
    }

    /// Marks the overlap as complete and sets the completion timestamp.
    ///
    /// This method should be called whenever the questionnaire is completed
    /// to ensure the completion date is properly recorded.
    func markAsComplete() {
        currentState = .complete
        completeDate = Date.now
        isCompleted = true
    }

    /// Initializes the responses for all current participants.
    ///
    /// This method should be called when the questionnaire begins to ensure all
    /// participants have their response structure initialized.
    func initializeResponses() {
        setParticipants(participants)
    }

    /// Resets the session to the beginning state
    func resetSession() {
        currentParticipantIndex = 0
        currentQuestionIndex = 0
        currentState = .instructions
        initializeParticipantResponses()
        if isRandomized {
            generateRandomizedQuestionOrders()
        }
    }

    /// Sets the participant list and resets session state
    ///
    /// - Parameter participants: Array of participant names
    func setParticipants(_ participants: [String]) {
        self.participants = participants
        currentParticipantIndex = 0
        currentQuestionIndex = 0
        initializeParticipantResponses()
        if isRandomized {
            generateRandomizedQuestionOrders()
        }
    }

    /// Adds a new participant to the session
    ///
    /// - Parameter participant: Name of the participant to add
    func addParticipant(_ participant: String) {
        guard !participants.contains(participant) else { return }
        participants.append(participant)
        initializeResponsesForParticipant(participant)
        if isRandomized {
            generateRandomizedQuestionOrderForParticipant(participant)
        }
    }

    /// Advances the session to the next question or participant
    func advanceSession() {
        currentQuestionIndex += 1

        if currentQuestionIndex >= questions.count {
            // Finished all questions for current participant
            currentQuestionIndex = 0
            
            // For online overlaps, don't advance participant index - each participant answers on their own device
            // For offline overlaps, advance to next participant for pass-and-play mode
            if !isOnline {
                currentParticipantIndex += 1
            }
        }
    }

    // MARK: - Internal Session Management

    /// Initializes response storage for all participants
    internal func initializeParticipantResponses() {
        participantResponses.removeAll()
        for participant in participants {
            initializeResponsesForParticipant(participant)
        }
    }

    /// Initializes response storage for a specific participant
    ///
    /// - Parameter participant: Name of the participant
    internal func initializeResponsesForParticipant(_ participant: String) {
        participantResponses[participant] = Array(
            repeating: nil,
            count: questions.count
        )
    }
}
