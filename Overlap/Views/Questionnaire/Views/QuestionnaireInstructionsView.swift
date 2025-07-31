//
//  QuestionnaireInstructionsView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

struct QuestionnaireInstructionsView: View {
    let overlap: Overlap
    @State private var newParticipantName = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var animatingParticipants: Set<Int> = []

    private var canBegin: Bool {
        overlap.participants.count >= 2
    }

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: .none)

            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
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

                        // Bottom padding to ensure content doesn't get hidden behind button
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 100)
                    }
                }

                // Begin Button - Fixed at bottom
                VStack {
                    GlassActionButton(
                        title: "Begin Overlap",
                        icon: "play.fill",
                        isEnabled: canBegin,
                        tintColor: .green,
                        action: beginQuestionnaire
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
            withAnimation(.easeInOut(duration: 0.3)) {
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
            
            // Update animation state for participants that will shift down
            let participantsToUpdate = animatingParticipants.filter { $0 > index }
            for participantIndex in participantsToUpdate {
                animatingParticipants.remove(participantIndex)
                animatingParticipants.insert(participantIndex - 1)
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                overlap.participants.remove(at: index)
            }
        }
    }

    private func beginQuestionnaire() {
        guard canBegin else { return }
        overlap.currentState = .nextParticipant
        if !overlap.participants.isEmpty {
            overlap.currentParticipant = overlap.participants[0]
        }
        overlap.currentQuestionIndex = 0
    }
}

#Preview {
    QuestionnaireInstructionsView(overlap: SampleData.sampleOverlap)
}
