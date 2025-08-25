//
//  QuestionnaireDetailView.swift
//  Overlap
//
//  Shows a saved questionnaire's details with a clean, modular layout.
//

import SwiftData
import SwiftUI

struct QuestionnaireDetailView: View {
    let questionnaire: QuestionnaireTable
    @Environment(\.navigationPath) private var navigationPath
    @StateObject private var userPreferences = UserPreferences.shared

    var body: some View {
        ZStack {
            // Scrollable content area
            GlassScreen {
                VStack(spacing: Tokens.Spacing.xxl) {
                    DetailHeader(questionnaire: questionnaire)
                    DetailInfo(questionnaire: questionnaire)
                    DetailQuestions(questionnaire: questionnaire)

                    // Bottom spacing to account for floating button
                    Spacer()
                        .frame(
                            height: Tokens.Size.buttonLarge + Tokens.Spacing.xl
                                * 2
                        )
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.xl)
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Floating bottom buttons
            VStack(spacing: Tokens.Spacing.m) {
                Spacer()

                // Local overlap button
                GlassActionButton(
                    title: Tokens.Strings.beginLocalOverlap,
                    icon: "play.fill",
                    isEnabled: true,
                    tintColor: .green,
                    action: startLocal
                )

                // Online overlap button
                GlassActionButton(
                    title: Tokens.Strings.startOnlineOverlap,
                    icon: "icloud.fill",
                    isEnabled: true,
                    tintColor: .blue,
                    action: startOnline
                )
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .navigationTitle(questionnaire.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    editQuestionnaire()
                }
            }
        }
    }

    private func startLocal() {
        // Create a new Overlap from the questionnaire for local play
        let overlap = Overlap(
            questionnaire: questionnaire,
            randomizeQuestions: false
        )
        navigate(to: overlap, using: navigationPath)
    }

    private func startOnline() {
        // Create a new Overlap from the questionnaire for online collaboration
        // Add the current user as the first participant
        let currentUser = userPreferences.userDisplayName ?? "You"
        let overlap = Overlap(
            participants: [currentUser],
            isOnline: true,
            questionnaire: questionnaire,
            randomizeQuestions: false
        )
        navigate(to: overlap, using: navigationPath)
    }

    private func editQuestionnaire() {
        // Navigate to edit mode of the questionnaire
        navigate(
            to: .edit(questionnaireId: questionnaire.id),
            using: navigationPath
        )
    }
}

// Centered header similar to CreateQuestionnaireHeader
private struct DetailHeader: View {
    let questionnaire: QuestionnaireTable

    var body: some View {
        VStack(spacing: Tokens.Spacing.l) {
            // Circular gradient icon matching CreateQuestionnaireHeader
            QuestionnaireIcon(questionnaire: questionnaire, size: .medium)

            VStack(spacing: Tokens.Spacing.s) {
                Text(questionnaire.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(questionnaire.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
    }
}

// Information card with metadata
private struct DetailInfo: View {
    let questionnaire: QuestionnaireTable

    var body: some View {
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

private struct DetailQuestions: View {
    let questionnaire: QuestionnaireTable
    var body: some View {
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
    let q = QuestionnaireTable(
        title: "Weekend Plans",
        description: "A quick pulse on preferences.",
        instructions: "Answer honestly with yes/no/maybe.",
        author: "Alex",
        questions: ["Hike a trail?", "Try a new cafe?", "See a movie?"]
    )

    NavigationStack { QuestionnaireDetailView(questionnaire: q) }
}
