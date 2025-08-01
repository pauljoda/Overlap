//
//  QuestionnaireSession.swift
//  Overlap
//
//  Created by Paul Davis on 8/1/25.
//

import Foundation
import SwiftData

/// A comprehensive session manager that handles questionnaire flow and response tracking
/// 
/// This class encapsulates both the questionnaire structure and participant responses,
/// providing a clean interface for managing the entire questionnaire session without
/// exposing internal index management or coupling between questions and answers.
///
/// ## Randomization Feature
/// The session supports question randomization where each participant receives the same questions
/// in a different random order. This helps eliminate order bias in responses.
///
/// Example usage:
/// ```swift
/// // Create session with randomization enabled
/// let session = QuestionnaireSession(
///     questionnaire: myQuestionnaire, 
///     participants: ["Alice", "Bob"], 
///     randomizeQuestions: true
/// )
///
/// // Alice might see: ["Question 3", "Question 1", "Question 2"]
/// // Bob might see: ["Question 2", "Question 3", "Question 1"]
/// 
/// // Responses are still stored consistently by original question index
/// // so analysis works correctly across all participants
/// ```
@Model
class QuestionnaireSession {
    // MARK: - Core Data
    var id = UUID()
    var questionnaire: Questionnaire
    private var participantResponses: [String: [Answer]] = [:]
    
    // MARK: - Randomization
    var isRandomized: Bool = false
    private var participantQuestionOrders: [String: [Int]] = [:]
    
    // MARK: - Session State
    var currentParticipantIndex: Int = 0
    var currentQuestionIndex: Int = 0
    var participants: [String] = []
    
    // MARK: - Computed Properties
    var currentParticipant: String? {
        guard currentParticipantIndex < participants.count else { return nil }
        return participants[currentParticipantIndex]
    }
    
    var currentQuestion: String? {
        guard currentQuestionIndex < questionnaire.questions.count,
              let participant = currentParticipant else { return nil }
        
        if isRandomized {
            guard let questionOrder = participantQuestionOrders[participant],
                  currentQuestionIndex < questionOrder.count else { return nil }
            let actualQuestionIndex = questionOrder[currentQuestionIndex]
            return questionnaire.questions[actualQuestionIndex]
        } else {
            return questionnaire.questions[currentQuestionIndex]
        }
    }
    
    var isComplete: Bool {
        return currentParticipantIndex >= participants.count
    }
    
    var totalQuestions: Int {
        return questionnaire.questions.count
    }
    
    // MARK: - Initialization
    init(questionnaire: Questionnaire, participants: [String] = [], randomizeQuestions: Bool = false) {
        self.questionnaire = questionnaire
        self.participants = participants
        self.isRandomized = randomizeQuestions
        initializeParticipantResponses()
        if randomizeQuestions {
            generateRandomizedQuestionOrders()
        }
    }
    
    // MARK: - Participant Management
    func setParticipants(_ participants: [String]) {
        self.participants = participants
        currentParticipantIndex = 0
        currentQuestionIndex = 0
        initializeParticipantResponses()
        if isRandomized {
            generateRandomizedQuestionOrders()
        }
    }
    
    func addParticipant(_ participant: String) {
        guard !participants.contains(participant) else { return }
        participants.append(participant)
        initializeResponsesForParticipant(participant)
        if isRandomized {
            generateRandomizedQuestionOrderForParticipant(participant)
        }
    }
    
    // MARK: - Randomization Management
    func enableRandomization() {
        isRandomized = true
        generateRandomizedQuestionOrders()
    }
    
    func disableRandomization() {
        isRandomized = false
        participantQuestionOrders.removeAll()
    }
    
    // MARK: - Response Management
    func saveCurrentAnswer(_ answer: Answer) -> Bool {
        guard let participant = currentParticipant,
              currentQuestionIndex < questionnaire.questions.count else {
            return false
        }
        
        // Ensure participant has response array initialized
        if participantResponses[participant] == nil {
            initializeResponsesForParticipant(participant)
        }
        
        // Get the actual question index (considering randomization)
        let actualQuestionIndex = getActualQuestionIndex(for: participant, displayIndex: currentQuestionIndex)
        
        // Save the answer at the actual question index (this maintains consistent storage)
        participantResponses[participant]![actualQuestionIndex] = answer
        
        // Advance to next question or participant
        advanceSession()
        
        return true
    }
    
    func getAnswer(for participant: String, questionIndex: Int) -> Answer? {
        guard let responses = participantResponses[participant],
              questionIndex < responses.count else {
            return nil
        }
        return responses[questionIndex]
    }
    
    func getAnswer(for participant: String, question: String) -> Answer? {
        guard let questionIndex = questionnaire.questions.firstIndex(of: question) else {
            return nil
        }
        return getAnswer(for: participant, questionIndex: questionIndex)
    }
    
    func getAllResponses(for participant: String) -> [Answer]? {
        return participantResponses[participant]
    }
    
    // MARK: - Question Management
    func getQuestion(at index: Int) -> String? {
        guard index < questionnaire.questions.count else { return nil }
        return questionnaire.questions[index]
    }
    
    func getQuestionIndex(for question: String) -> Int? {
        return questionnaire.questions.firstIndex(of: question)
    }
    
    // MARK: - Session Flow
    func advanceSession() {
        currentQuestionIndex += 1
        
        if currentQuestionIndex >= questionnaire.questions.count {
            // Finished all questions for current participant
            currentQuestionIndex = 0
            currentParticipantIndex += 1
        }
    }
    
    func resetSession() {
        currentParticipantIndex = 0
        currentQuestionIndex = 0
        initializeParticipantResponses()
        if isRandomized {
            generateRandomizedQuestionOrders()
        }
    }
    
    // MARK: - Analysis Methods
    func getResponsesForQuestion(at index: Int) -> [String: Answer] {
        guard index < questionnaire.questions.count else { return [:] }
        
        var responses: [String: Answer] = [:]
        for participant in participants {
            if let answer = getAnswer(for: participant, questionIndex: index) {
                responses[participant] = answer
            }
        }
        return responses
    }
    
    func getResponsesForQuestion(_ question: String) -> [String: Answer] {
        guard let index = getQuestionIndex(for: question) else { return [:] }
        return getResponsesForQuestion(at: index)
    }
    
    func getCompletionStatus() -> (completed: Int, total: Int) {
        let totalExpected = participants.count * questionnaire.questions.count
        var completedCount = 0
        
        for participant in participants {
            if let responses = participantResponses[participant] {
                completedCount += responses.count
            }
        }
        
        return (completed: completedCount, total: totalExpected)
    }
    
    // MARK: - Private Methods
    private func initializeParticipantResponses() {
        participantResponses.removeAll()
        for participant in participants {
            initializeResponsesForParticipant(participant)
        }
    }
    
    private func initializeResponsesForParticipant(_ participant: String) {
        participantResponses[participant] = Array(repeating: .no, count: questionnaire.questions.count)
    }
    
    // MARK: - Private Randomization Methods
    private func generateRandomizedQuestionOrders() {
        participantQuestionOrders.removeAll()
        for participant in participants {
            generateRandomizedQuestionOrderForParticipant(participant)
        }
    }
    
    private func generateRandomizedQuestionOrderForParticipant(_ participant: String) {
        let questionIndices = Array(0..<questionnaire.questions.count)
        participantQuestionOrders[participant] = questionIndices.shuffled()
    }
    
    private func getActualQuestionIndex(for participant: String, displayIndex: Int) -> Int {
        if isRandomized,
           let questionOrder = participantQuestionOrders[participant],
           displayIndex < questionOrder.count {
            return questionOrder[displayIndex]
        }
        return displayIndex
    }
}

// MARK: - Convenience Extensions
extension QuestionnaireSession {
    /// Get all questions with their current responses for analysis
    var questionsWithResponses: [(String, [String: Answer])] {
        return questionnaire.questions.enumerated().map { index, question in
            (question, getResponsesForQuestion(at: index))
        }
    }
    
    /// Get completion percentage
    var completionPercentage: Double {
        let status = getCompletionStatus()
        guard status.total > 0 else { return 0 }
        return Double(status.completed) / Double(status.total)
    }
    
    /// Get the question order for a specific participant (useful for debugging or analysis)
    func getQuestionOrder(for participant: String) -> [String]? {
        if isRandomized,
           let questionOrder = participantQuestionOrders[participant] {
            return questionOrder.map { questionnaire.questions[$0] }
        }
        return questionnaire.questions // Return original order if not randomized
    }
    
    /// Get the actual question index in the original questionnaire for a participant's display index
    func getOriginalQuestionIndex(for participant: String, displayIndex: Int) -> Int? {
        if isRandomized,
           let questionOrder = participantQuestionOrders[participant],
           displayIndex < questionOrder.count {
            return questionOrder[displayIndex]
        }
        return displayIndex < questionnaire.questions.count ? displayIndex : nil
    }
    
    /// Check if a participant has completed all questions
    func isParticipantComplete(_ participant: String) -> Bool {
        guard let responses = participantResponses[participant] else { return false }
        // Check if we have meaningful responses (not all default .no answers)
        return responses.count == questionnaire.questions.count
    }
    
    /// Debug helper: Print question orders for all participants (useful for testing randomization)
    func printQuestionOrders() {
        print("=== Question Orders ===")
        print("Randomization enabled: \(isRandomized)")
        
        for participant in participants {
            print("\n\(participant):")
            if let order = getQuestionOrder(for: participant) {
                for (index, question) in order.enumerated() {
                    let originalIndex = getOriginalQuestionIndex(for: participant, displayIndex: index) ?? -1
                    print("  \(index + 1). [Original #\(originalIndex + 1)] \(question)")
                }
            }
        }
        print("=====================")
    }
}
