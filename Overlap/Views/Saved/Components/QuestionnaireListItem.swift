//
//  QuestionnaireListItem.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct QuestionnaireListItem: View {
    
    let questionnaire: Questionnaire
    
    var body: some View {
        HStack(spacing: Tokens.Spacing.m) {
            // Leading icon
            QuestionnaireIcon(questionnaire: questionnaire, size: .small)
            
            // Main content
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(questionnaire.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if !questionnaire.description.isEmpty {
                    Text(questionnaire.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Metadata section
                HStack(spacing: Tokens.Spacing.m) {
                    // Question count
                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(questionnaire.questions.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    // Separator
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: Tokens.Border.thick, height: Tokens.Border.thick)
                    
                    // Author or date
                    if !questionnaire.author.isEmpty {
                        HStack(spacing: Tokens.Spacing.xs) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(questionnaire.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        HStack(spacing: Tokens.Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(questionnaire.creationDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Trailing chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                //.foregroundColor(.tertiary)
        }
        .padding(.vertical, Tokens.Spacing.s)
        .padding(.horizontal, Tokens.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width touch target
        .contentShape(Rectangle()) // Make entire area tappable
        .standardGlassCard()
    }
}

#Preview {
    QuestionnaireListItem(questionnaire: SampleData.sampleQuestionnaire)
}
