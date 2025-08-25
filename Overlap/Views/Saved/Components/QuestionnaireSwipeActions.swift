//
//  QuestionnaireSwipeActions.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SwiftData
import SharingGRDB

struct QuestionnaireSwipeActions: ViewModifier {
    let questionnaire: QuestionnaireTable
    let onEdit: (QuestionnaireTable) -> Void
    let onDelete: (QuestionnaireTable) -> Void
    
    @Dependency(\.defaultDatabase) var database
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    withAnimation {
                        onDelete(questionnaire)
                    }
                } label: {
                    Image(systemName: "trash.fill")
                }
                
                Button {
                    onEdit(questionnaire)
                } label: {
                    Image(systemName: "pencil")
                }
                .tint(.blue)
            }
            .swipeActions(edge: .leading) {
                Button {
                    withAnimation {
                        withErrorReporting {
                            try database.write { db in
                                var updatedQuestionnaire = questionnaire
                                updatedQuestionnaire.isFavorite.toggle()
                                try QuestionnaireTable.update(updatedQuestionnaire).execute(db)
                            }
                        }
                    }
                } label: {
                    Image(systemName: questionnaire.isFavorite ? "star.slash.fill" : "star.fill")
                }
                .tint(.yellow)
            }
    }
}

extension View {
    func questionnaireSwipeActions(
        questionnaire: QuestionnaireTable,
        onEdit: @escaping (QuestionnaireTable) -> Void = { questionnaire in
            print("Edit \(questionnaire.title)")
        },
        onDelete: @escaping (QuestionnaireTable) -> Void = { questionnaire in
            print("Delete \(questionnaire.title)")
        }
    ) -> some View {
        modifier(QuestionnaireSwipeActions(
            questionnaire: questionnaire,
            onEdit: onEdit,
            onDelete: onDelete
        ))
    }
}
