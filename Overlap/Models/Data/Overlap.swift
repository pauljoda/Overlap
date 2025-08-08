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

/// A comprehensive overlap session that handles questionnaire flow and response tracking
///
/// This class encapsulates the entire overlap experience including questionnaire structure,
/// participant responses, session management, and randomization features. It provides a
/// clean interface for managing the questionnaire session without exposing internal
/// index management or coupling between questions and answers.
///
/// ## Key Features
/// - **Session Management**: Tracks current participant and question progress
/// - **Response Storage**: Maintains participant responses with CloudKit compatibility
/// - **Question Randomization**: Optional feature to randomize question order per participant
/// - **Progress Tracking**: Monitors completion status and session flow
/// - **Analysis Tools**: Methods for extracting and analyzing response data
///
/// ## Randomization Feature
/// The session supports question randomization where each participant receives the same questions
/// in a different random order. This helps eliminate order bias in responses.
///
/// Example usage:
/// ```swift
/// // Create overlap with randomization enabled
/// let overlap = Overlap(
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
class Overlap {
    // MARK: - Session Information
    /// The unique identifier for this overlap session
    var id = UUID()
    /// Start date of the overlap session
    var beginDate: Date = Date.now
    /// Completion date when all participants have finished
    var completeDate: Date?

    // MARK: - Collaboration Settings
    /// List of participant names in this overlap session
    var participants: [String] = []
    /// Whether this is an online collaborative session or local only
    var isOnline: Bool = false

    // MARK: - Questionnaire Data
    /// The title for this overlap session
    var title: String = ""
    /// The information for this overlap session
    var information: String = ""
    /// The instructions for this overlap session
    var instructions: String = ""
    /// The questions for this session
    var questions: [String] = []
    /// Storage for all participant responses organized by participant name and question index
    private var participantResponses: [String: [Answer?]] = [:]

    // MARK: - Randomization Settings
    /// Whether question randomization is enabled for this session
    var isRandomized: Bool = false
    /// Question order mappings for each participant (used when randomization is enabled)
    private var participantQuestionOrders: [String: [Int]] = [:]

    // MARK: - Session State
    /// Current position in the participant list
    var currentParticipantIndex: Int = 0
    /// Current question index for the active participant
    var currentQuestionIndex: Int = 0
    /// Overall session state for UI navigation
    var currentState: OverlapState = OverlapState.instructions
    /// Whether the overlap session has been completed (stored property for SwiftData queries)
    var isCompleted: Bool = false

    // MARK: - Computed Properties

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

    /// Total number of questions in the questionnaire
    var totalQuestions: Int {
        return questions.count
    }

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

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        beginDate: Date = Date.now,
        completeDate: Date? = nil,
        participants: [String] = [],
        isOnline: Bool = false,
        questionnaire: Questionnaire,
        randomizeQuestions: Bool = false,
        currentState: OverlapState = .instructions
    ) {
        self.id = id
        self.beginDate = beginDate
        self.completeDate = completeDate
        self.participants = participants
        self.isOnline = isOnline
        
        // Copy questionnaire data to preserve immutability
        self.title = questionnaire.title
        self.information = questionnaire.information
        self.instructions = questionnaire.instructions
        self.questions = questionnaire.questions
        
        self.isRandomized = randomizeQuestions
        self.currentState = currentState
        self.isCompleted = (currentState == .complete)

        initializeParticipantResponses()
        if randomizeQuestions {
            generateRandomizedQuestionOrders()
        }
    }
    
    /// Convenience initializer for creating an overlap with direct question data
    init(
        id: UUID = UUID(),
        beginDate: Date = Date.now,
        completeDate: Date? = nil,
        participants: [String] = [],
        isOnline: Bool = false,
        title: String,
        information: String = "",
        instructions: String,
        questions: [String],
        randomizeQuestions: Bool = false,
        currentState: OverlapState = .instructions
    ) {
        self.id = id
        self.beginDate = beginDate
        self.completeDate = completeDate
        self.participants = participants
        self.isOnline = isOnline
        self.title = title
        self.information = information
        self.instructions = instructions
        self.questions = questions
        self.isRandomized = randomizeQuestions
        self.currentState = currentState
        self.isCompleted = (currentState == .complete)

        initializeParticipantResponses()
        if randomizeQuestions {
            generateRandomizedQuestionOrders()
        }
    }

    // MARK: - Session Management

    /// Marks the overlap as complete and sets the completion timestamp.
    ///
    /// This method should be called whenever the questionnaire is completed
    /// to ensure the completion date is properly recorded.
    private func markAsComplete() {
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

    // MARK: - Participant Management

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

    // MARK: - Randomization Management

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

    // MARK: - Response Management

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

        // Check if session is complete
        if isComplete {
            markAsComplete()
        } else if currentQuestionIndex == 0 {
            // We moved to the next participant
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

    // MARK: - Question Management

    /// Returns the current question being answered by the current participant.
    ///
    /// - Returns: The current question string, or nil if no current question exists.
    func getCurrentQuestion() -> String? {
        return currentQuestion
    }

    /// Returns the current participant name.
    ///
    /// - Returns: The current participant string, or nil if no current participant exists.
    func getCurrentParticipant() -> String? {
        return currentParticipant
    }

    /// Gets a question by its index in the original questionnaire
    ///
    /// - Parameter index: Index of the question
    /// - Returns: Question text if found, nil otherwise
    func getQuestion(at index: Int) -> String? {
        guard index < questions.count else { return nil }
        return questions[index]
    }

    /// Gets the index of a question by its text
    ///
    /// - Parameter question: The question text to find
    /// - Returns: Index of the question if found, nil otherwise
    func getQuestionIndex(for question: String) -> Int? {
        return questions.firstIndex(of: question)
    }

    // MARK: - Session Flow

    /// Advances the session to the next question or participant
    private func advanceSession() {
        currentQuestionIndex += 1

        if currentQuestionIndex >= questions.count {
            // Finished all questions for current participant
            currentQuestionIndex = 0
            currentParticipantIndex += 1
        }
    }

    // MARK: - Analysis Methods

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

    /// Gets the question order for a specific participant (useful for debugging or analysis)
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
    func getOriginalQuestionIndex(for participant: String, displayIndex: Int)
        -> Int?
    {
        if isRandomized,
            let questionOrder = participantQuestionOrders[participant],
            displayIndex < questionOrder.count
        {
            return questionOrder[displayIndex]
        }
        return displayIndex < questions.count ? displayIndex : nil
    }

    /// Checks if a participant has completed all questions
    ///
    /// - Parameter participant: Name of the participant to check
    /// - Returns: True if participant has answered all questions
    func isParticipantComplete(_ participant: String) -> Bool {
        guard let responses = participantResponses[participant] else { return false }
        return responses.compactMap { $0 }.count == questions.count
    }

    // MARK: - Debug and Utility Methods

    /// Debug helper: Print question orders for all participants (useful for testing randomization)
    func printQuestionOrders() {
        print("=== Question Orders ===")
        print("Randomization enabled: \(isRandomized)")

        for participant in participants {
            print("\n\(participant):")
            if let order = getQuestionOrder(for: participant) {
                for (index, question) in order.enumerated() {
                    let originalIndex =
                        getOriginalQuestionIndex(
                            for: participant,
                            displayIndex: index
                        ) ?? -1
                    print(
                        "  \(index + 1). [Original #\(originalIndex + 1)] \(question)"
                    )
                }
            }
        }
        print("=====================")
    }

    // MARK: - Private Implementation

    /// Initializes response storage for all participants
    private func initializeParticipantResponses() {
        participantResponses.removeAll()
        for participant in participants {
            initializeResponsesForParticipant(participant)
        }
    }

    /// Initializes response storage for a specific participant
    ///
    /// - Parameter participant: Name of the participant
    private func initializeResponsesForParticipant(_ participant: String) {
        participantResponses[participant] = Array(
            repeating: nil,
            count: questions.count
        )
    }

    /// Generates randomized question orders for all participants
    private func generateRandomizedQuestionOrders() {
        participantQuestionOrders.removeAll()
        for participant in participants {
            generateRandomizedQuestionOrderForParticipant(participant)
        }
    }

    /// Generates a randomized question order for a specific participant
    ///
    /// - Parameter participant: Name of the participant
    private func generateRandomizedQuestionOrderForParticipant(
        _ participant: String
    ) {
        let questionIndices = Array(0..<questions.count)
        participantQuestionOrders[participant] = questionIndices.shuffled()
    }

    /// Gets the actual question index considering randomization
    ///
    /// - Parameters:
    ///   - participant: Name of the participant
    ///   - displayIndex: The index as displayed to the participant
    /// - Returns: The actual index in the original questionnaire
    private func getActualQuestionIndex(
        for participant: String,
        displayIndex: Int
    ) -> Int {
        if isRandomized,
            let questionOrder = participantQuestionOrders[participant],
            displayIndex < questionOrder.count
        {
            return questionOrder[displayIndex]
        }
        return displayIndex
    }
}

// MARK: - Questionnaire Integration Extensions
extension Overlap {
    /// Creates an Overlap from a Questionnaire template
    ///
    /// - Parameters:
    ///   - questionnaire: The questionnaire template to copy data from
    ///   - participants: Array of participant names
    ///   - randomizeQuestions: Whether to enable question randomization
    ///   - isOnline: Whether this is an online collaborative session
    /// - Returns: A new Overlap instance with questionnaire data copied
    static func from(
        questionnaire: Questionnaire,
        participants: [String] = [],
        randomizeQuestions: Bool = false,
        isOnline: Bool = false
    ) -> Overlap {
        return Overlap(
            participants: participants,
            isOnline: isOnline,
            questionnaire: questionnaire,
            randomizeQuestions: randomizeQuestions
        )
    }
}
