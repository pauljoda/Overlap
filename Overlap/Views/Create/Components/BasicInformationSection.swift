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
            SectionHeader(title: "Basic Information", icon: "info.circle.fill")
            
            VStack(spacing: Tokens.Spacing.m) {
                // Title Field
                VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                    HStack {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Enter questionnaire title", text: $questionnaire.title)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.sentences)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .padding()
                        .standardGlassCard()
                        .focused($focusedField, equals: .title)
                        .onSubmit { focusedField = .information }
                }
                
                // Information Field
                VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                    HStack {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Brief description of this questionnaire", text: $questionnaire.information, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.next)
                        .padding()
                        .standardGlassCard()
                        .focused($focusedField, equals: .information)
                        .onSubmit { focusedField = .instructions }
                }
                
                // Instructions Field
                VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                    HStack {
                        Text("Instructions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Instructions for participants", text: $questionnaire.instructions, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.next)
                        .padding()
                        .standardGlassCard()
                        .focused($focusedField, equals: .instructions)
                        .onSubmit { focusedField = .author }
                }
                
                // Author Field
                VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                    HStack {
                        Text("Author")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Your name", text: $questionnaire.author)
                        .textFieldStyle(.plain)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .padding()
                        .standardGlassCard()
                        .focused($focusedField, equals: .author)
                        .onSubmit { focusedField = .emoji }
                }
            }
            
            // Required fields note
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("* Required fields")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.top, 8)
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
