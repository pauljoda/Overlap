//
//  QuestionnairesListView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SwiftData

struct QuestionnairesListView: View {
    let favoriteQuestionnaires: [Questionnaire]
    let regularQuestionnaires: [Questionnaire]
    let modelContext: ModelContext
    let onEdit: (Questionnaire) -> Void
    let onDeleteFavorites: (IndexSet) -> Void
    let onDeleteRegular: (IndexSet) -> Void
    
    var body: some View {
    List {
            // Favorites Section
            if !favoriteQuestionnaires.isEmpty {
                QuestionnaireSection(
                    title: "Favorites",
                    questionnaires: favoriteQuestionnaires,
                    modelContext: modelContext,
                    onDelete: onDeleteFavorites,
                    onEdit: onEdit
                )
            }
            
            // Regular Questionnaires Section
            if !regularQuestionnaires.isEmpty {
                QuestionnaireSection(
                    title: favoriteQuestionnaires.isEmpty ? "Questionnaires" : "Other Questionnaires",
                    questionnaires: regularQuestionnaires,
                    modelContext: modelContext,
                    onDelete: onDeleteRegular,
                    onEdit: onEdit
                )
            }
        }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.clear)
    .listSectionSeparator(.hidden)
    }
}

#Preview {
    QuestionnairesListView(
        favoriteQuestionnaires: [SampleData.sampleQuestionnaire],
        regularQuestionnaires: [SampleData.sampleQuestionnaire2],
        modelContext: previewModelContainer.mainContext,
        onEdit: { _ in },
        onDeleteFavorites: { _ in },
        onDeleteRegular: { _ in }
    )
    .modelContainer(previewModelContainer)
}
