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
        overlap.questionnaire.questions.compactMap { question in
            let responses = getResponsesForQuestion(question)
            let allYes = responses.values.allSatisfy { $0 == .yes }
            return allYes && !responses.isEmpty ? (question, responses) : nil
        }
    }
    
    private var partialAgreementQuestions: [(String, [String: Answer])] {
        overlap.questionnaire.questions.compactMap { question in
            let responses = getResponsesForQuestion(question)
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
    
    private func getResponsesForQuestion(_ questionId: String) -> [String: Answer] {
        var questionResponses: [String: Answer] = [:]
        
        for (participant, responses) in overlap.responses {
            if let answer = responses.answers[questionId] {
                questionResponses[participant] = answer
            }
        }
        
        return questionResponses
    }
}

#Preview {
    // Create a sample overlap with completed responses for visualization
    let sampleOverlapWithResponses: Overlap = {
        let overlap = Overlap(
            participants: ["Alice", "Bob", "Charlie", "Diana"],
            questionnaire: SampleData.sampleQuestionnaire,
            currentState: .complete
        )
        
        // Get question IDs from sample questions
        let questions = SampleData.sampleQuestions
        
        // Create responses for Alice
        let aliceResponses = Responses(
            user: "Alice",
            answers: [
                questions[0]: .yes,               // Pizza - full agreement
                questions[1]: .yes,               // Swift - full agreement
                questions[2]: .maybe,             // Outdoor - partial agreement
                questions[3]: .no,                // Travel - disagreement
                questions[4]: .yes                // Coffee vs Tea - disagreement
            ]
        )
        
        // Create responses for Bob
        let bobResponses = Responses(
            user: "Bob",
            answers: [
                questions[0]: .yes,               // Pizza - full agreement
                questions[1]: .yes,               // Swift - full agreement
                questions[2]: .yes,               // Outdoor - partial agreement
                questions[3]: .yes,               // Travel - disagreement
                questions[4]: .no                 // Coffee vs Tea - disagreement
            ]
        )
        
        // Create responses for Charlie
        let charlieResponses = Responses(
            user: "Charlie",
            answers: [
                questions[0]: .yes,               // Pizza - full agreement
                questions[1]: .yes,               // Swift - full agreement
                questions[2]: .maybe,             // Outdoor - partial agreement
                questions[3]: .maybe,             // Travel - disagreement
                questions[4]: .maybe              // Coffee vs Tea - disagreement
            ]
        )
        
        // Create responses for Diana
        let dianaResponses = Responses(
            user: "Diana",
            answers: [
                questions[0]: .yes,               // Pizza - full agreement
                questions[1]: .yes,               // Swift - full agreement
                questions[2]: .maybe,             // Outdoor - partial agreement
                questions[3]: .yes,               // Travel - disagreement
                questions[4]: .yes                // Coffee vs Tea - disagreement
            ]
        )
        
        // Add responses to overlap
        overlap.responses = [
            "Alice": aliceResponses,
            "Bob": bobResponses,
            "Charlie": charlieResponses,
            "Diana": dianaResponses
        ]
        
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
