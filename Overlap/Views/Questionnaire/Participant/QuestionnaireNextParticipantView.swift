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
                VStack(spacing: 32) {
                    // Main Participant Section
                    VStack(spacing: 20) {
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
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                    // Questionnaire Instructions Section
                    QuestionnaireInstructionsSection(
                        overlap: overlap,
                        isAnimated: isAnimated,
                        animationDelay: 0.6
                    )
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isAnimated ? 1 : 0)
                    .animation(
                        .easeIn(duration: 0.7).delay(0.6),
                        value: isAnimated
                    )

                    // Bottom padding to account for floating button
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 120)
                }
            }

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
                .offset(y: isAnimated ? 0 : 50)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.8).delay(0.8),
                    value: isAnimated
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
