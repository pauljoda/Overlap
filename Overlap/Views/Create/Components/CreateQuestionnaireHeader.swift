//
//  CreateQuestionnaireHeader.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct CreateQuestionnaireHeader: View {
    let questionnaire: QuestionnaireTable
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.l) {
            // Circular gradient icon
            QuestionnaireIcon(questionnaire: questionnaire, size: .medium)
            
            VStack(spacing: Tokens.Spacing.s) {
                Text("Create New Questionnaire")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Design questions to discover where opinions overlap")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    CreateQuestionnaireHeader(questionnaire: QuestionnaireTable())
        .padding()
}
