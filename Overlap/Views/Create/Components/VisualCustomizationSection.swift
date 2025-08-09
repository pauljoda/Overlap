//
//  VisualCus        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct VisualCustomizationSection: View {
    @Binding var questionnaire: Questionnaire
    @Binding var showingColorPicker: Bool
    @Binding var selectedColorType: CreateQuestionnaireView.ColorType
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?
    @State private var isEmojiFieldFocused = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Visual Style", icon: "paintbrush.fill")
            
            VStack(spacing: 16) {
                // Emoji Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emoji")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        // Toggle focus - if focused, unfocus to dismiss keyboard
                        if focusedField == .emoji {
                            focusedField = nil
                            isEmojiFieldFocused = false
                        } else {
                            focusedField = .emoji
                            isEmojiFieldFocused = true
                        }
                    }) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [questionnaire.startColor, questionnaire.endColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: Tokens.Size.iconMedium, height: Tokens.Size.iconMedium)
                                
                                Text(questionnaire.iconEmoji)
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                Text(isEmojiFieldFocused ? "Tap to Close" : "Tap to Change")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(isEmojiFieldFocused ? "Keyboard will close" : "Emoji keyboard opens automatically")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Emoji Input Field
                            EmojiTextField(
                                text: $questionnaire.iconEmoji, 
                                placeholder: "📝",
                                isFocused: $isEmojiFieldFocused
                            )
                            .frame(width: Tokens.Size.iconLarge, height: Tokens.Size.iconLarge)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Tokens.Radius.m))
                            .overlay(
                                RoundedRectangle(cornerRadius: Tokens.Radius.m)
                                    .stroke(
                                        isEmojiFieldFocused ? Color.blue : Color.blue.opacity(0.3), 
                                        lineWidth: isEmojiFieldFocused ? Tokens.Border.thick : Tokens.Border.standard
                                    )
                            )
                            .allowsHitTesting(false) // Prevent double-tap issues
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onChange(of: focusedField) { oldValue, newValue in
                        isEmojiFieldFocused = newValue == .emoji
                    }
                    .padding()
                    .standardGlassCard()
                }
                
                // Color Selection
                VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                    Text("Colors")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: Tokens.Spacing.l) {
                        // Start Color (aligned center with bar)
                        Button(action: {
                            selectedColorType = .start
                            showingColorPicker = true
                        }) {
                            Circle()
                                .fill(questionnaire.startColor)
                                .frame(width: Tokens.Size.iconMedium, height: Tokens.Size.iconMedium)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: Tokens.Border.thick)
                                        .shadow(radius: Tokens.Shadow.subtle.radius)
                                )
                        }
                        .accessibilityLabel("Start color")
                        .accessibilityHint("Tap to choose the start color of the gradient")

                        // Gradient Preview (flexes in the middle)
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [questionnaire.startColor, questionnaire.endColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: Tokens.Size.iconMedium)
                            .frame(maxWidth: .infinity)

                        // End Color (aligned center with bar)
                        Button(action: {
                            selectedColorType = .end
                            showingColorPicker = true
                        }) {
                            Circle()
                                .fill(questionnaire.endColor)
                                .frame(width: Tokens.Size.iconMedium, height: Tokens.Size.iconMedium)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: Tokens.Border.thick)
                                        .shadow(radius: Tokens.Shadow.subtle.radius)
                                )
                        }
                        .accessibilityLabel("End color")
                        .accessibilityHint("Tap to choose the end color of the gradient")
                    }
                    .padding()
                    .standardGlassCard()

                    // Controls: Swap and Randomize
                    HStack(spacing: Tokens.Spacing.m) {
                        Button {
                            swapColors()
                        } label: {
                            Label("Swap", systemImage: "arrow.left.arrow.right")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            randomizeColors()
                        } label: {
                            Label("Randomize", systemImage: "sparkles")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func swapColors() {
        let start = questionnaire.startColor
        questionnaire.startColor = questionnaire.endColor
        questionnaire.endColor = start
    }

    private func randomizeColors() {
        // Generate harmonious gradient using HSB
        let hue = Double.random(in: 0...1)
        let offset = Double.random(in: 0.12...0.2) // pleasant separation
        let startHue = hue
        let endHue = fmod(hue + offset, 1.0)
        let start = Color(hue: startHue, saturation: 0.7, brightness: 0.95)
        let end = Color(hue: endHue, saturation: 0.7, brightness: 0.85)
        questionnaire.startColor = start
        questionnaire.endColor = end
    }
}

#Preview {
    @State var questionnaire = Questionnaire()
    @State var showingColorPicker = false
    @State var selectedColorType: CreateQuestionnaireView.ColorType = .start
    @FocusState var focusedField: CreateQuestionnaireView.FocusedField?
    
    VisualCustomizationSection(
        questionnaire: $questionnaire,
        showingColorPicker: $showingColorPicker,
        selectedColorType: $selectedColorType,
        focusedField: $focusedField
    )
    .padding()
}
