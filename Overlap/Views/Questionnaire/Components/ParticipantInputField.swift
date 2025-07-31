//
//  ParticipantInputField.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable input field component for adding participants with glass effect styling
/// 
/// Features:
/// - Glass effect background
/// - Integrated add button with dynamic state
/// - Automatic focus management
/// - Custom submit handling
struct ParticipantInputField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let placeholder: String
    let onSubmit: () -> Void
    
    private var isInputValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.secondary)
                    .font(.body)

                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .onSubmit(onSubmit)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 50)
            .glassEffect(.regular)
            .cornerRadius(40)

            // Add Button
            Button(action: onSubmit) {
                Image(systemName: "plus")
                    .font(.largeTitle)
            }
            .disabled(!isInputValid)
            .buttonStyle(GlassProminentButtonStyle())
            .glassEffect(.regular.interactive())
            .animation(.easeInOut(duration: 0.2), value: isInputValid)
        }
    }
}

#Preview {
    @State var text = ""
    @FocusState var isFocused: Bool
    
    return VStack {
        ParticipantInputField(
            text: $text,
            isFocused: $isFocused,
            placeholder: "Enter participant name"
        ) {
            print("Add participant: \(text)")
            text = ""
        }
    }
    .padding()
}
