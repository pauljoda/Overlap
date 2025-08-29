//
//  Overlap.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftUI
import SharingGRDB

enum OverlapState: String, Codable, CaseIterable, QueryBindable {
    case instructions = "instructions"
    case answering = "answering"
    case nextParticipant = "nextParticipant"
    case awaitingResponses = "awaitingResponses"
    case complete = "complete"
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
/// - **Response Storage**: Maintains participant responses
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
@Table
struct Overlap: Identifiable, Hashable {
    // MARK: - Session Information
    /// The unique identifier for this overlap session
    let id: UUID
    /// Start date of the overlap session
    var beginDate: Date = Date.now
    /// Completion date when all participants have finished
    var completeDate: Date?

    // MARK: - Collaboration Settings
    /// List of participant names in this overlap session
    @Column(as: [String].JSONRepresentation.self)
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
    @Column(as: [String].JSONRepresentation.self)
    var questions: [String] = []
    /// Storage for all participant responses organized by participant name and question index
    @Column(as: [String: [Answer?]].JSONRepresentation.self)
    var participantResponses: [String: [Answer?]] = [:]
    
    // MARK: - Visual Customization (copied from Questionnaire)
    /// Icon emoji for the overlap session
    var iconEmoji: String = "📝"
    
    @Column(as: Color.HexRepresentation.self)
    var startColor: Color = .blue
    
    @Column(as: Color.HexRepresentation.self)
    var endColor: Color = .purple

    // MARK: - Randomization Settings
    /// Whether question randomization is enabled for this session
    var isRandomized: Bool = false
    /// Question order mappings for each participant (used when randomization is enabled)
    @Column(as: [String: [Int]].JSONRepresentation.self)
    var participantQuestionOrders: [String: [Int]] = [:]

    // MARK: - Session State
    /// Current position in the participant list
    var currentParticipantIndex: Int = 0
    /// Current question index for the active participant
    var currentQuestionIndex: Int = 0
    /// Overall session state for UI navigation
    var currentState: OverlapState = OverlapState.instructions
    /// Whether the overlap session has been completed
    var isCompleted: Bool = false

    // MARK: - Computed Properties

    // Computed properties moved to Overlap+State.swift
    
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
        self.information = questionnaire.description
        self.instructions = questionnaire.instructions
        self.questions = questionnaire.questions
        
        // Copy visual customization properties
        self.iconEmoji = questionnaire.iconEmoji
        
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
        iconEmoji: String = "📝",
        startColor: Color = .blue,
        endColor: Color = .purple,
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
        self.iconEmoji = iconEmoji
        self.isRandomized = randomizeQuestions
        self.currentState = currentState
        self.isCompleted = (currentState == .complete)
        
        // Set colors using the computed properties
        self.startColor = startColor
        self.endColor = endColor

        initializeParticipantResponses()
        if randomizeQuestions {
            generateRandomizedQuestionOrders()
        }
    }
}
