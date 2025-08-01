//
//  QuestionnaireCompleteView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

struct QuestionnaireCompleteView: View {
    let overlap: Overlap
    @State private var isAnimated = false
    
    @Environment(\.navigationPath) private var navigationPath

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: .none)
            
            // Scrollable Content - Full screen
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    CompletionHeader(isAnimated: isAnimated, overlap: overlap)
                    
                    // Results Section
                    OverlapResultsView(overlap: overlap, isAnimated: isAnimated)
                    
                    // Bottom padding to account for floating button
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 120) // Increased to account for button height
                }
            }
            
            // Floating Done Button - Overlays at bottom
            VStack {
                Spacer()
                
                GlassActionButton(
                    title: "Done",
                    isEnabled: true,
                    tintColor: .blue,
                    action: startNewOverlap
                )
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 50)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(2.0), value: isAnimated)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            isAnimated = true
        }
    }
    
    private func startNewOverlap() {
        navigationPath.wrappedValue.removeLast(navigationPath.wrappedValue.count)
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
        overlap.session.setParticipants(["Alice", "Bob", "Charlie"])
        
        // Simulate response patterns
        let responsePatterns = [
            [Answer.yes, .yes, .maybe, .no, .yes],      // Alice
            [Answer.yes, .yes, .yes, .yes, .yes],       // Bob  
            [Answer.yes, .yes, .maybe, .maybe, .maybe]  // Charlie
        ]
        
        // Reset and populate responses
        overlap.session.resetSession()
        for pattern in responsePatterns {
            for answer in pattern {
                _ = overlap.session.saveCurrentAnswer(answer)
            }
        }
        
        return overlap
    }()
    
    QuestionnaireCompleteView(overlap: sampleOverlapWithResponses)
}
