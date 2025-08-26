//
//  QuestionnaireIcon.swift
//  Overlap
//
//  Centralized questionnaire icon component with gradient background
//

import SwiftUI

struct QuestionnaireIcon: View {
    let questionnaire: Questionnaire
    let size: IconSize
    
    enum IconSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return Tokens.Size.iconMedium
            case .medium: return Tokens.Size.iconXL
            case .large: return Tokens.Size.iconHuge
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return Tokens.Radius.s
            case .medium, .large: return dimension / 2  // Circle
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .title3
            case .medium: return .largeTitle
            case .large: return .system(size: Tokens.FontSize.extraLarge)
            }
        }
    }
    
    var body: some View {
        ZStack {
            if size == .small {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [questionnaire.startColor.opacity(0.8), questionnaire.endColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.dimension, height: size.dimension)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [questionnaire.startColor, questionnaire.endColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.dimension, height: size.dimension)
            }
            
            Text(questionnaire.iconEmoji)
                .font(size.fontSize)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: Tokens.Spacing.xl) {
        QuestionnaireIcon(questionnaire: SampleData.sampleQuestionnaire, size: .small)
        QuestionnaireIcon(questionnaire: SampleData.sampleQuestionnaire, size: .medium)
        QuestionnaireIcon(questionnaire: SampleData.sampleQuestionnaire, size: .large)
    }
    .padding()
}
