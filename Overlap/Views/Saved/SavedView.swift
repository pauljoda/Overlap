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
    @Query(filter: #Predicate<Questionnaire> { questionnaire in
        questionnaire.isFavorite == true
    }, sort: \Questionnaire.title, order: .forward) private var favoriteQuestionnaires: [Questionnaire]
    
    @Query(filter: #Predicate<Questionnaire> { questionnaire in
        questionnaire.isFavorite == false
    }, sort: \Questionnaire.title, order: .forward) private var regularQuestionnaires: [Questionnaire]

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: .none)

            if favoriteQuestionnaires.isEmpty && regularQuestionnaires.isEmpty {
                EmptyQuestionnairesState {
                    navigationPath.wrappedValue.append("create")
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
            }
        }
        .navigationTitle("Saved Questionnaires")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .contentMargins(0)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    navigationPath.wrappedValue.append("create")
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }

            if !(favoriteQuestionnaires.isEmpty && regularQuestionnaires.isEmpty) {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }
    
    private func handleEdit(_ questionnaire: Questionnaire) {
        // TODO: Implement edit functionality
        print("Edit \(questionnaire.title)")
    }
    
    private func deleteFavoriteQuestionnaires(at offsets: IndexSet) {
        withAnimation {
            offsets.map { favoriteQuestionnaires[$0] }.forEach(modelContext.delete)
        }
    }
    
    private func deleteRegularQuestionnaires(at offsets: IndexSet) {
        withAnimation {
            offsets.map { regularQuestionnaires[$0] }.forEach(modelContext.delete)
        }
    }
}

#Preview {
    NavigationStack {
        SavedView()
    }
    .modelContainer(previewModelContainer)
}
