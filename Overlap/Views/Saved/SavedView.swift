//
//  SavedView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftData
import SwiftUI

struct SavedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @Query(
        filter: #Predicate<Questionnaire> { questionnaire in
            questionnaire.isFavorite == true
        },
        sort: \Questionnaire.title,
        order: .forward
    ) private var favoriteQuestionnaires: [Questionnaire]

    @Query(
        filter: #Predicate<Questionnaire> { questionnaire in
            questionnaire.isFavorite == false
        },
        sort: \Questionnaire.title,
        order: .forward
    ) private var regularQuestionnaires: [Questionnaire]

    var body: some View {
        GlassScreen(scrollable: false) {
            if favoriteQuestionnaires.isEmpty && regularQuestionnaires.isEmpty {
                EmptyQuestionnairesState {
                    navigate(to: .create, using: navigationPath)
                }
            } else {
                QuestionnairesListView(
                    favoriteQuestionnaires: favoriteQuestionnaires,
                    regularQuestionnaires: regularQuestionnaires,
                    modelContext: modelContext,
                    onEdit: handleEdit,
                    onDeleteFavorites: deleteFavoriteQuestionnaires,
                    onDeleteRegular: deleteRegularQuestionnaires
                )
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .navigationTitle("Saved Questionnaires")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.zero)
        .toolbar {
            if !(favoriteQuestionnaires.isEmpty
                && regularQuestionnaires.isEmpty)
            {

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigate(to: .create, using: navigationPath)
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }

    private func handleEdit(_ questionnaire: Questionnaire) {
        navigate(to: .edit(questionnaireId: questionnaire.id), using: navigationPath)
    }

    private func deleteFavoriteQuestionnaires(at offsets: IndexSet) {
        withAnimation {
            offsets.map { favoriteQuestionnaires[$0] }.forEach(
                modelContext.delete
            )
        }
    }

    private func deleteRegularQuestionnaires(at offsets: IndexSet) {
        withAnimation {
            offsets.map { regularQuestionnaires[$0] }.forEach(
                modelContext.delete
            )
        }
    }
}

#Preview {
    NavigationStack {
        SavedView()
    }
    .modelContainer(previewModelContainer)
}
