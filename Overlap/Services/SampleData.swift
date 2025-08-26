//
//  SampleData.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftUI
import SharingGRDB

class SampleData {
    static let sampleQuestions: [String] = [
        "Do you like pizza?",
        "Is Swift your favorite programming language?",
        "Do you enjoy outdoor activities?",
        "Have you ever traveled abroad?",
        "Do you prefer tea over coffee?",
    ]

    static let sampleQuestionnaire = Questionnaire(
        title: "Sample Questionnaire",
        description:
            "A fun sample questionnaire to test the Overlap app. This questionnaire is designed to be lighthearted and entertaining. It includes a variety of questions that cover different topics, from food preferences to travel experiences.",
        instructions:
            "Respond to each question honestly, select the best answer for each one. This questionnaire is for fun only and does not reflect any personal opinions or beliefs. The results are purely statistical and should not be interpreted as any kind of opinion or prediction. Good luck!",
        questions: SampleData.sampleQuestions,
        iconEmoji: "🍕",
    )

    static let sampleQuestions2: [String] = [
        "Have you ever gone skydiving?",
        "Do you speak more than one language?",
        "Is summer your favorite season?",
        "Do you play a musical instrument?",
        "Have you ever run a marathon?",
    ]

    static let sampleQuestionnaire2 = Questionnaire(
        title: "Adventure & Experience Quiz",
        description: "A short quiz about adventure and personal experiences.",
        instructions:
            "Select the answer that best matches your experience. Be honest for the most interesting results!",
        questions: SampleData.sampleQuestions2,
        iconEmoji: "🏔️"
    )

    static let sampleQuestions3: [String] = [
        "Do you enjoy reading books?",
        "Is science fiction your favorite genre?",
        "Do you own a pet?",
        "Have you ever written a story?",
        "Do you visit the library regularly?",
    ]

    static let sampleQuestionnaire3 = Questionnaire(
        title: "Reading & Hobbies Survey",
        description: "A lighthearted survey about reading habits and hobbies.",
        instructions:
            "Answer each question based on your current habits and interests.",
        questions: SampleData.sampleQuestions3,
        iconEmoji: "📚"
    )

    static let sampleParticipants = ["John", "Sally"]

    static let sampleOverlap = Overlap(
        participants: sampleParticipants,
        questionnaire: SampleData.sampleQuestionnaire,
        currentState: .instructions
    )

    static let sampleRandomizedOverlap = Overlap(
        participants: sampleParticipants,
        questionnaire: SampleData.sampleQuestionnaire,
        randomizeQuestions: true,
        currentState: .instructions
    )

    static let sampleInProgressOverlap = Overlap(
        participants: ["Alice", "Bob", "Carol"],
        questionnaire: SampleData.sampleQuestionnaire2,
        currentState: .answering
    )

    static let sampleCompletedOverlap: Overlap = {
        var overlap = Overlap(
            participants: ["David", "Emma", "Frank"],
            questionnaire: SampleData.sampleQuestionnaire3,
            currentState: .complete
        )
        overlap.completeDate = Date.now.addingTimeInterval(-86400)  // Yesterday
        overlap.isCompleted = true
        return overlap
    }()
    
    /// Sets up preview database with sample questionnaires
    @MainActor
    static func setupPreviewDatabase() throws {
        @Dependency(\.defaultDatabase) var database
        
        // Insert sample questionnaires into the database
        try database.write { db in
            // Clear existing data first
            try db.execute(sql: "DELETE FROM questionnaires")
            
            // Insert sample questionnaires
            try Questionnaire.insert {
                sampleQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                sampleQuestionnaire2
            }.execute(db)
            
            try Questionnaire.insert {
                sampleQuestionnaire3
            }.execute(db)
        }
    }
    
    /// SharingGRDB preview setup
    @MainActor
    static func setupGRDBPreview() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try setupPreviewDatabase()
        } catch {
            print("Failed to setup GRDB preview: \(error)")
        }
    }
}
