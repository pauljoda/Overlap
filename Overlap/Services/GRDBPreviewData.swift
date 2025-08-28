//
//  GRDBPreviewData.swift
//  Overlap
//
//  SharingGRDB preview setup
//
//  Provides preview data setup for SharingGRDB-based views.
//

import Foundation
import SwiftUI
import SharingGRDB

/// Preview setup for SharingGRDB
struct GRDBPreviewData {
    
    /// Sets up SharingGRDB for previews with comprehensive sample data
    @MainActor
    static func setup() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try populateComprehensiveSampleData()
        } catch {
            print("Failed to setup GRDB preview: \(error)")
        }
    }
    
    /// Populates the database with comprehensive sample questionnaire data for testing all states
    @MainActor
    private static func populateComprehensiveSampleData() throws {
        @Dependency(\.defaultDatabase) var database
        
        try database.write { db in
            // Clear existing data first
            try db.execute(sql: "DELETE FROM questionnaires")
            try db.execute(sql: "DELETE FROM overlaps")
            
            // Insert all sample questionnaires
            try Questionnaire.insert {
                SampleData.foodPreferencesQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.techInterestsQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.lifestyleQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.adventureQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.hobbiesQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.creativityQuestionnaire
            }.execute(db)
            
            // Insert overlaps in various states for comprehensive testing
            try Overlap.insert {
                SampleData.instructionsOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.earlyAnsweringOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.midProgressOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.nextParticipantOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.awaitingResponsesOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.recentlyCompletedOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.olderCompletedOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.randomizedOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.largeGroupOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.onlineCollaborativeOverlap
            }.execute(db)
        }
    }
    
    /// Sets up minimal preview data for simple test cases
    @MainActor
    static func setupMinimal() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try populateMinimalSampleData()
        } catch {
            print("Failed to setup minimal GRDB preview: \(error)")
        }
    }
    
    /// Populates the database with just basic questionnaire data
    @MainActor
    private static func populateMinimalSampleData() throws {
        @Dependency(\.defaultDatabase) var database
        
        try database.write { db in
            // Clear existing data first
            try db.execute(sql: "DELETE FROM questionnaires")
            try db.execute(sql: "DELETE FROM overlaps")
            
            // Insert just the legacy sample questionnaires for backwards compatibility
            try Questionnaire.insert {
                SampleData.sampleQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.sampleQuestionnaire2
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.sampleQuestionnaire3
            }.execute(db)
            
            // Insert a few basic overlaps
            try Overlap.insert {
                SampleData.sampleOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.sampleInProgressOverlap
            }.execute(db)
            
            try Overlap.insert {
                SampleData.sampleCompletedOverlap
            }.execute(db)
        }
    }
}

/// Convenience function for use in previews - sets up comprehensive data
@MainActor
func setupGRDBPreview() {
    GRDBPreviewData.setup()
}

/// Convenience function for use in previews - sets up minimal data for simple cases
@MainActor
func setupMinimalGRDBPreview() {
    GRDBPreviewData.setupMinimal()
}
