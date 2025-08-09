//
//  QuestionnaireInstructionsView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireInstructionsView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @State private var newParticipantName = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var animatingParticipants: Set<Int> = []

    private var canBegin: Bool {
        overlap.participants.count >= 2
    }

    var body: some View {
        ZStack {
            GlassScreen {
                ScrollView {
                    VStack(spacing: Tokens.Spacing.xxl) {
                        // Header Section
                        QuestionnaireHeader(overlap: overlap)

                        // Participants Section
                        if !overlap.isOnline {
                            ParticipantsSection(
                                overlap: overlap,
                                newParticipantName: $newParticipantName,
                                isTextFieldFocused: $isTextFieldFocused,
                                animatingParticipants: $animatingParticipants,
                                onAddParticipant: addParticipant,
                                onRemoveParticipant: removeParticipant
                            )
                        }

                        // Bottom padding to account for floating button
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: Tokens.Size.iconHuge)
                    }
                    .padding(.top, Tokens.Spacing.xl)
                }
            }

            // Floating Begin Button - overlayed at bottom
            VStack {
                Spacer()
                
                GlassActionButton(
                    title: "Begin Overlap",
                    icon: "play.fill",
                    isEnabled: canBegin,
                    tintColor: .green,
                    action: beginQuestionnaire
                )
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    private func addParticipant() {
        let trimmedName = newParticipantName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty,
            !overlap.participants.contains(trimmedName)
        else {
            return
        }

        let newIndex = overlap.participants.count
        overlap.participants.append(trimmedName)
        newParticipantName = ""
        isTextFieldFocused = false

        // Start animation for the new participant
        animatingParticipants.insert(newIndex)

        // After a brief delay, expand the participant row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: Tokens.Duration.fast)) {
                _ = animatingParticipants.remove(newIndex)
            }
        }
    }

    private func removeParticipant(at index: Int) {
        guard index < overlap.participants.count else { return }

        // Start removal animation - shrink to circle first
        animatingParticipants.insert(index)

        // After animation completes, remove the participant
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Clean up animation state for the removed participant
            animatingParticipants.remove(index)

            // Clear any animation states for participants with indices greater than the removed one
            // This prevents the shifting participants from being animated
            let participantsToCleanup = animatingParticipants.filter {
                $0 > index
            }
            for participantIndex in participantsToCleanup {
                animatingParticipants.remove(participantIndex)
            }

            withAnimation(.easeInOut(duration: Tokens.Duration.fast)) {
                overlap.participants.remove(at: index)
            }
        }
    }

    private func beginQuestionnaire() {
        guard canBegin else { return }

        // Initialize responses for all current participants
        overlap.initializeResponses()

        overlap.currentState = .nextParticipant
        
        // Save the overlap to the model context when starting
        modelContext.insert(overlap)
        try? modelContext.save()
        
        // The session automatically handles participant and question index management
    }
}

#Preview {
    QuestionnaireInstructionsView(overlap: SampleData.sampleOverlap)
}
