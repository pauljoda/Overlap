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
        HStack(spacing: 12) {
            // Leading icon
            QuestionnaireIcon(questionnaire: questionnaire, size: .small)
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(questionnaire.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if !questionnaire.information.isEmpty {
                    Text(questionnaire.information)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Metadata section
                HStack(spacing: 12) {
                    // Question count
                    HStack(spacing: 4) {
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
                        .frame(width: 2, height: 2)
                    
                    // Author or date
                    if !questionnaire.author.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(questionnaire.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        HStack(spacing: 4) {
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
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .standardGlassCard()
    }
}

#Preview {
    QuestionnaireListItem(questionnaire: SampleData.sampleQuestionnaire)
}
