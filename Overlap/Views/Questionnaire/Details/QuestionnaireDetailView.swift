//
//  QuestionnaireDetailView.swift
//  Overlap
//
//  Shows a saved questionnaire's details with a clean, modular layout.
//

import SwiftData
import SwiftUI

struct QuestionnaireDetailView: View {
    let questionnaire: Questionnaire
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
                        .frame(height: Tokens.Size.buttonLarge + Tokens.Spacing.xl * 2)
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
        navigate(to: overlap, using: navigationPath, replaceCurrent: true)
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
        navigate(to: overlap, using: navigationPath, replaceCurrent: true)
    }

    private func editQuestionnaire() {
        // Navigate to edit mode of the questionnaire
        navigate(
            to: .edit(questionnaireId: questionnaire.id),
            using: navigationPath
        )
    }
}

#Preview {
    let q = Questionnaire(
        title: "Weekend Plans",
        information: "A quick pulse on preferences.",
        instructions: "Answer honestly with yes/no/maybe.",
        author: "Alex",
        questions: ["Hike a trail?", "Try a new cafe?", "See a movie?"],
        startColor: .blue,
        endColor: .purple
    )
    return NavigationStack { QuestionnaireDetailView(questionnaire: q) }
        .modelContainer(for: Questionnaire.self, inMemory: true)
}
