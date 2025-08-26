//
//  EditQuestionnaireView.swift
//  Overlap
//
//  A wrapper view that loads an existing questionnaire for editing
//

import SharingGRDB
import SwiftUI

struct EditQuestionnaireView: View {
    let questionnaireId: UUID
    @State private var questionnaire: Questionnaire?
    @State private var isLoading = true

    @Dependency(\.defaultDatabase) private var database
    @Environment(\.dismiss) private var dismiss

    init(questionnaireId: UUID) {
        self.questionnaireId = questionnaireId
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .navigationTitle("Edit Questionnaire")
                    .navigationBarTitleDisplayMode(.inline)
            } else if let questionnaire = questionnaire {
                CreateQuestionnaireView(editingQuestionnaire: questionnaire)
            } else {
                ContentUnavailableView(
                    "Questionnaire Not Found",
                    systemImage: "questionmark.circle",
                    description: Text(
                        "The questionnaire you're trying to edit could not be found."
                    )
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
        .onAppear {
            loadQuestionnaire()
        }
    }
    
    private func loadQuestionnaire() {
        withErrorReporting {
            try database.read { db in
                questionnaire = try Questionnaire.find(questionnaireId).fetchOne(db)
                isLoading = false
            }
        }
    }
}

#Preview("Current - Combined") {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    NavigationStack {
        EditQuestionnaireView(questionnaireId: SampleData.sampleQuestionnaire.id)
    }
}

#Preview("Future - GRDB Only") {
    let _ = setupGRDBPreview()
    
    NavigationStack {
        EditQuestionnaireView(questionnaireId: SampleData.sampleQuestionnaire.id)
    }
}
