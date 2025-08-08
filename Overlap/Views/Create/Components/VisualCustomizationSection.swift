//
//  VisualCustomizationSection.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct VisualCustomizationSection: View {
    @Binding var questionnaire: Questionnaire
    @Binding var showingColorPicker: Bool
    @Binding var selectedColorType: CreateQuestionnaireView.ColorType
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
                        isEmojiFieldFocused.toggle()
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
                                    .frame(width: 50, height: 50)
                                
                                Text(questionnaire.iconEmoji)
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
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
                            .frame(width: 60, height: 60)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isEmojiFieldFocused ? Color.blue : Color.blue.opacity(0.3), 
                                        lineWidth: isEmojiFieldFocused ? 2 : 1
                                    )
                            )
                            .allowsHitTesting(false) // Prevent double-tap issues
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .standardGlassCard()
                }
                
                // Color Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colors")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        // Start Color (aligned center with bar)
                        Button(action: {
                            selectedColorType = .start
                            showingColorPicker = true
                        }) {
                            Circle()
                                .fill(questionnaire.startColor)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .shadow(radius: 2)
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
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)

                        // End Color (aligned center with bar)
                        Button(action: {
                            selectedColorType = .end
                            showingColorPicker = true
                        }) {
                            Circle()
                                .fill(questionnaire.endColor)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .shadow(radius: 2)
                                )
                        }
                        .accessibilityLabel("End color")
                        .accessibilityHint("Tap to choose the end color of the gradient")
                    }
                    .padding()
                    .standardGlassCard()

                    // Controls: Swap and Randomize
                    HStack(spacing: 12) {
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
    
    VisualCustomizationSection(
        questionnaire: $questionnaire,
        showingColorPicker: $showingColorPicker,
        selectedColorType: $selectedColorType
    )
    .padding()
}
