//
//  ParticipantsSection.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A complete participants management section component
/// 
/// Features:
/// - Participant input field
/// - Participants list with animations
/// - Empty state handling
/// - Count warnings
/// - All participant management logic encapsulated
struct ParticipantsSection: View {
    let overlap: Overlap
    @Binding var newParticipantName: String
    @FocusState.Binding var isTextFieldFocused: Bool
    @Binding var animatingParticipants: Set<Int>
    
    let minimumParticipants: Int
    let onAddParticipant: () -> Void
    let onRemoveParticipant: (Int) -> Void
    
    init(
        overlap: Overlap,
        newParticipantName: Binding<String>,
        isTextFieldFocused: FocusState<Bool>.Binding,
        animatingParticipants: Binding<Set<Int>>,
        minimumParticipants: Int = 2,
        onAddParticipant: @escaping () -> Void,
        onRemoveParticipant: @escaping (Int) -> Void
    ) {
        self.overlap = overlap
        self._newParticipantName = newParticipantName
        self._isTextFieldFocused = isTextFieldFocused
        self._animatingParticipants = animatingParticipants
        self.minimumParticipants = minimumParticipants
        self.onAddParticipant = onAddParticipant
        self.onRemoveParticipant = onRemoveParticipant
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            // Header
            HStack {
                Text("Participants")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(overlap.participants.count) of ∞")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Input Field
            ParticipantInputField(
                text: $newParticipantName,
                isFocused: $isTextFieldFocused,
                placeholder: "Enter participant name",
                onSubmit: onAddParticipant
            )

            // Participants List or Empty State
            if !overlap.participants.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(overlap.participants.enumerated()), id: \.offset) { index, participant in
                        let isAnimating = animatingParticipants.contains(index)
                        
                        ParticipantListItem(
                            participant: participant,
                            index: index,
                            isAnimating: isAnimating
                        ) {
                            onRemoveParticipant(index)
                        }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            } else {
                EmptyParticipantsState(minimumParticipants: minimumParticipants)
            }

            // Warning for insufficient participants
            if overlap.participants.count > 0 && overlap.participants.count < minimumParticipants {
                ParticipantCountWarning(
                    currentCount: overlap.participants.count,
                    requiredCount: minimumParticipants
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    @Previewable @State var animating: Set<Int> = []
    @Previewable @State var newName = ""
    @FocusState var isFocused: Bool
    
    return ParticipantsSection(
        overlap: SampleData.sampleOverlap,
        newParticipantName: $newName,
        isTextFieldFocused: $isFocused,
        animatingParticipants: $animating,
        onAddParticipant: {
            print("Add participant: \(newName)")
            newName = ""
        },
        onRemoveParticipant: { index in
            print("Remove participant at index: \(index)")
        }
    )
    .padding()
}
