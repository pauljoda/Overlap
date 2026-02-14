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

    private var displayQuestionNumber: Int {
        guard overlap.totalQuestions > 0 else { return 0 }
        return min(overlap.currentQuestionIndex + 1, overlap.totalQuestions)
    }
    
    var body: some View {
        if overlap.isOnline {
            Text("\(displayQuestionNumber) / \(overlap.totalQuestions)")
        } else {
            HStack {
                Text(overlap.currentParticipant ?? Tokens.Strings.unknown)
                    .bold()
                Text("\(displayQuestionNumber) / \(overlap.totalQuestions)")
                
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
