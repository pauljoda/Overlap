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
    
    /// Sets up SharingGRDB for previews with sample data
    @MainActor
    static func setup() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try populateSampleData()
        } catch {
            print("Failed to setup GRDB preview: \(error)")
        }
    }
    
    /// Populates the database with sample questionnaire data
    @MainActor
    private static func populateSampleData() throws {
        @Dependency(\.defaultDatabase) var database
        
        try database.write { db in
            // Clear existing data first
            try db.execute(sql: "DELETE FROM questionnaires")
            
            // Insert sample questionnaires
            try Questionnaire.insert {
                SampleData.sampleQuestionnaire
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.sampleQuestionnaire2
            }.execute(db)
            
            try Questionnaire.insert {
                SampleData.sampleQuestionnaire3
            }.execute(db)
        }
    }
}

/// Convenience function for use in previews
@MainActor
func setupGRDBPreview() {
    GRDBPreviewData.setup()
}
