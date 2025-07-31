//
//  QuestionnaireAnsweringView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

struct QuestionnaireAnsweringView: View {
    let overlap: Overlap
    
    @State private var blobEmphasis: BlobEmphasis = .none
    
    /// The scale of the card for animation
    @State private var cardScale: CGFloat = 0.8
    /// The opacity of the card for animation
    @State private var cardOpacity: Double = 0.0

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: blobEmphasis)
            
            VStack {
                CardView(
                    question: overlap.GetCurrentQuestion(),
                    onSwipe: { answer in
                        print("Selected answer: \(answer)")

                        // Save answer first (this changes the question index)
                        overlap.SaveResponse(answer: answer)
                        
                        // Reset blob emphasis
                        blobEmphasis = .none

                        // Reset card state for next card
                        cardScale = 0.8
                        cardOpacity = 0.0

                        // Animate in the next card with a slight delay to ensure state is updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(
                                .spring(response: 0.6, dampingFraction: 0.8)
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
                .id(overlap.GetCurrentQuestion().id)  // Force SwiftUI to recreate the view
                                .onAppear {
                    // Animate in the first card
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        cardScale = 1.0
                        cardOpacity = 1.0
                    }
                }
                
                // Progress
                QuestionnaireProgress(overlap: overlap)
            }
        }
    }
}

#Preview {
    ZStack {
        BlobBackgroundView()
        QuestionnaireAnsweringView(overlap: SampleData.sampleOverlap)
    }
}
