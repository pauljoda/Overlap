//
//  GRDBPreviewData.swift
//  Overlap
//
//  Standalone SharingGRDB preview setup - independent of SwiftData
//
//  MIGRATION PATH:
//  1. Current: Use `previewModelContainer` for views that need both GRDB and SwiftData
//  2. Transition: Use dual previews to test both patterns side by side
//  3. Future: Use `setupGRDBPreview()` for GRDB-only previews (no ModelContainer)
//  4. Final: Remove all SwiftData dependencies and ModelContainer usage
//

import Foundation
import SwiftUI
import SharingGRDB

/// Standalone preview setup for SharingGRDB - no SwiftData dependencies
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
            try db.execute(sql: "DELETE FROM questionnaireTables")
            
            // Insert sample questionnaires
            try QuestionnaireTable.insert {
                SampleData.sampleQuestionnaire
            }.execute(db)
            
            try QuestionnaireTable.insert {
                SampleData.sampleQuestionnaire2
            }.execute(db)
            
            try QuestionnaireTable.insert {
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
