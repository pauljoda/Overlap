//
//  BrowseDetailView.swift
//  Overlap
//
//  Detail page for a browse catalog template, modeled after QuestionnaireDetailView.
//

import SwiftUI
import SwiftData

struct BrowseDetailView: View {
    let template: BrowseQuestionnaire
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath

    var body: some View {
        ZStack {
            GlassScreen {
                VStack(spacing: Tokens.Spacing.xxl) {
                    // Header
                    VStack(spacing: Tokens.Spacing.l) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: template.startColorHex),
                                            Color(hex: template.endColorHex)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: Tokens.Size.iconXL, height: Tokens.Size.iconXL)

                            Text(template.iconEmoji)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }

                        VStack(spacing: Tokens.Spacing.s) {
                            Text(template.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text(template.information)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                    }

                    // Instructions card
                    VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                        SectionHeader(title: "Instructions", icon: "text.alignleft")

                        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                            Text(template.instructions)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: Tokens.Spacing.m) {
                                HStack(spacing: Tokens.Spacing.xs) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(template.questions.count) questions")
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
                                    Text(template.author)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Circle()
                                    .fill(Color.secondary)
                                    .frame(width: 2, height: 2)

                                Text(template.category)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: template.startColorHex))
                                    .padding(.horizontal, Tokens.Spacing.s)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: template.startColorHex).opacity(0.12))
                                    .clipShape(Capsule())

                                Spacer()
                            }
                        }
                        .padding()
                        .standardGlassCard()
                    }

                    // Questions list
                    VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                        SectionHeader(title: "Questions", icon: "questionmark.bubble.fill")

                        ForEach(Array(template.questions.enumerated()), id: \.offset) { idx, q in
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

                    // Bottom spacing for floating button
                    Spacer()
                        .frame(height: Tokens.Size.buttonLarge + Tokens.Spacing.xl * 3)
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.xl)
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Floating "Use Template" button
            VStack {
                Spacer()

                GlassActionButton(
                    title: "Use Template",
                    icon: "square.and.arrow.down",
                    isEnabled: true,
                    tintColor: Color(hex: template.startColorHex),
                    action: useTemplate
                )
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .navigationTitle(template.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func useTemplate() {
        // Save as a local questionnaire
        let questionnaire = Questionnaire(
            title: template.title,
            information: template.information,
            instructions: template.instructions,
            questions: template.questions,
            iconEmoji: template.iconEmoji,
            startColor: Color(hex: template.startColorHex),
            endColor: Color(hex: template.endColorHex)
        )
        modelContext.insert(questionnaire)
        try? modelContext.save()

        // Pop browse stack and navigate to the saved entry's detail view
        // Pop back to home, then push saved, then push the questionnaire
        navigationPath.wrappedValue = NavigationPath()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigationPath.wrappedValue.append("saved")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationPath.wrappedValue.append(questionnaire)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BrowseDetailView(
            template: BrowseQuestionnaire(
                id: "preview",
                title: "Weekend Plans",
                information: "A quick pulse on weekend preferences.",
                instructions: "Answer honestly with yes/no/maybe.",
                author: "Overlap Team",
                questions: ["Hike a trail?", "Try a new cafe?", "See a movie?", "Cook dinner?"],
                iconEmoji: "🏔️",
                startColorHex: "#FF6B35",
                endColorHex: "#004E89",
                category: "Social"
            )
        )
    }
    .modelContainer(for: Questionnaire.self, inMemory: true)
}
