//
//  QuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftUI

struct QuestionnaireView: View {
    let overlap: Overlap

    var body: some View {
        ZStack {
            // Show Different Views based on current state
            switch overlap.currentState {
            case .instructions:
                QuestionnaireInstructionsView(overlap: overlap)
            case .nextParticipant:
                QuestionnaireNextParticipantView(overlap: overlap)
            case .answering:
                QuestionnaireAnsweringView(overlap: overlap)
            case .complete:
                QuestionnaireCompleteView(overlap: overlap)
            }

        }
        .navigationTitle(
            overlap.currentState == .answering
                ? overlap.questionnaire.title : ""
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    QuestionnaireView(overlap: SampleData.sampleOverlap)
}
