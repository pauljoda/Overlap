//
//  QuestionnaireNextParticipantView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireNextParticipantView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @State private var isAnimated = false

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: .none)

            // Scrollable Content - Full screen
            ScrollView {
                VStack(spacing: Tokens.Spacing.tripleXL) {
                    // Main Participant Section
                    VStack(spacing: Tokens.Spacing.xl) {
                        AnimatedParticipantDisplay(
                            overlap: overlap,
                            isAnimated: isAnimated
                        )

                        // Hand-off Instructions Card
                        InstructionCard(
                            icon: "hand.point.right.fill",
                            text: "Pass to the next participant",
                            isAnimated: isAnimated,
                            animationDelay: 0.4
                        )
                    }
                    .padding(.horizontal, Tokens.Spacing.xl)
                    .padding(.top, Tokens.Spacing.quadXL)

                    // Questionnaire Instructions Section
                    QuestionnaireInstructionsSection(
                        overlap: overlap,
                        isAnimated: isAnimated,
                        animationDelay: 0.6
                    )
                    .padding(.horizontal, Tokens.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isAnimated ? 1 : 0)
                    .animation(
                        .easeIn(duration: Tokens.Duration.slow).delay(Tokens.Duration.medium),
                        value: isAnimated
                    )

                    // Bottom spacing to account for floating button
                    Spacer()
                        .frame(height: Tokens.Size.buttonLarge + Tokens.Spacing.xl * 2)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Floating Begin Button - overlayed at bottom
            VStack {
                Spacer()
                
                GlassActionButton(
                    title: "Begin Questions",
                    icon: "play.fill",
                    isEnabled: true,
                    tintColor: .green,
                    action: beginAnswering
                )
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : Tokens.Size.buttonStandard)
                .animation(
                    .spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping).delay(Tokens.Spring.response),
                    value: isAnimated
                )
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .onAppear {
            isAnimated = true
        }
    }

    private func beginAnswering() {
        overlap.currentState = .answering
        
        // Save state change to model context
        try? modelContext.save()
        
        // The session automatically handles question index management
    }
}

#Preview {
    QuestionnaireNextParticipantView(overlap: SampleData.sampleOverlap)
}
