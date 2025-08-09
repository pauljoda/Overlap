//
//  QuestionListEditor.swift
//  Overlap
//
//  A simple list-based question editor with swipe-to-delete and inline editing.
//

import SwiftUI

struct QuestionListEditor: View {
    @Binding var questions: [String]
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            HStack {
                Spacer()
                Button(action: addQuestion) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .contentShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .actionGlassButton(tint: .blue)
                .accessibilityLabel("Add Question")
            }

            List {
                ForEach(questions.indices, id: \.self) { index in
                    HStack(spacing: Tokens.Spacing.m) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                        TextField(
                            "Enter your question",
                            text: $questions[index],
                            axis: .vertical
                        )
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(1...3)
                        .submitLabel(index == questions.count - 1 ? .done : .next)
                        .focused($focusedField, equals: .question(index))
                        .onSubmit {
                            if index == questions.count - 1 {
                                // On last question, add a new one and focus it
                                addQuestion()
                            } else {
                                // Move to next question
                                focusedField = .question(index + 1)
                            }
                        }
                    }
                    .padding(.vertical, Tokens.Spacing.m)
                    .padding(.horizontal, Tokens.Spacing.m)
                    .standardGlassCard()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: delete)
                .listRowInsets(
                    EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 25)
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            // Keep a small cushion so the last row isn't obscured by the home indicator/keyboard
            .padding(.bottom, Tokens.Spacing.xl)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func addQuestion() {
        questions.append("")
        // Set focus immediately to prevent keyboard dismissal
        focusedField = .question(questions.count - 1)
    }

    private func delete(at offsets: IndexSet) {
        let sorted = offsets.sorted()
        guard let first = sorted.first else { return }
        // Remove from highest to lowest to preserve indices
        for i in sorted.reversed() { questions.remove(at: i) }
        let newIndex = min(first, max(questions.count - 1, 0))
        // Set focus immediately to maintain keyboard
        focusedField = .question(newIndex)
    }
}

#Preview("List – 3 Questions") {
    struct Wrapper: View {
        @State var questions = [
            "What’s your ideal vacation?",
            "Do you prefer mornings or nights?",
            "Dogs, cats, or both?",
        ]
        @FocusState private var focused: CreateQuestionnaireView.FocusedField?
        var body: some View {
            QuestionListEditor(questions: $questions, focusedField: $focused)
                .frame(height: 480)
                .padding()
                .background(BlobBackgroundView())
        }
    }
    return Wrapper()
}
