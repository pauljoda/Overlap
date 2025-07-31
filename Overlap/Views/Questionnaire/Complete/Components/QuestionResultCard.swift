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
    let question: Question
    let responses: [String: Answer]
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.text)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(responses.keys.sorted()), id: \.self) {
                    participant in
                    if let answer = responses[participant] {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colorForAnswerType(answer.type))
                                .frame(width: 12, height: 12)

                            Text(participant)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()

                            Text(answer.text)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    colorForAnswerType(answer.type)
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    colorForAnswerType(answer.type).opacity(0.2)
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
    private func colorForAnswerType(_ type: AnswerType) -> Color {
        switch type {
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
        question: Question(
            text: "What's your favorite programming language?"
        ),
        responses: [
            "Alice": Answer(type: .yes, text: "Swift"),
            "Bob": Answer(type: .maybe, text: "Python"),
            "Charlie": Answer(type: .no, text: "Java"),
            "Dana": Answer(type: .yes, text: "Kotlin"),
            "Eve": Answer(type: .maybe, text: "Go")
        ],
        accentColor: .blue
    )
}
