//
//  DetailQuestions.swift
//  Overlap
//
//  Created by Paul Davis on 8/22/25.
//

import SwiftUI

public struct DetailQuestions: View {
    let questionnaire: Questionnaire
    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Questions", icon: "questionmark.bubble.fill")
            ForEach(Array(questionnaire.questions.enumerated()), id: \.offset) {
                idx,
                q in
                HStack(alignment: .top, spacing: Tokens.Spacing.m) {
                    Text("\(idx + 1).")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, alignment: .trailing)
                    Text(q)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, Tokens.Spacing.m)
                .padding(.horizontal, Tokens.Spacing.m)
                .standardGlassCard()
            }
        }
    }
}

#Preview {
    let sampleQuestions = [
        "What is your favorite color?",
        "Tell us about a memorable experience.",
        "How do you like to spend your weekends?"
    ]
    let sampleQuestionnaire = Questionnaire(
        title: "Sample Questionnaire",
        information: "Some info",
        instructions: "Answer honestly",
        author: "Test User",
        questions: sampleQuestions
    )
    return DetailQuestions(questionnaire: sampleQuestionnaire)
        .padding()
        .background(Color(.systemGroupedBackground))
}
