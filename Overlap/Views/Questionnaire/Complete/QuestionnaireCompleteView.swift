//
//  QuestionnaireCompleteView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SharingGRDB

struct QuestionnaireCompleteView: View {
    @Binding var overlap: Overlap
    @Dependency(\.defaultDatabase) var database
    @State private var isAnimated = false
    
    @Environment(\.navigationPath) private var navigationPath

    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.tripleXL) {
                    // Header Section
                    CompletionHeader(isAnimated: isAnimated, overlap: overlap)
            
                    
                    // Results Section
                    OverlapResultsView(overlap: overlap, isAnimated: isAnimated)
                    
                    // Bottom padding to account for floating button
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: Tokens.Spacing.quadXL * 3) // Increased to account for button height
                }
        }
        .onAppear {
            isAnimated = true
            
            // Set and persist completion date if not already set
            if overlap.completeDate == nil {
                overlap.completeDate = Date.now
                withErrorReporting {
                    try database.write { db in
                        try Overlap.update(overlap).execute(db)
                    }
                }
            }
        }
    }
    
    private func startNewOverlap() {
        navigationPath.wrappedValue.removeLast(navigationPath.wrappedValue.count)
    }
}

#Preview {
    // Create a sample overlap with completed responses for visualization
    var sampleOverlapWithResponses: Overlap = {
        var overlap = Overlap(
            participants: ["Alice", "Bob", "Charlie"],
            questionnaire: SampleData.sampleQuestionnaire,
            currentState: .complete
        )
        
        // Set a completion date for preview
        overlap.completeDate = Date.now
        
        // Initialize the session and simulate responses
        overlap.setParticipants(["Alice", "Bob", "Charlie"])
        
        // Simulate response patterns
        let responsePatterns = [
            [Answer.yes, .yes, .maybe, .no, .yes],      // Alice
            [Answer.yes, .yes, .yes, .yes, .yes],       // Bob  
            [Answer.yes, .yes, .maybe, .maybe, .maybe]  // Charlie
        ]
        
        // Reset and populate responses
        overlap.resetSession()
        for pattern in responsePatterns {
            for answer in pattern {
                _ = overlap.saveResponse(answer: answer)
            }
        }
        
        return overlap
    }()
    
    QuestionnaireCompleteView(overlap: .constant(sampleOverlapWithResponses))
}
