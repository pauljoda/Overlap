//
//  ResultsSection.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable results section component for displaying questionnaire agreement results
/// 
/// Features:
/// - Configurable section title, icon, and color theme
/// - Question result cards with staggered animations
/// - Count badge display
/// - Consistent styling and spacing
struct ResultsSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let questions: [(Question, [String: Answer])]
    let isAnimated: Bool
    let animationDelay: Double
    let cardAnimationDelay: Double
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        accentColor: Color,
        questions: [(Question, [String: Answer])],
        isAnimated: Bool = false,
        animationDelay: Double = 0.0,
        cardAnimationDelay: Double = 1.0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.questions = questions
        self.isAnimated = isAnimated
        self.animationDelay = animationDelay
        self.cardAnimationDelay = cardAnimationDelay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.title2)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(questions.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(12)
            }
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
            
            ForEach(Array(questions.enumerated()), id: \.offset) { index, questionData in
                QuestionResultCard(
                    question: questionData.0,
                    responses: questionData.1,
                    accentColor: accentColor
                )
                .opacity(isAnimated ? 1 : 0)
                .offset(x: isAnimated ? 0 : (accentColor == .green ? -50 : 50))
                .animation(.easeOut(duration: 0.5).delay(cardAnimationDelay + Double(index) * 0.15), value: isAnimated)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : -20)
        .animation(.easeOut(duration: 0.6).delay(animationDelay), value: isAnimated)
    }
}

#Preview {
    ResultsSection(
        title: "Perfect Agreement",
        subtitle: "Everyone said yes to these questions",
        icon: "hands.clap.fill",
        accentColor: .green,
        questions: [(SampleData.sampleQuestions[0], ["Alice": .yes])],
        isAnimated: true
    )
    .padding()
}
