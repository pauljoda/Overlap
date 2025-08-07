//
//  CreateQuestionnaireHeader.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct CreateQuestionnaireHeader: View {
    let questionnaire: Questionnaire
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [questionnaire.startColor, questionnaire.endColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(questionnaire.iconEmoji)
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Create New Questionnaire")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Design questions to discover where opinions overlap")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    CreateQuestionnaireHeader(questionnaire: Questionnaire())
        .padding()
}
