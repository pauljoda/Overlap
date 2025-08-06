//
//  QuestionnaireProgress.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable progress indicator component for questionnaires
/// 
/// Features:
/// - Shows current question progress from Overlap
/// - Automatic participant name display for offline mode
/// - Consistent styling across questionnaire views
struct QuestionnaireProgress: View {
    let overlap: Overlap
    
    var body: some View {
        if overlap.isOnline {
            Text("\(overlap.currentQuestionIndex + 1) / \(overlap.totalQuestions)")
        } else {
            HStack {
                Text(overlap.getCurrentParticipant() ?? "Unknown")
                    .bold()
                Text("\(overlap.currentQuestionIndex + 1) / \(overlap.totalQuestions)")
                
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        QuestionnaireProgress(overlap: SampleData.sampleOverlap)
        
//        QuestionnaireProgress(overlap: {
//            let onlineOverlap = SampleData.sampleOverlap
//            onlineOverlap.isOnline = true
//            return onlineOverlap
//        }())
    }
    .padding()
}
