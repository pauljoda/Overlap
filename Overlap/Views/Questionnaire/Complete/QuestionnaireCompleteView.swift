//
//  QuestionnaireCompleteView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireCompleteView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @State private var isAnimated = false

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

            // Set completion date if not already set
            if overlap.completeDate == nil {
                overlap.completeDate = Date.now
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    // Create a sample overlap with completed responses for visualization
    let sampleOverlapWithResponses: Overlap = {
        let overlap = Overlap(
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
    
    QuestionnaireCompleteView(overlap: sampleOverlapWithResponses)
}
