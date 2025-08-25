//
//  QuestionnaireSection.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SwiftData
import SharingGRDB

struct QuestionnaireSection: View {
    let title: String
    let questionnaires: [QuestionnaireTable]
    let onDelete: (IndexSet) -> Void
    let onEdit: (QuestionnaireTable) -> Void
    let onDeleteQuestionnaire: (QuestionnaireTable) -> Void
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
                    onEdit: onEdit,
                    onDelete: onDeleteQuestionnaire
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

#Preview("Current - Combined") {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    List {
        QuestionnaireSection(
            title: "Favorites",
            questionnaires: [SampleData.sampleQuestionnaire],
            onDelete: { _ in },
            onEdit: { _ in },
            onDeleteQuestionnaire: { _ in }
        )
    }
    .modelContainer(previewModelContainer)
}

#Preview("Future - GRDB Only") {
    let _ = setupGRDBPreview()
    
    List {
        QuestionnaireSection(
            title: "Favorites",
            questionnaires: [SampleData.sampleQuestionnaire],
            onDelete: { _ in },
            onEdit: { _ in },
            onDeleteQuestionnaire: { _ in }
        )
    }
}
