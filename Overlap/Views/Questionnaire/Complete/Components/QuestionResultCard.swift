//
//  QuestionResultCard.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A SwiftUI view that displays the result of a question, showing each participant's response.
/// 
/// The `QuestionResultCard` renders a summary card for a given `question`, listing each participant's answer
/// along with a colored indicator based on their response type (`yes`, `maybe`, or `no`). The card's appearance
/// can be customized with an accent color, and participant answers are visually grouped and styled for clarity.
///
/// - Parameters:
///   - question: The `Question` object containing the text and metadata of the question.
///   - responses: A dictionary mapping participant identifiers to their corresponding `Answer`.
///   - accentColor: The primary color used for card accents and outlines.
/// 
/// This view is intended for use in result or summary screens, where an overview of collected answers
/// is presented in a clear, visually distinct format.
struct QuestionResultCard: View {
    let question: String
    let responses: [String: Answer]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(responses.keys.sorted()), id: \.self) {
                    participant in
                    if let answer = responses[participant] {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colorForAnswer(answer))
                                .frame(width: 12, height: 12)

                            Text(participant)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(answer.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    colorForAnswer(answer)
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    colorForAnswer(answer).opacity(0.2)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(accentColor.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    private func colorForAnswer(_ answer: Answer) -> Color {
        switch answer {
        case .yes:
            return .green
        case .maybe:
            return .orange
        case .no:
            return .red
        }
    }
}


#Preview("Sample Result Card") {
    QuestionResultCard(
        question: "What's your favorite programming language?",
        responses: [
            "Alice": .yes,
            "Bob": .maybe,
            "Charlie": .no,
            "Dana": .yes,
            "Eve": .maybe
        ],
        accentColor: .blue
    )
}
