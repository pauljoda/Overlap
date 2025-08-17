//
//  QuestionnaireAnsweringView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireAnsweringView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @Environment(\.overlapSyncManager) private var syncManager
    
    @State private var blobEmphasis: BlobEmphasis = .none
    
    /// The scale of the card for animation
    @State private var cardScale: CGFloat = 0.8
    /// The opacity of the card for animation
    @State private var cardOpacity: Double = 0.0

    var body: some View {
        GlassScreen(scrollable: false, emphasis: blobEmphasis) {
            VStack(spacing: Tokens.Spacing.xs) {
                if let currentQuestion = overlap.getCurrentQuestion() {
                    CardView(
                        question: currentQuestion,
                        onSwipe: { answer in
                            print("Selected answer: \(answer)")

                            // Save answer first (this changes the question index)
                            let wasCompleted = overlap.isCompleted
                            let previousState = overlap.currentState
                            overlap.saveResponse(answer: answer)
                            
                            // Save changes to model context
                            try? modelContext.save()
                            
                            // Sync to CloudKit if this is an online overlap and participant completed their portion
                            if overlap.isOnline && !wasCompleted && 
                               (overlap.currentState == .nextParticipant || overlap.currentState == .complete) &&
                               previousState == .answering {
                                Task {
                                    await syncParticipantCompletion()
                                }
                            }
                            
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
                    .id(currentQuestion)  // Force SwiftUI to recreate the view
                    .onAppear {
                        // Animate in the first card
                        withAnimation(.spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping)) {
                            cardScale = 1.0
                            cardOpacity = 1.0
                        }
                    }
                } else {
                    Text("No more questions")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Progress
                QuestionnaireProgress(overlap: overlap)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Sync Functions
    
    private func syncParticipantCompletion() async {
        guard let syncManager = syncManager else { return }
        
        do {
            try await syncManager.syncOverlapCompletion(overlap)
            print("Successfully synced participant completion")
        } catch {
            print("Failed to sync participant completion: \(error)")
        }
    }
}


#Preview {
    ZStack {
        BlobBackgroundView()
        QuestionnaireAnsweringView(overlap: SampleData.sampleOverlap)
    }
}
