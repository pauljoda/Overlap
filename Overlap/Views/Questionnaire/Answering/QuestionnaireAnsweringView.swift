//
//  QuestionnaireAnsweringView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SharingGRDB
import SwiftUI

struct QuestionnaireAnsweringView: View {
    @Dependency(\.defaultDatabase) var database

    @Binding var overlap: Overlap

    @State private var blobEmphasis: BlobEmphasis = .none

    /// The scale of the card for animation
    @State private var cardScale: CGFloat = 0.8
    /// The opacity of the card for animation
    @State private var cardOpacity: Double = 0.0

    var body: some View {
        GlassScreen(scrollable: false, emphasis: blobEmphasis) {
            VStack(spacing: Tokens.Spacing.xs) {
                if let currentQuestion = overlap.currentQuestion {
                    CardView(
                        question: currentQuestion,
                        onSwipe: { answer in
                            print("Selected answer: \(answer)")

                            // Save answer (this changes the question index)
                            let saveSuccessful = overlap.saveResponse(
                                answer: answer
                            )

                            // Reset blob emphasis
                            blobEmphasis = .none

                            // Reset card state for next card
                            cardScale = 0.8
                            cardOpacity = 0.0

                            // Animate in the next card with a slight delay to ensure state is updated
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + Tokens.Delay.short
                            ) {
                                withAnimation(
                                    .spring(
                                        response: Tokens.Spring.response,
                                        dampingFraction: Tokens.Spring.damping
                                    )
                                ) {
                                    cardScale = 1.0
                                    cardOpacity = 1.0
                                }
                            }
                        },
                        onEmphasisChange: { emphasis in
                            blobEmphasis = emphasis
                        }
                    )
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .id(currentQuestion)  // Force SwiftUI to recreate the view
                    .onAppear {
                        // Animate in the first card
                        withAnimation(
                            .spring(
                                response: Tokens.Spring.response,
                                dampingFraction: Tokens.Spring.damping
                            )
                        ) {
                            cardScale = 1.0
                            cardOpacity = 1.0
                        }
                    }
                } else {
                    Text(Tokens.Strings.noMoreQuestions)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                // Progress
                QuestionnaireProgress(overlap: overlap)
                    .padding(.top, Tokens.Spacing.m)
                    .padding(.bottom, Tokens.Spacing.xl)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
        }
    }
}

#Preview("Offline") {
    let _ = setupGRDBPreview()
    ZStack {
        BlobBackgroundView()
        QuestionnaireAnsweringView(
            overlap: .constant(SampleData.midProgressOverlap)
        )
    }
}

#Preview("Online") {
    let _ = setupGRDBPreview()
    ZStack {
        BlobBackgroundView()
        QuestionnaireAnsweringView(
            overlap: .constant(SampleData.onlineCollaborativeOverlap)
        )
    }
}
