//
//  DetailInfo.swift
//  Overlap
//
//  Created by Paul Davis on 8/22/25.
//

import SwiftUI

// Information card with metadata
public struct DetailInfo: View {
    let questionnaire: Questionnaire

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Instructions", icon: "text.alignleft")

            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                Text(questionnaire.instructions)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Metadata row similar to QuestionnaireListItem
                HStack(spacing: Tokens.Spacing.m) {
                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(questionnaire.questions.count) questions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)

                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(questionnaire.author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)

                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(
                            questionnaire.creationDate.formatted(
                                date: .abbreviated,
                                time: .omitted
                            )
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .standardGlassCard()
        }
    }
}

#Preview {
    let sample = Questionnaire(
        title: "Sample Questionnaire",
        information: "This is a sample questionnaire for preview.",
        instructions: "Please answer all questions honestly and to the best of your ability.",
        author: "Jane Doe",
        creationDate: Date(timeIntervalSince1970: 1_727_500_000),
        questions: [
            "Do you enjoy programming?",
            "What's your favorite language?",
            "Do you use SwiftUI?"
        ],
        iconEmoji: "📝"
    )
    return DetailInfo(questionnaire: sample)
        .padding()
        .background(Color(.systemBackground))
}
