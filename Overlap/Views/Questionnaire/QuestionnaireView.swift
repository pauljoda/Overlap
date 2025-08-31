//
//  QuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftUI
import SharingGRDB

struct QuestionnaireView: View {
    @State private var overlap: Overlap
    @Dependency(\.defaultDatabase) var database
    @StateObject private var userPreferences = UserPreferences.shared

    init(overlap: Overlap) {
        self._overlap = State(initialValue: overlap)
    }

    var body: some View {
        ZStack {
            // Show Different Views based on current state
            switch overlap.currentState {
            case .instructions:
                QuestionnaireInstructionsView(overlap: $overlap)
            case .nextParticipant:
                QuestionnaireNextParticipantView(overlap: $overlap)
            case .answering:
                QuestionnaireAnsweringView(overlap: $overlap)
            case .awaitingResponses:
                // For online overlaps, if the local user has not completed, allow answering.
                if shouldOfferLocalAnswering() {
                    QuestionnaireAnsweringView(overlap: $overlap)
                        .onAppear { ensureCurrentParticipantIsLocalUser() }
                } else {
                    QuestionnaireAwaitingResponsesView(overlap: $overlap)
                }
            case .complete:
                QuestionnaireCompleteView(overlap: $overlap)
            }

        }
        .navigationTitle(
            overlap.currentState == .answering
                ? overlap.title : ""
        )
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: overlap) {
            // Persist every state/data change to keep DB and UI in sync
            _ = overlap.updateOrInsert(database: database)
        }
    }

    private func shouldOfferLocalAnswering() -> Bool {
        guard overlap.isOnline else { return false }
        guard let name = userPreferences.userDisplayName,
              overlap.participants.contains(name) else { return false }
        return !overlap.isParticipantComplete(name)
    }

    private func ensureCurrentParticipantIsLocalUser() {
        if let name = userPreferences.userDisplayName,
           let idx = overlap.participants.firstIndex(of: name) {
            if overlap.currentParticipantIndex != idx {
                print("[Overlap] Switching currentParticipantIndex to local user: \(name) @ index \(idx)")
                overlap.currentParticipantIndex = idx
            }
            return
        }
        // Fallback: pick the first incomplete participant
        if let idx = overlap.participants.firstIndex(where: { !overlap.isParticipantComplete($0) }) {
            if overlap.currentParticipantIndex != idx {
                print("[Overlap] Switching currentParticipantIndex to first incomplete participant @ index \(idx)")
                overlap.currentParticipantIndex = idx
            }
        }
    }
}

#Preview("Instructions") {
    QuestionnaireView(overlap: SampleData.instructionsOverlap)
}

#Preview("Answering - Offline") {
    QuestionnaireView(overlap: SampleData.midProgressOverlap)
}

#Preview("Answering - Online") {
    QuestionnaireView(overlap: SampleData.onlineCollaborativeOverlap)
}

#Preview("Next Participant") {
    QuestionnaireView(overlap: SampleData.nextParticipantOverlap)
}

#Preview("Awaiting Responses") {
    QuestionnaireView(overlap: SampleData.awaitingResponsesOverlap)
}

#Preview("Awaiting Responses (Partial)") {
    QuestionnaireView(overlap: SampleData.awaitingResponsesPartialOverlap)
}

#Preview("Complete") {
    QuestionnaireView(overlap: SampleData.recentlyCompletedOverlap)
}

#Preview("Complete - Randomized") {
    QuestionnaireView(overlap: SampleData.completedRandomizedOverlap)
}
