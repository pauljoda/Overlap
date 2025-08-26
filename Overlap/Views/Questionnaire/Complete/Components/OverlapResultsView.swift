//
//  OverlapResultsView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A comprehensive results view component for displaying overlap analysis
/// 
/// Features:
/// - Automatic analysis of overlap responses
/// - Full and partial agreement sections
/// - Empty state handling
/// - Staggered animations
/// - All analysis logic encapsulated
struct OverlapResultsView: View {
    let overlap: Overlap
    let isAnimated: Bool
    
    // Computed properties for analyzing results
    private var fullAgreementQuestions: [(String, [String: Answer])] {
        overlap.getQuestionsWithResponses().compactMap { question, responses in
            let allYes = responses.values.allSatisfy { $0 == .yes }
            return allYes && !responses.isEmpty ? (question, responses) : nil
        }
    }
    
    private var partialAgreementQuestions: [(String, [String: Answer])] {
        overlap.getQuestionsWithResponses().compactMap { question, responses in
            let hasAtLeastOneMaybe = responses.values.contains { $0 == .maybe }
            let hasNoNo = !responses.values.contains { $0 == .no }
            let notAllYes = !responses.values.allSatisfy { $0 == .yes }
            
            return hasAtLeastOneMaybe && hasNoNo && notAllYes && !responses.isEmpty ? (question, responses) : nil
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Full Agreement Section
            if !fullAgreementQuestions.isEmpty {
                ResultsSection(
                    title: "Perfect Agreement",
                    subtitle: "Everyone said yes to these questions",
                    icon: "hands.clap.fill",
                    accentColor: .green,
                    questions: fullAgreementQuestions,
                    isAnimated: isAnimated,
                    animationDelay: 0.8,
                    cardAnimationDelay: 1.0
                )
            }
            
            // Partial Agreement Section
            if !partialAgreementQuestions.isEmpty {
                ResultsSection(
                    title: "Possible Agreement",
                    subtitle: "Some maybes, but no disagreements",
                    icon: "hand.thumbsup.fill",
                    accentColor: .orange,
                    questions: partialAgreementQuestions,
                    isAnimated: isAnimated,
                    animationDelay: 1.2 + Double(fullAgreementQuestions.count) * 0.15,
                    cardAnimationDelay: 1.4 + Double(fullAgreementQuestions.count) * 0.15
                )
            }
            
            // Empty State
            if fullAgreementQuestions.isEmpty && partialAgreementQuestions.isEmpty {
                EmptyResultsState(
                    isAnimated: isAnimated,
                    animationDelay: 0.8
                )
            }
        }
    }
}

#Preview {
    // Create a sample overlap with completed responses for visualization
    let sampleOverlapWithResponses: Overlap = {
        var overlap = Overlap(
            participants: ["Alice", "Bob", "Charlie", "Diana"],
            questionnaire: SampleData.sampleQuestionnaire,
            currentState: .complete
        )
        
        // Initialize the session with participants
        overlap.setParticipants(["Alice", "Bob", "Charlie", "Diana"])
        
        // Simulate saving responses for each participant
        let responsePatterns = [
            [Answer.yes, .yes, .maybe, .no, .yes],      // Alice
            [Answer.yes, .yes, .yes, .yes, .no],        // Bob  
            [Answer.yes, .yes, .maybe, .maybe, .maybe], // Charlie
            [Answer.yes, .yes, .maybe, .yes, .yes]      // Diana
        ]
        
        // Reset session and manually set responses for preview
        overlap.resetSession()
        for (participantIndex, pattern) in responsePatterns.enumerated() {
            let participant = overlap.participants[participantIndex]
            for (questionIndex, answer) in pattern.enumerated() {
                // Directly set the answer for preview purposes
                _ = overlap.saveResponse(answer: answer)
            }
        }
        
        return overlap
    }()
    
    ScrollView {
        VStack {
            Text("Results Preview")
                .font(.title)
                .padding()
            
            OverlapResultsView(overlap: sampleOverlapWithResponses, isAnimated: true)
        }
        .padding()
    }
}
