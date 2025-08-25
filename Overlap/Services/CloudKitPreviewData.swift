//
//  CloudKitPreviewData.swift
//  Overlap
//
//  Preview data for testing CloudKit features
//

import Foundation
import SwiftData
import SwiftUI
import SharingGRDB

extension SampleData {
    /// Sample online overlap for testing CloudKit features
    static let sampleOnlineOverlap = Overlap(
        participants: ["Alice", "Bob"],
        isOnline: true,
        questionnaire: SampleData.sampleQuestionnaire,
        currentState: .instructions
    )
    
    /// Sample overlap with unread changes (simulated)
    static let sampleOverlapWithUpdates: Overlap = {
        let overlap = Overlap(
            participants: ["You", "Charlie", "Dana"],
            isOnline: true,
            questionnaire: SampleData.sampleQuestionnaire2,
            currentState: .answering
        )
        // Add some sample responses to simulate activity
        overlap.saveResponse(answer: .yes) // First question answered
        return overlap
    }()
    
    /// Sample completed online overlap
    static let sampleCompletedOnlineOverlap: Overlap = {
        let overlap = Overlap(
            participants: ["Team Lead", "Designer", "Developer"],
            isOnline: true,
            questionnaire: SampleData.sampleQuestionnaire3,
            currentState: .complete
        )
        overlap.completeDate = Date.now.addingTimeInterval(-3600) // 1 hour ago
        overlap.isCompleted = true
        return overlap
    }()
}

@MainActor
let cloudKitPreviewContainer: ModelContainer = {
    do {
        // Setup the SharingGRDB database for previews
        let _ = try! prepareDependencies {
            $0.defaultDatabase = try appDatabase()
        }
        
        // Setup sample questionnaire data in the database
        try SampleData.setupPreviewDatabase()
        
        let configuration = ModelConfiguration("OverlapContainer", cloudKitDatabase: .private("iCloud.com.pauljoda.Overlap"))
        
        let container = try ModelContainer(
            for:
            Overlap.self,
            configurations: configuration
        )
        
        // Clear existing data
        try? container.mainContext.delete(model: Overlap.self)
        

        // Add mixed local and online overlaps
        container.mainContext.insert(SampleData.sampleOverlap) // Local
        container.mainContext.insert(SampleData.sampleOnlineOverlap) // Online
        container.mainContext.insert(SampleData.sampleInProgressOverlap) // Local in progress
        container.mainContext.insert(SampleData.sampleOverlapWithUpdates) // Online with activity
        container.mainContext.insert(SampleData.sampleCompletedOverlap) // Local completed
        container.mainContext.insert(SampleData.sampleCompletedOnlineOverlap) // Online completed
        
        return container
    } catch {
        fatalError("Failed to create CloudKit preview container: \(error)")
    }
}()
