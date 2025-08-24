//
//  DetailHeader.swift
//  Overlap
//
//  Created by Paul Davis on 8/22/25.
//

import SwiftUI


// Centered header similar to CreateQuestionnaireHeader
public struct DetailHeader: View {
    let questionnaire: Questionnaire

    public var body: some View {
        VStack(spacing: Tokens.Spacing.l) {
            // Circular gradient icon matching CreateQuestionnaireHeader
            QuestionnaireIcon(questionnaire: questionnaire, size: .medium)

            VStack(spacing: Tokens.Spacing.s) {
                Text(questionnaire.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(questionnaire.information)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
    }
}

#Preview {
    DetailHeader(questionnaire: SampleData.sampleQuestionnaire)
        .padding()
        .background(Color(.systemBackground))
}
