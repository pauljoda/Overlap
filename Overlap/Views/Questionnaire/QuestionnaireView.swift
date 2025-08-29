//
//  QuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftUI

struct QuestionnaireView: View {
    @State private var overlap: Overlap

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
                QuestionnaireAwaitingResponsesView(overlap: overlap)
            case .complete:
                QuestionnaireCompleteView(overlap: $overlap)
            }

        }
        .navigationTitle(
            overlap.currentState == .answering
                ? overlap.title : ""
        )
        .navigationBarTitleDisplayMode(.inline)
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
