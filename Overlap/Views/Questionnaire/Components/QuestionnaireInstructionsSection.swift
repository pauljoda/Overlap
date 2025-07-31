//
//  QuestionnaireInstructionsSection.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable questionnaire instructions section component
/// 
/// Features:
/// - Section title and instructions display from Overlap
/// - Consistent glass-effect background styling
/// - Configurable animation support
struct QuestionnaireInstructionsSection: View {
    let overlap: Overlap
    let title: String
    let isAnimated: Bool
    let animationDelay: Double
    
    init(
        overlap: Overlap,
        title: String = "Questionnaire Instructions",
        isAnimated: Bool = false,
        animationDelay: Double = 0.0
    ) {
        self.overlap = overlap
        self.title = title
        self.isAnimated = isAnimated
        self.animationDelay = animationDelay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(overlap.questionnaire.instructions)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(20)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(40)
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(
            .easeOut(duration: 0.6).delay(animationDelay),
            value: isAnimated
        )
    }
}

#Preview {
    QuestionnaireInstructionsSection(
        overlap: SampleData.sampleOverlap,
        isAnimated: true,
        animationDelay: 0.0
    )
    .padding()
}
