//
//  QuestionnaireHeader.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable header component for questionnaire views
/// 
/// Features:
/// - Title and instructions display from Overlap questionnaire
/// - Consistent typography and spacing
/// - Responsive design
struct QuestionnaireHeader: View {
    let overlap: Overlap
    
    var body: some View {
        VStack(spacing: 16) {
            Text(overlap.session.questionnaire.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(overlap.session.questionnaire.instructions)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
}

#Preview {
    QuestionnaireHeader(overlap: SampleData.sampleOverlap)
        .padding()
}
