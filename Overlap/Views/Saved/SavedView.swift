//
//  SavedView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SharingGRDB

struct SavedView: View {
    @Environment(\.navigationPath) private var navigationPath
    @Dependency(\.defaultDatabase) var database
    
    @FetchAll(
        Questionnaire.where { $0.isFavorite == true }.order { $0.creationDate.desc() }
    ) private var favoriteQuestionnaires

    @FetchAll(
        Questionnaire.where { $0.isFavorite == false }.order { $0.creationDate.desc() }
    ) private var regularQuestionnaires

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
                    onEdit: handleEdit,
                    onDeleteFavorites: deleteFavoriteQuestionnaires,
                    onDeleteRegular: deleteRegularQuestionnaires,
                    onDeleteQuestionnaire: deleteQuestionnaire
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
        withErrorReporting {
            try database.write { db in
                for index in offsets {
                    let questionnaire = favoriteQuestionnaires[index]
                    try Questionnaire.delete(questionnaire).execute(db)
                }
            }
        }
    }

    private func deleteRegularQuestionnaires(at offsets: IndexSet) {
        withErrorReporting {
            try database.write { db in
                for index in offsets {
                    let questionnaire = regularQuestionnaires[index]
                    try Questionnaire.delete(questionnaire).execute(db)
                }
            }
        }
    }
    
    private func deleteQuestionnaire(_ questionnaire: Questionnaire) {
        withErrorReporting {
            try database.write { db in
                try Questionnaire.delete(questionnaire).execute(db)
            }
        }
    }
}

#Preview("GRDB Only") {
    let _ = setupGRDBPreview()
    
    NavigationStack {
        SavedView()
    }
}
