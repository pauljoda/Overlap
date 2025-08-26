//
//  QuestionnairesListView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct QuestionnairesListView: View {
    let favoriteQuestionnaires: [Questionnaire]
    let regularQuestionnaires: [Questionnaire]

    let onEdit: (Questionnaire) -> Void
    let onDeleteFavorites: (IndexSet) -> Void
    let onDeleteRegular: (IndexSet) -> Void
    let onDeleteQuestionnaire: (Questionnaire) -> Void
    
    var body: some View {
    List {
            // Favorites Section
            if !favoriteQuestionnaires.isEmpty {
                QuestionnaireSection(
                    title: "Favorites",
                    questionnaires: favoriteQuestionnaires,
                    onDelete: onDeleteFavorites,
                    onEdit: onEdit,
                    onDeleteQuestionnaire: onDeleteQuestionnaire
                )
            }
            
            // Regular Questionnaires Section
            if !regularQuestionnaires.isEmpty {
                QuestionnaireSection(
                    title: favoriteQuestionnaires.isEmpty ? "Questionnaires" : "Other Questionnaires",
                    questionnaires: regularQuestionnaires,
                    onDelete: onDeleteRegular,
                    onEdit: onEdit,
                    onDeleteQuestionnaire: onDeleteQuestionnaire
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
        onEdit: { _ in },
        onDeleteFavorites: { _ in },
        onDeleteRegular: { _ in },
        onDeleteQuestionnaire: { _ in }
    )
}
