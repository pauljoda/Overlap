//
//  QuestionEditCard.swift
//  Overlap
//
//  Created by Paul Davis on 8/8/25.
//

import SwiftUI


struct QuestionEditCard: View {
    @Binding var question: String
    let number: Int
    let canRemove: Bool
    let onRemove: () -> Void
    let isNew: Bool
    let onNewAnimationComplete: () -> Void
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?
    let questionIndex: Int
    @State private var appearScale: CGFloat = 1.0
    @State private var appearOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Outer subtle ring similar to the answering card
            RoundedRectangle(cornerRadius: Tokens.Radius.heroCard)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color(.separator).opacity(Tokens.Opacity.light), .clear]),
                        center: .center, startRadius: 0, endRadius: 220
                    )
                )
                .opacity(Tokens.Opacity.medium)
                .scaleEffect(Tokens.Scale.hover)

            // Main card with concentric borders
            RoundedRectangle(cornerRadius: Tokens.Radius.heroCard)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.Radius.heroCard - Tokens.Border.concentricOffset/2)
                        .stroke(Color(.separator).opacity(Tokens.Opacity.strong), lineWidth: Tokens.Border.thin)
                        .padding(Tokens.Border.concentricOffset/2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.Radius.heroCard)
                        .stroke(Color(.separator), lineWidth: Tokens.Border.standard)
                )
                .strongShadow()
                .opacity(Tokens.Opacity.prominent)

            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                HStack {
                    Text("Question \(number)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    if canRemove {
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .accessibilityLabel("Remove question \(number)")
                    }
                }

                Spacer()

                // Centered large editor to resemble answering card text
                TextField("Ask a question", text: $question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .question(questionIndex))
                    .padding(.horizontal, Tokens.Spacing.l)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(Tokens.Spacing.xxl)
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
            .onAppear {
                guard isNew else { return }
                appearScale = 0.95
                appearOpacity = 0
                withAnimation(.spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping)) {
                    appearScale = 1
                    appearOpacity = 1
                }
                // Clear new state after the animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    onNewAnimationComplete()
                }
            }
        }
    }
}

#Preview {
    @State var question = ""
    @FocusState var focusedField: CreateQuestionnaireView.FocusedField?
    
    QuestionEditCard(
        question: $question,
        number: 1,
        canRemove: true,
        onRemove: {},
        isNew: false,
        onNewAnimationComplete: {},
        focusedField: $focusedField,
        questionIndex: 0
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("With Text") {
    @State var question = "This is a question"
    @FocusState var focusedField: CreateQuestionnaireView.FocusedField?
    
    QuestionEditCard(
        question: $question,
        number: 1,
        canRemove: true,
        onRemove: {},
        isNew: false,
        onNewAnimationComplete: {},
        focusedField: $focusedField,
        questionIndex: 0
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
