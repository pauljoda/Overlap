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
        
        // Get question IDs from sample questions
        let questions = SampleData.sampleQuestions
        
        // Create responses for Alice
        let aliceResponses = Responses(
            user: "Alice",
            answers: [
                questions[0].id: Answer(type: .yes, text: "Yes"),      // Pizza - everyone agrees
                questions[1].id: Answer(type: .yes, text: "Yes"),      // Swift - everyone agrees
                questions[2].id: Answer(type: .maybe, text: "Maybe"),  // Outdoor - partial agreement
                questions[3].id: Answer(type: .no, text: "No"),        // Travel - disagreement
                questions[4].id: Answer(type: .yes, text: "Coffee")    // Tea vs Coffee - disagreement
            ]
        )
        
        // Create responses for Bob
        let bobResponses = Responses(
            user: "Bob",
            answers: [
                questions[0].id: Answer(type: .yes, text: "Yes"),      // Pizza - everyone agrees
                questions[1].id: Answer(type: .yes, text: "Yes"),      // Swift - everyone agrees
                questions[2].id: Answer(type: .yes, text: "Yes"),      // Outdoor - partial agreement
                questions[3].id: Answer(type: .yes, text: "Yes"),      // Travel - disagreement
                questions[4].id: Answer(type: .yes, text: "Coffee")        // Tea vs Coffee - disagreement
            ]
        )
        
        // Create responses for Charlie
        let charlieResponses = Responses(
            user: "Charlie",
            answers: [
                questions[0].id: Answer(type: .yes, text: "Yes"),         // Pizza - everyone agrees
                questions[1].id: Answer(type: .yes, text: "Yes"),         // Swift - everyone agrees
                questions[2].id: Answer(type: .maybe, text: "Maybe"),     // Outdoor - partial agreement
                questions[3].id: Answer(type: .maybe, text: "Maybe"),     // Travel - disagreement
                questions[4].id: Answer(type: .maybe, text: "Both/Neither") // Tea vs Coffee - disagreement
            ]
        )
        
        // Add responses to overlap
        overlap.responses = [
            "Alice": aliceResponses,
            "Bob": bobResponses,
            "Charlie": charlieResponses
        ]
        
        return overlap
    }()
    
    QuestionnaireCompleteView(overlap: sampleOverlapWithResponses)
}
