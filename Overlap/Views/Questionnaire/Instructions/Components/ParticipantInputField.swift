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
    @State private var showAddButton: Bool = false
    @Namespace private var namespace

    let placeholder: String
    let onSubmit: () -> Void

    private var isInputValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func checkAddButton() {
        if isInputValid && !showAddButton {
            withAnimation {
                showAddButton.toggle()
            }
        } else if !isInputValid && showAddButton {
            withAnimation {
                showAddButton.toggle()
            }
        }
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.secondary)
                        .font(.body)

                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .onSubmit { if isInputValid { onSubmit() } }
                        .onChange(of: text) { checkAddButton() }
                        .submitLabel(.done)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 50)
                .glassEffect()
                .glassEffectID("participant-input", in: namespace)
                .cornerRadius(25)

                if showAddButton {
                    // Add Button
                    Button(action: onSubmit) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .glassEffectID("add-button", in: namespace)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""
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
}

