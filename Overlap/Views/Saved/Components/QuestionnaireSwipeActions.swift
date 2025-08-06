//
//  QuestionnaireSwipeActions.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireSwipeActions: ViewModifier {
    let questionnaire: Questionnaire
    let modelContext: ModelContext
    let onEdit: (Questionnaire) -> Void
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    withAnimation {
                        modelContext.delete(questionnaire)
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
                        questionnaire.isFavorite.toggle()
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
        questionnaire: Questionnaire,
        modelContext: ModelContext,
        onEdit: @escaping (Questionnaire) -> Void = { questionnaire in
            print("Edit \(questionnaire.title)")
        }
    ) -> some View {
        modifier(QuestionnaireSwipeActions(
            questionnaire: questionnaire,
            modelContext: modelContext,
            onEdit: onEdit
        ))
    }
}
