//
//  VisualCus        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct VisualCustomizationSection: View {
    @Binding var questionnaire: Questionnaire
    @FocusState private var isEmojiFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
            SectionHeader(title: "Visual Style", icon: "paintbrush.fill")

            VStack(spacing: Tokens.Spacing.l) {
                // Color Pickers flanking the Icon
                HStack(spacing: Tokens.Spacing.xl) {
                    // Start Color Picker (Left)
                    VStack(spacing: Tokens.Spacing.xs) {
                        Text("Start")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker(
                            "Start",
                            selection: $questionnaire.startColor,
                            supportsOpacity: false
                        )
                        .labelsHidden()
                        .scaleEffect(Tokens.Scale.colorPicker)
                    }

                    Spacer()

                    // Interactive Icon (Center)
                    Button(action: { isEmojiFieldFocused.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            questionnaire.startColor,
                                            questionnaire.endColor,
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: Tokens.Size.iconXL,
                                    height: Tokens.Size.iconXL
                                )

                            Text(questionnaire.iconEmoji)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(
                                    isEmojiFieldFocused
                                        ? Color.blue : Color.clear,
                                    lineWidth: Tokens.Border.thick
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tap to change emoji")

                    Spacer()

                    // End Color Picker (Right)
                    VStack(spacing: Tokens.Spacing.xs) {
                        Text("End")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker(
                            "End",
                            selection: $questionnaire.endColor,
                            supportsOpacity: false
                        )
                        .labelsHidden()
                        .scaleEffect(Tokens.Scale.colorPicker)
                    }
                }
                .padding(.horizontal, Tokens.Spacing.xxl)

                // Helper text
                Text("Tap the icon to change emoji • Only emojis accepted")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Hidden emoji input that gets focus (SwiftUI-native)
                EmojiTextField(
                    text: $questionnaire.iconEmoji,
                    placeholder: "📝",
                    isFocused: $isEmojiFieldFocused
                )
                .frame(width: 0, height: 0)
                .opacity(0)

                // Control Buttons
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

                    Spacer()
                }
            }
            .padding()
            .standardGlassCard()
        }
    }

    private func swapColors() {
        let start = questionnaire.startColor
        let end = questionnaire.endColor
        questionnaire.startColor = end
        questionnaire.endColor = start
    }

    private func randomizeColors() {
        // Generate harmonious gradient using HSB
        let hue = Double.random(in: 0...1)
        let offset = Double.random(in: 0.12...0.2)  // pleasant separation using HSB color theory
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

    VisualCustomizationSection(
        questionnaire: $questionnaire
    )
    .padding()
}
