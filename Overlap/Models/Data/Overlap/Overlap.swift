//
//  Overlap.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftData
import SwiftUI

enum OverlapState: String, Codable, CaseIterable {
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
@Model
class Overlap: ColorCustomizable {
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
    /// Whether this overlap is intended to be online (stored property)
    private var _isOnline: Bool = false
    
    /// Whether this is an online collaborative session or local only
    var isOnline: Bool {
        get {
            return _isOnline
        }
        set {
            _isOnline = newValue
        }
    }
    
    /// Whether the current user is the owner (created the overlap)
    var isOwner: Bool {
        return true  // Always true since sharing is disabled
    }

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
    var participantResponses: [String: [Answer?]] = [:]
    
    // MARK: - Visual Customization (copied from Questionnaire)
    /// Icon emoji for the overlap session
    var iconEmoji: String = "📝"
    
    // Simple color storage using RGBA components for start color
    var startColorRed: Double = 0.0
    var startColorGreen: Double = 0.0
    var startColorBlue: Double = 1.0
    var startColorAlpha: Double = 1.0
    
    // Simple color storage using RGBA components for end color
    var endColorRed: Double = 0.5
    var endColorGreen: Double = 0.0
    var endColorBlue: Double = 0.5
    var endColorAlpha: Double = 1.0

    // MARK: - Randomization Settings
    /// Whether question randomization is enabled for this session
    var isRandomized: Bool = false
    /// Question order mappings for each participant (used when randomization is enabled)
    var participantQuestionOrders: [String: [Int]] = [:]

    // MARK: - Session State
    /// Current position in the participant list
    var currentParticipantIndex: Int = 0
    /// Current question index for the active participant
    var currentQuestionIndex: Int = 0
    /// Overall session state for UI navigation (stored as String for SwiftData compatibility)
    private var currentStateRaw: String = OverlapState.instructions.rawValue
    /// Whether the overlap session has been completed (stored property for SwiftData queries)
    var isCompleted: Bool = false
    
    // MARK: - CloudKit Sync Support
    /// Data storage for the last known CloudKit record (for conflict resolution)
    var lastKnownRecordData: Data?
    
    /// Public interface for currentState with safe conversion
    var currentState: OverlapState {
        get {
            return OverlapState(rawValue: currentStateRaw) ?? .instructions
        }
        set {
            currentStateRaw = newValue.rawValue
        }
    }

        // MARK: - Initialization

    /// Core designated initializer with all properties
    /// Other convenience initializers are in Overlap+Initialization.swift
    init(
        id: UUID,
        beginDate: Date,
        completeDate: Date?,
        participants: [String],
        isOnline: Bool,
        title: String,
        information: String,
        instructions: String,
        questions: [String],
        iconEmoji: String,
        startColorRed: Double,
        startColorGreen: Double,
        startColorBlue: Double,
        startColorAlpha: Double,
        endColorRed: Double,
        endColorGreen: Double,
        endColorBlue: Double,
        endColorAlpha: Double,
        randomizeQuestions: Bool,
        currentState: OverlapState,
        currentParticipantIndex: Int,
        currentQuestionIndex: Int,
        isCompleted: Bool
    ) {
        self.id = id
        self.beginDate = beginDate
        self.completeDate = completeDate
        self.participants = participants
        self._isOnline = isOnline
        self.title = title
        self.information = information
        self.instructions = instructions
        self.questions = questions
        self.iconEmoji = iconEmoji
        self.startColorRed = startColorRed
        self.startColorGreen = startColorGreen
        self.startColorBlue = startColorBlue
        self.startColorAlpha = startColorAlpha
        self.endColorRed = endColorRed
        self.endColorGreen = endColorGreen
        self.endColorBlue = endColorBlue
        self.endColorAlpha = endColorAlpha
        self.isRandomized = randomizeQuestions
        self.currentState = currentState
        self.currentParticipantIndex = currentParticipantIndex
        self.currentQuestionIndex = currentQuestionIndex
        self.isCompleted = isCompleted

        initializeParticipantResponses()
        if randomizeQuestions {
            generateRandomizedQuestionOrders()
        }
    }
}
