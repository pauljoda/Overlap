//
//  Overlap+Session.swift
//  Overlap
//
//  Session lifecycle and participant response initialization/flow
//

import Foundation

extension Overlap {
    /// Marks the overlap as complete and sets the completion timestamp.
    mutating func markAsComplete() {
        currentState = .complete
        completeDate = Date.now
        isCompleted = true
    }

    /// Initializes the responses for all current participants.
    mutating func initializeResponses() { setParticipants(participants) }

    /// Resets the session to the beginning state
    mutating func resetSession() {
        currentParticipantIndex = 0
        currentQuestionIndex = 0
        currentState = .instructions
        initializeParticipantResponses()
        if isRandomized { generateRandomizedQuestionOrders() }
    }

    /// Sets the participant list and resets session state
    mutating func setParticipants(_ participants: [String]) {
        self.participants = participants
        currentParticipantIndex = 0
        currentQuestionIndex = 0
        initializeParticipantResponses()
        if isRandomized { generateRandomizedQuestionOrders() }
    }

    /// Adds a new participant to the session
    mutating func addParticipant(_ participant: String) {
        guard !participants.contains(participant) else { return }
        participants.append(participant)
        initializeResponsesForParticipant(participant)
        if isRandomized { generateRandomizedQuestionOrderForParticipant(participant) }
    }

    /// Advances the session to the next question or participant
    mutating func advanceSession() {
        currentQuestionIndex += 1
        if currentQuestionIndex >= questions.count {
            currentQuestionIndex = 0
            if !isOnline { currentParticipantIndex += 1 }
        }
    }

    /// Initializes response storage for all participants
    mutating func initializeParticipantResponses() {
        participantResponses.removeAll()
        for participant in participants { initializeResponsesForParticipant(participant) }
    }

    /// Initializes response storage for a specific participant
    mutating func initializeResponsesForParticipant(_ participant: String) {
        participantResponses[participant] = Array(repeating: nil, count: questions.count)
    }
}

