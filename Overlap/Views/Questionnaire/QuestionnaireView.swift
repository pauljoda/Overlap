//
//  QuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftUI

struct QuestionnaireView: View {
    let overlap: Overlap

    // Which blob should we make larger
    @State private var blobEmphasis: BlobEmphasis = .none
    // Current Question index
    @State private var currentQuestionIndex: Int = 0
    /// The scale of the card for animation
    @State private var cardScale: CGFloat = 0.8
    /// The opacity of the card for animation
    @State private var cardOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Setup background
            BlobBackgroundView(emphasis: blobEmphasis)

            // Cards
            if currentQuestionIndex < overlap.questionnaire.questions.count {
                CardView(
                    question: overlap.questionnaire.questions[
                        currentQuestionIndex
                    ],
                    onSwipe: { answer in
                        print("Selected answer: \(answer)")

                        // Save answer with selected
                        // Ensure the answers array is large enough
                        while overlap.answers.count <= currentQuestionIndex {
                            overlap.answers.append(
                                Answer(type: .no, text: "No")
                            )
                        }
                        overlap.answers[currentQuestionIndex] = answer

                        // Increment the question index
                        currentQuestionIndex += 1

                        // Reset animation state for next card
                        if currentQuestionIndex
                            < overlap.questionnaire.questions.count
                        {
                            cardScale = 0.8
                            cardOpacity = 0.0
                            // Reset blob emphasis
                            blobEmphasis = .none

                            // Animate in the next card
                            withAnimation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                            ) {
                                cardScale = 1.0
                                cardOpacity = 1.0
                            }
                        } else {
                            // All questions answered - save results and complete
                            //saveResultsAndComplete()
                        }
                    },
                    onEmphasisChange: { emphasis in
                        blobEmphasis = emphasis
                    }
                )
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .id(overlap.questionnaire.questions[currentQuestionIndex].id)  // Force SwiftUI to recreate the view
                .onAppear {
                    // Animate in the first card
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8))
                    {
                        cardScale = 1.0
                        cardOpacity = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    QuestionnaireView(overlap: SampleData.sampleOverlap)
}
