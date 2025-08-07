//
//  QuestionsSection.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct QuestionsSection: View {
    @Binding var questions: [String]
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack {
                    SectionHeader(title: "Questions", icon: "questionmark.bubble.fill")
                    
                    Text("*")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: addQuestion) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
            
            ForEach(questions.indices, id: \.self) { index in
                QuestionInputField(
                    question: $questions[index],
                    questionNumber: index + 1,
                    focusedField: $focusedField,
                    onRemove: questions.count > 1 ? { removeQuestion(at: index) } : nil
                )
            }
        }
    }
    
    private func addQuestion() {
        questions.append("")
        // Focus the new question field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .question(questions.count - 1)
        }
    }
    
    private func removeQuestion(at index: Int) {
        guard questions.count > 1, index < questions.count else { return }
        questions.remove(at: index)
    }
}

struct QuestionInputField: View {
    @Binding var question: String
    let questionNumber: Int
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?
    let onRemove: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(questionNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            TextField("Enter your question", text: $question, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .padding()
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                .focused($focusedField, equals: .question(questionNumber - 1))
        }
    }
}

#Preview {
    @State var questions = ["", ""]
    @FocusState var focusedField: CreateQuestionnaireView.FocusedField?
    
    QuestionsSection(
        questions: $questions,
        focusedField: $focusedField
    )
    .padding()
}
