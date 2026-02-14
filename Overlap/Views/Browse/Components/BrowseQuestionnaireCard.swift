//
//  BrowseQuestionnaireCard.swift
//  Overlap
//
//  Row component for browse catalog questionnaire templates.
//

import SwiftUI

/// Native list row for browse templates (used inside NavigationLink)
struct BrowseQuestionnaireRow: View {
    let template: BrowseQuestionnaire

    var body: some View {
        HStack(spacing: Tokens.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Tokens.Radius.s)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: template.startColorHex).opacity(0.8),
                                Color(hex: template.endColorHex).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: Tokens.Size.iconMedium, height: Tokens.Size.iconMedium)

                Text(template.iconEmoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(template.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: Tokens.Spacing.s) {
                    Label("\(template.questions.count) Qs", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)

                    Text(template.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            BrowseQuestionnaireRow(
                template: BrowseQuestionnaire(
                    id: "preview",
                    title: "Weekend Plans",
                    information: "A quick pulse on preferences.",
                    instructions: "Answer honestly.",
                    author: "Overlap Team",
                    questions: ["Hike?", "Cafe?", "Movie?"],
                    iconEmoji: "🏔️",
                    startColorHex: "#FF6B35",
                    endColorHex: "#004E89",
                    category: "Social"
                )
            )
        }
    }
}
