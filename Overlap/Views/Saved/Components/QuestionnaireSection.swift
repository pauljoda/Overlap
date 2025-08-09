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
    @Environment(\.navigationPath) private var navigationPath
    
    var body: some View {
        Section {
            ForEach(questionnaires) { questionnaire in
                Button {
                    navigate(to: questionnaire, using: navigationPath)
                } label: {
                    QuestionnaireListItem(questionnaire: questionnaire)
                }
                .buttonStyle(PlainButtonStyle())
                .questionnaireSwipeActions(
                    questionnaire: questionnaire,
                    modelContext: modelContext,
                    onEdit: onEdit
                )
            }
            .onDelete(perform: onDelete)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Tokens.Spacing.xs, leading: Tokens.Spacing.xxl, bottom: Tokens.Spacing.xs, trailing: Tokens.Spacing.xxl))
            .listRowBackground(Color.clear)
        } header: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Tokens.Spacing.xxl)
                .padding(.top, Tokens.Spacing.m)
                .textCase(nil)
                .background(Color.clear)
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
