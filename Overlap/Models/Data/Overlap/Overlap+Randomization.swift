//
//  Overlap+Randomization.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation

// MARK: - Randomization Management
extension Overlap {
    
    /// Enables question randomization for all participants.
    /// Each participant will get a different random order of questions.
    func enableRandomization() {
        isRandomized = true
        generateRandomizedQuestionOrders()
    }

    /// Disables question randomization, reverting to original question order.
    func disableRandomization() {
        isRandomized = false
        participantQuestionOrders.removeAll()
    }

    /// Checks if question randomization is currently enabled.
    var isRandomizationEnabled: Bool {
        return isRandomized
    }
    
    /// Gets the question order for a specific participant (useful for analysis)
    ///
    /// - Parameter participant: Name of the participant
    /// - Returns: Array of question texts in the order shown to that participant
    func getQuestionOrder(for participant: String) -> [String]? {
        if isRandomized,
            let questionOrder = participantQuestionOrders[participant]
        {
            return questionOrder.map { questions[$0] }
        }
        return questions  // Return original order if not randomized
    }

    /// Gets the actual question index in the original questionnaire for a participant's display index
    ///
    /// - Parameters:
    ///   - participant: Name of the participant
    ///   - displayIndex: The index as shown to the participant
    /// - Returns: The actual index in the original questionnaire, or nil if invalid
    func getOriginalQuestionIndex(for participant: String, displayIndex: Int) -> Int? {
        if isRandomized,
            let questionOrder = participantQuestionOrders[participant],
            displayIndex < questionOrder.count
        {
            return questionOrder[displayIndex]
        }
        return displayIndex < questions.count ? displayIndex : nil
    }

    // MARK: - Internal Randomization Methods

    /// Generates randomized question orders for all participants
    internal func generateRandomizedQuestionOrders() {
        participantQuestionOrders.removeAll()
        for participant in participants {
            generateRandomizedQuestionOrderForParticipant(participant)
        }
    }

    /// Generates a randomized question order for a specific participant
    ///
    /// - Parameter participant: Name of the participant
    internal func generateRandomizedQuestionOrderForParticipant(_ participant: String) {
        let questionIndices = Array(0..<questions.count)
        participantQuestionOrders[participant] = questionIndices.shuffled()
    }

    /// Gets the actual question index considering randomization
    ///
    /// - Parameters:
    ///   - participant: Name of the participant
    ///   - displayIndex: The index as displayed to the participant
    /// - Returns: The actual index in the original questionnaire
    internal func getActualQuestionIndex(for participant: String, displayIndex: Int) -> Int {
        if isRandomized,
            let questionOrder = participantQuestionOrders[participant],
            displayIndex < questionOrder.count
        {
            return questionOrder[displayIndex]
        }
        return displayIndex
    }
}
