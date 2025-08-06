//
//  QuestionnaireSection.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireSection: View {
    let title: String
    let questionnaires: [Questionnaire]
    let modelContext: ModelContext
    let onDelete: (IndexSet) -> Void
    let onEdit: (Questionnaire) -> Void
    
    var body: some View {
        Section(title) {
            ForEach(questionnaires) { questionnaire in
                QuestionnaireListItem(questionnaire: questionnaire)
                    .questionnaireSwipeActions(
                        questionnaire: questionnaire,
                        modelContext: modelContext,
                        onEdit: onEdit
                    )
            }
            .onDelete(perform: onDelete)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 25))
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    List {
        QuestionnaireSection(
            title: "Favorites",
            questionnaires: [SampleData.sampleQuestionnaire],
            modelContext: previewModelContainer.mainContext,
            onDelete: { _ in },
            onEdit: { _ in }
        )
    }
    .modelContainer(previewModelContainer)
}
