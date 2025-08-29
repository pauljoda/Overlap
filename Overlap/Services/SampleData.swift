//
//  SampleData.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//
//  Comprehensive sample data for testing all interface states and scenarios.
//
//  This file provides extensive sample data including:
//  - 6 diverse questionnaires covering different topics
//  - 10+ overlaps in various states (instructions, answering, complete, etc.)
//  - Multiple participant groups for different scenarios
//  - Online/offline and randomized question examples
//  - Time-based scenarios (recent vs older completions)
//

import Foundation
import SwiftUI
import SharingGRDB

class SampleData {
    // MARK: - Sample Questions
    static let foodQuestions: [String] = [
        "Do you like pizza?",
        "Do you prefer chocolate over vanilla?",
        "Are you a morning coffee person?",
        "Do you enjoy spicy food?",
        "Have you ever tried sushi?",
        "Do you prefer cooking over ordering takeout?",
        "Are you vegetarian or vegan?",
        "Do you have a sweet tooth?"
    ]
    
    static let technologyQuestions: [String] = [
        "Is Swift your favorite programming language?",
        "Do you prefer iOS over Android?",
        "Are you excited about AI development?",
        "Do you use a Mac for development?",
        "Have you built an app before?",
        "Do you enjoy debugging code?",
        "Are you interested in AR/VR?",
        "Do you prefer native over cross-platform development?"
    ]
    
    static let lifestyleQuestions: [String] = [
        "Do you enjoy outdoor activities?",
        "Have you ever traveled abroad?",
        "Do you prefer tea over coffee?",
        "Are you a morning person?",
        "Do you exercise regularly?",
        "Have you ever been camping?",
        "Do you enjoy concerts or live music?",
        "Are you more of an introvert or extrovert?"
    ]
    
    static let adventureQuestions: [String] = [
        "Have you ever gone skydiving?",
        "Do you speak more than one language?",
        "Is summer your favorite season?",
        "Do you play a musical instrument?",
        "Have you ever run a marathon?",
        "Would you go bungee jumping?",
        "Have you been on a road trip?",
        "Do you enjoy trying new cuisines?"
    ]
    
    static let hobbyQuestions: [String] = [
        "Do you enjoy reading books?",
        "Is science fiction your favorite genre?",
        "Do you own a pet?",
        "Have you ever written a story?",
        "Do you visit the library regularly?",
        "Are you into photography?",
        "Do you enjoy board games?",
        "Have you ever learned a new language as an adult?"
    ]
    
    static let creativityQuestions: [String] = [
        "Do you consider yourself artistic?",
        "Have you ever painted or drawn regularly?",
        "Do you enjoy crafting or DIY projects?",
        "Are you interested in interior design?",
        "Have you ever written poetry?",
        "Do you play any musical instruments?",
        "Are you good at coming up with creative solutions?",
        "Do you enjoy watching documentaries?"
    ]

    // MARK: - Sample Questionnaires
    static let foodPreferencesQuestionnaire = Questionnaire(
        title: "Food & Taste Preferences",
        description: "A fun exploration of culinary preferences and food experiences. Discover what you have in common with friends and family when it comes to taste, cooking, and dining habits.",
        instructions: "Answer honestly about your food preferences and experiences. There are no right or wrong answers - just your personal taste!",
        questions: foodQuestions,
        iconEmoji: "🍕"
    )
    
    static let techInterestsQuestionnaire = Questionnaire(
        title: "Tech Enthusiast Quiz",
        description: "Explore your technology preferences and development interests. Perfect for comparing perspectives with fellow developers and tech enthusiasts.",
        instructions: "Select the answer that best reflects your technology preferences and experiences. Be honest for the most interesting results!",
        questions: technologyQuestions,
        iconEmoji: "💻"
    )
    
    static let lifestyleQuestionnaire = Questionnaire(
        title: "Lifestyle & Personality",
        description: "A comprehensive look at lifestyle choices and personality traits. Great for understanding how similar or different you are from your friends.",
        instructions: "Choose the response that best describes your typical behavior or preference. Remember, there's no judgment here!",
        questions: lifestyleQuestions,
        iconEmoji: "🌟"
    )

    static let adventureQuestionnaire = Questionnaire(
        title: "Adventure & Experience Quiz",
        description: "Discover your adventurous side and compare experiences with others. From adrenaline activities to cultural experiences.",
        instructions: "Select the answer that best matches your experience. Be honest for the most interesting results!",
        questions: adventureQuestions,
        iconEmoji: "🏔️"
    )

    static let hobbiesQuestionnaire = Questionnaire(
        title: "Reading & Hobbies Survey",
        description: "A lighthearted survey about reading habits, hobbies, and personal interests. Perfect for book clubs and hobby groups.",
        instructions: "Answer each question based on your current habits and interests.",
        questions: hobbyQuestions,
        iconEmoji: "📚"
    )
    
    static let creativityQuestionnaire = Questionnaire(
        title: "Creative Expression & Arts",
        description: "Explore your creative side and artistic interests. Compare your creative preferences and experiences with others.",
        instructions: "Answer based on your genuine interest and experience with creative activities.",
        questions: creativityQuestions,
        iconEmoji: "🎨"
    )

    // MARK: - Sample Participants
    static let teamMembers = ["Alex", "Jordan", "Taylor", "Casey", "Morgan"]
    static let friendGroup = ["Emma", "Liam", "Olivia", "Noah", "Ava"]
    static let familyMembers = ["Mom", "Dad", "Sarah", "Michael"]
    static let colleagues = ["Jennifer", "David", "Lisa", "Robert", "Amanda"]
    
    // MARK: - Sample Overlaps in Various States
    
    // Instructions State
    static let instructionsOverlap = Overlap(
        participants: teamMembers,
        questionnaire: foodPreferencesQuestionnaire,
        currentState: .instructions
    )
    
    // Early Answering State
    static let earlyAnsweringOverlap: Overlap = {
        var overlap = Overlap(
            participants: friendGroup,
            questionnaire: techInterestsQuestionnaire,
            currentState: .answering
        )
        overlap.currentParticipantIndex = 0
        overlap.currentQuestionIndex = 2
        return overlap
    }()
    
    // Mid-Progress Answering State
    static let midProgressOverlap: Overlap = {
        var overlap = Overlap(
            participants: familyMembers,
            questionnaire: lifestyleQuestionnaire,
            currentState: .answering
        )
        overlap.currentParticipantIndex = 1
        overlap.currentQuestionIndex = 4
        return overlap
    }()
    
    // Next Participant State
    static let nextParticipantOverlap: Overlap = {
        var overlap = Overlap(
            participants: colleagues,
            questionnaire: adventureQuestionnaire,
            currentState: .nextParticipant
        )
        overlap.currentParticipantIndex = 2
        overlap.currentQuestionIndex = 0
        return overlap
    }()
    
    // Awaiting Responses (Online) State
    static let awaitingResponsesOverlap: Overlap = {
        var overlap = Overlap(
            participants: teamMembers,
            isOnline: true,
            questionnaire: hobbiesQuestionnaire,
            currentState: .awaitingResponses
        )
        return overlap
    }()
    
    // Awaiting Responses (Online) with some participants completed
    static let awaitingResponsesPartialOverlap: Overlap = {
        var overlap = Overlap(
            participants: ["Alex", "Jordan", "Taylor", "Casey"],
            isOnline: true,
            questionnaire: hobbiesQuestionnaire,
            randomizeQuestions: true,
            currentState: .awaitingResponses
        )
        // Simulate two completed participants
        let allYes = Array(repeating: Answer.yes as Answer?, count: overlap.questions.count)
        overlap.participantResponses["Alex"] = allYes
        overlap.participantResponses["Jordan"] = allYes
        // Others pending (default nils)
        overlap.participantResponses["Taylor"] = Array(repeating: nil, count: overlap.questions.count)
        overlap.participantResponses["Casey"] = Array(repeating: nil, count: overlap.questions.count)
        return overlap
    }()
    
    // Recently Completed State
    static let recentlyCompletedOverlap: Overlap = {
        var overlap = Overlap(
            participants: friendGroup,
            questionnaire: creativityQuestionnaire,
            currentState: .complete
        )
        overlap.completeDate = Date.now.addingTimeInterval(-3600) // 1 hour ago
        overlap.isCompleted = true
        return overlap
    }()
    
    // Older Completed State
    static let olderCompletedOverlap: Overlap = {
        var overlap = Overlap(
            participants: familyMembers,
            questionnaire: foodPreferencesQuestionnaire,
            currentState: .complete
        )
        overlap.completeDate = Date.now.addingTimeInterval(-86400 * 3) // 3 days ago
        overlap.isCompleted = true
        return overlap
    }()
    
    // Randomized Questions Overlap
    static let randomizedOverlap = Overlap(
        participants: colleagues,
        questionnaire: techInterestsQuestionnaire,
        randomizeQuestions: true,
        currentState: .instructions
    )
    
    // Completed (Randomized) Overlap for results testing
    static let completedRandomizedOverlap: Overlap = {
        var overlap = Overlap(
            participants: ["Ava", "Liam", "Noah"],
            questionnaire: techInterestsQuestionnaire,
            randomizeQuestions: true,
            currentState: .complete
        )
        let answersA = Array(repeating: Answer.yes as Answer?, count: overlap.questions.count)
        let answersB = Array(repeating: Answer.no as Answer?, count: overlap.questions.count)
        let answersC = Array(repeating: Answer.maybe as Answer?, count: overlap.questions.count)
        overlap.participantResponses["Ava"] = answersA
        overlap.participantResponses["Liam"] = answersB
        overlap.participantResponses["Noah"] = answersC
        overlap.completeDate = Date.now.addingTimeInterval(-7200)
        overlap.isCompleted = true
        return overlap
    }()
    
    // Large Group Overlap
    static let largeGroupOverlap: Overlap = {
        let largeGroup = ["Person1", "Person2", "Person3", "Person4", "Person5", "Person6", "Person7", "Person8"]
        return Overlap(
            participants: largeGroup,
            questionnaire: lifestyleQuestionnaire,
            currentState: .answering
        )
    }()
    
    // Online Collaborative Overlap
    static let onlineCollaborativeOverlap: Overlap = {
        var overlap = Overlap(
            participants: teamMembers,
            isOnline: true,
            questionnaire: adventureQuestionnaire,
            currentState: .answering
        )
        overlap.currentParticipantIndex = 0
        overlap.currentQuestionIndex = 1
        return overlap
    }()
    
    // MARK: - Legacy Sample Data (for backwards compatibility)
    static let sampleQuestions = foodQuestions
    static let sampleQuestionnaire = foodPreferencesQuestionnaire
    static let sampleQuestions2 = adventureQuestions
    static let sampleQuestionnaire2 = adventureQuestionnaire
    static let sampleQuestions3 = hobbyQuestions
    static let sampleQuestionnaire3 = hobbiesQuestionnaire
    static let sampleParticipants = teamMembers
    
    static let sampleOverlap = instructionsOverlap
    static let sampleRandomizedOverlap = randomizedOverlap
    static let sampleInProgressOverlap = midProgressOverlap
    static let sampleCompletedOverlap = recentlyCompletedOverlap
    
    /// Sets up preview database with comprehensive sample questionnaires and overlaps
    @MainActor
    static func setupComprehensivePreviewDatabase() throws {
        @Dependency(\.defaultDatabase) var database
        try database.write { db in
            // Clear existing data first
            try db.execute(sql: "DELETE FROM questionnaires")
            try db.execute(sql: "DELETE FROM overlaps")

            // Insert all sample questionnaires
            for questionnaire in allQuestionnaires {
                try Questionnaire.insert { questionnaire }.execute(db)
            }

            // Insert overlaps in various states for comprehensive testing
            for overlap in allOverlaps {
                try Overlap.insert { overlap }.execute(db)
            }
        }
    }

    /// Sets up preview database with minimal sample data (legacy-compatible)
    @MainActor
    static func setupMinimalPreviewDatabase() throws {
        @Dependency(\.defaultDatabase) var database
        try database.write { db in
            // Clear existing data first
            try db.execute(sql: "DELETE FROM questionnaires")
            try db.execute(sql: "DELETE FROM overlaps")

            // Insert just the legacy sample questionnaires for backwards compatibility
            try Questionnaire.insert { sampleQuestionnaire }.execute(db)
            try Questionnaire.insert { sampleQuestionnaire2 }.execute(db)
            try Questionnaire.insert { sampleQuestionnaire3 }.execute(db)

            // Insert a few basic overlaps
            try Overlap.insert { sampleOverlap }.execute(db)
            try Overlap.insert { sampleInProgressOverlap }.execute(db)
            try Overlap.insert { sampleCompletedOverlap }.execute(db)
        }
    }
    
    /// SharingGRDB preview setup
    @MainActor
    static func setupGRDBPreview() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try setupComprehensivePreviewDatabase()
        } catch {
            print("Failed to setup GRDB preview: \(error)")
        }
    }
    
    // MARK: - Collections for Easy Access
    
    /// All sample questionnaires organized by category
    static let allQuestionnaires: [Questionnaire] = [
        foodPreferencesQuestionnaire,
        techInterestsQuestionnaire,
        lifestyleQuestionnaire,
        adventureQuestionnaire,
        hobbiesQuestionnaire,
        creativityQuestionnaire
    ]
    
    /// All sample overlaps organized by state
    static let allOverlaps: [Overlap] = [
        instructionsOverlap,
        earlyAnsweringOverlap,
        midProgressOverlap,
        nextParticipantOverlap,
        awaitingResponsesOverlap,
        awaitingResponsesPartialOverlap,
        recentlyCompletedOverlap,
        olderCompletedOverlap,
        randomizedOverlap,
        completedRandomizedOverlap,
        largeGroupOverlap,
        onlineCollaborativeOverlap
    ]
    
    /// Overlaps grouped by state for specific testing
    static let overlapsByState: [OverlapState: [Overlap]] = [
        .instructions: [instructionsOverlap, randomizedOverlap],
        .answering: [earlyAnsweringOverlap, midProgressOverlap, largeGroupOverlap, onlineCollaborativeOverlap],
        .nextParticipant: [nextParticipantOverlap],
        .awaitingResponses: [awaitingResponsesOverlap, awaitingResponsesPartialOverlap],
        .complete: [recentlyCompletedOverlap, olderCompletedOverlap, completedRandomizedOverlap]
    ]
    
    /// Get a random questionnaire for testing
    static func randomQuestionnaire() -> Questionnaire {
        return allQuestionnaires.randomElement() ?? foodPreferencesQuestionnaire
    }
    
    /// Get a random overlap for testing
    static func randomOverlap() -> Overlap {
        return allOverlaps.randomElement() ?? instructionsOverlap
    }
    
    /// Get overlaps in a specific state
    static func overlaps(in state: OverlapState) -> [Overlap] {
        return overlapsByState[state] ?? []
    }
}
