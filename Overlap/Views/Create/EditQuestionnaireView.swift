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
    let container = try! ModelContainer(for: Questionnaire.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    let sampleQuestionnaire = Questionnaire(
        title: "Sample Questionnaire",
        information: "A test questionnaire for preview",
        instructions: "Answer all questions honestly",
        author: "Test Author",
        questions: ["Do you like pizza?", "Is the sky blue?", "Should we work from home?"]
    )
    
    context.insert(sampleQuestionnaire)
    try! context.save()
    
    return NavigationStack {
        EditQuestionnaireView(questionnaireId: sampleQuestionnaire.id)
    }
    .modelContainer(container)
}

#Preview("Empty Questionnaire") {
    let container = try! ModelContainer(for: Questionnaire.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    let emptyQuestionnaire = Questionnaire()
    context.insert(emptyQuestionnaire)
    try! context.save()
    
    return NavigationStack {
        EditQuestionnaireView(questionnaireId: emptyQuestionnaire.id)
    }
    .modelContainer(container)
}
