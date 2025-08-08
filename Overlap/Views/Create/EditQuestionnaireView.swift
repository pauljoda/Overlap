//
//  EditQuestionnaireView.swift
//  Overlap
//
//  A wrapper view that loads an existing questionnaire for editing
//

import SwiftUI
import SwiftData

struct EditQuestionnaireView: View {
    let questionnaireId: UUID
    @Query private var questionnaires: [Questionnaire]
    @Environment(\.dismiss) private var dismiss
    
    init(questionnaireId: UUID) {
        self.questionnaireId = questionnaireId
        self._questionnaires = Query(
            filter: #Predicate<Questionnaire> { questionnaire in
                questionnaire.id == questionnaireId
            }
        )
    }
    
    var body: some View {
        Group {
            if let questionnaire = questionnaires.first {
                CreateQuestionnaireView(editingQuestionnaire: questionnaire)
            } else {
                ContentUnavailableView(
                    "Questionnaire Not Found",
                    systemImage: "questionmark.circle",
                    description: Text("The questionnaire you're trying to edit could not be found.")
                )
                .navigationTitle("Edit Questionnaire")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let q = Questionnaire(
        title: "Sample Questionnaire",
        information: "A test questionnaire",
        instructions: "Answer all questions",
        author: "Test Author",
        questions: ["Question 1", "Question 2"]
    )
    
    return NavigationStack {
        EditQuestionnaireView(questionnaireId: q.id)
    }
    .modelContainer(for: Questionnaire.self, inMemory: true)
}
