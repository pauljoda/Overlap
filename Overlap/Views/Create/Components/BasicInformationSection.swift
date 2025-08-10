//
//  BasicInformationSection.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct BasicInformationSection: View {
    @Binding var questionnaire: Questionnaire
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
            SectionHeader(
                title: "Basic Information",
                icon: "info.circle.fill"
            )
            
            VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
                // Title
                TextField("Title", text: $questionnaire.title)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                    .focused($focusedField, equals: .title)
                    .onSubmit { focusedField = .author }

                // Author
                TextField("Your name", text: $questionnaire.author)
                    .textFieldStyle(.plain)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                    .focused($focusedField, equals: .author)
                    .onSubmit { focusedField = .information }

                // Description
                TextField("Description", text: $questionnaire.information, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                    .focused($focusedField, equals: .information)
                    .onSubmit { focusedField = .instructions }

                // Instructions
                TextField("Instructions", text: $questionnaire.instructions, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                    .focused($focusedField, equals: .instructions)
                    .onSubmit { focusedField = nil }
            }
        }
    }
}

#Preview {
    @State var questionnaire = Questionnaire()
    @FocusState var focusedField: CreateQuestionnaireView.FocusedField?

    BasicInformationSection(
        questionnaire: $questionnaire,
        focusedField: $focusedField
    )
    .padding()
}
