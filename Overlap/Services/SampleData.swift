//
//  SampleData.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import Foundation
import SwiftData
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

    static let sampleQuestionnaire = QuestionnaireTable(
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

    static let sampleQuestionnaire2 = QuestionnaireTable(
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

    static let sampleQuestionnaire3 = QuestionnaireTable(
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
        let overlap = Overlap(
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
            try db.execute(sql: "DELETE FROM questionnaireTables")
            
            // Insert sample questionnaires
            try QuestionnaireTable.insert {
                sampleQuestionnaire
            }.execute(db)
            
            try QuestionnaireTable.insert {
                sampleQuestionnaire2
            }.execute(db)
            
            try QuestionnaireTable.insert {
                sampleQuestionnaire3
            }.execute(db)
        }
    }
    
    /// Standalone SharingGRDB preview setup - independent of SwiftData
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

// MARK: - SwiftData Preview Containers (Legacy - will be removed)

/// Legacy SwiftData-only preview container (no GRDB setup)
@MainActor
let swiftDataOnlyPreviewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: Overlap.self
        )

        // Clear existing overlaps
        try? container.mainContext.delete(model: Overlap.self)

        // Insert sample overlaps (Overlap still uses SwiftData)
        container.mainContext.insert(SampleData.sampleOverlap)
        container.mainContext.insert(SampleData.sampleInProgressOverlap)
        container.mainContext.insert(SampleData.sampleCompletedOverlap)
        return container
    } catch {
        fatalError("Failed to create SwiftData-only ModelContainer for previews: \(error)")
    }
}()

/// Combined preview container with both GRDB and SwiftData (transitional)
@MainActor
let previewModelContainer: ModelContainer = {
    do {
        // Setup the SharingGRDB database for previews
        let _ = try! prepareDependencies {
            $0.defaultDatabase = try appDatabase()
        }
        
        // Setup sample questionnaire data in the database
        try SampleData.setupPreviewDatabase()
        
        let container = try ModelContainer(
            for: Overlap.self
        )

        // Clear existing overlaps
        try? container.mainContext.delete(model: Overlap.self)

        // Insert sample overlaps (Overlap still uses SwiftData)
        container.mainContext.insert(SampleData.sampleOverlap)
        container.mainContext.insert(SampleData.sampleInProgressOverlap)
        container.mainContext.insert(SampleData.sampleCompletedOverlap)
        return container
    } catch {
        fatalError("Failed to create ModelContainer for previews: \(error)")
    }
}()
