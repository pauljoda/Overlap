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
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Basic Information", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                // Title Field
                VStack(alignment: .leading, spacing: 8) {
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
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                        .focused($focusedField, equals: .title)
                }
                
                // Information Field
                VStack(alignment: .leading, spacing: 8) {
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
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                        .focused($focusedField, equals: .information)
                }
                
                // Instructions Field
                VStack(alignment: .leading, spacing: 8) {
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
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                        .focused($focusedField, equals: .instructions)
                }
                
                // Author Field
                VStack(alignment: .leading, spacing: 8) {
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
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                        .focused($focusedField, equals: .author)
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
