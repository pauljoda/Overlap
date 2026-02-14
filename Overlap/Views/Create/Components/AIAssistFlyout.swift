//
//  AIAssistFlyout.swift
//  Overlap
//
//  Sheet for AI-assisted questionnaire creation using on-device Foundation Models.
//

#if canImport(FoundationModels)
import FoundationModels
import SwiftUI

struct AIAssistFlyout: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback when the user applies the generated result.
    let onApply: (GeneratedQuestionnaire, AIAssistOptions) -> Void

    @State private var service = AIGenerationService()
    @State private var prompt: String = ""
    @State private var length: QuestionnaireLength = .medium
    @State private var generateTitleAndDescription: Bool = true
    @State private var generateInstructions: Bool = true
    @State private var replaceExisting: Bool = true

    @FocusState private var promptFocused: Bool

    private var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                switch service.state {
                case .idle, .failed:
                    inputPhase
                case .generating:
                    generatingPhase
                case .completed:
                    resultsPhase
                }
            }
            .navigationTitle("AI Assist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            promptFocused = false
                        }
                    }
                }
            }
        }
        .onAppear {
            service.prewarm()
            DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Duration.medium) {
                promptFocused = true
            }
        }
    }

    // MARK: - Input Phase

    private var inputPhase: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xl) {
                // Header
                VStack(spacing: Tokens.Spacing.l) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: Tokens.Size.iconLarge))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: Tokens.Spacing.s) {
                        Text("AI Assist")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Describe your questionnaire and let AI generate it for you.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Tokens.Spacing.l)

                // Prompt section
                VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                    SectionHeader(title: "Description", icon: "text.bubble.fill")

                    TextField(
                        "e.g. Fun icebreaker questions for a team meeting about food preferences...",
                        text: $prompt,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .focused($promptFocused)
                    .padding(Tokens.Spacing.m)
                    .standardGlassCard()
                }

                // Length section
                VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                    SectionHeader(title: "Length", icon: "slider.horizontal.3")

                    Picker("Length", selection: $length) {
                        ForEach(QuestionnaireLength.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Options section
                VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                    SectionHeader(title: "Options", icon: "gearshape.fill")

                    VStack(spacing: 0) {
                        Toggle("Generate Title & Description", isOn: $generateTitleAndDescription)
                            .padding(.horizontal, Tokens.Spacing.m)
                            .padding(.vertical, Tokens.Spacing.s)

                        Divider().padding(.horizontal, Tokens.Spacing.m)

                        Toggle("Generate Instructions", isOn: $generateInstructions)
                            .padding(.horizontal, Tokens.Spacing.m)
                            .padding(.vertical, Tokens.Spacing.s)

                        Divider().padding(.horizontal, Tokens.Spacing.m)

                        Toggle("Replace Existing Questions", isOn: $replaceExisting)
                            .padding(.horizontal, Tokens.Spacing.m)
                            .padding(.vertical, Tokens.Spacing.s)
                    }
                    .standardGlassCard()
                }

                // Error message
                if case .failed(let message) = service.state {
                    HStack(spacing: Tokens.Spacing.s) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(Tokens.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .standardGlassCard()
                }

                // Generate button
                GlassActionButton(
                    title: "Generate",
                    icon: "apple.intelligence",
                    isEnabled: canGenerate,
                    tintColor: .purple
                ) {
                    promptFocused = false
                    Task {
                        await service.generate(prompt: prompt, length: length)
                    }
                }

                Spacer().frame(height: Tokens.Spacing.quadXL)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Generating Phase

    private var generatingPhase: some View {
        GlassScreen {
            AIGeneratingView(partialResult: service.partialResult)
                .padding(.horizontal, Tokens.Spacing.xl)
        }
    }

    // MARK: - Results Phase

    private var resultsPhase: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xl) {
                // Success header
                VStack(spacing: Tokens.Spacing.l) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Tokens.Size.iconLarge))
                        .foregroundColor(.green)

                    VStack(spacing: Tokens.Spacing.s) {
                        Text("Questionnaire Generated")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Review the results below, then apply them to your questionnaire.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Tokens.Spacing.l)

                if let result = service.completedResult {
                    // Title & Description preview
                    if generateTitleAndDescription {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                            SectionHeader(title: "Title & Description", icon: "text.quote")

                            VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                                Text(result.title)
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text(result.information)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(Tokens.Spacing.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .standardGlassCard()
                        }
                    }

                    // Instructions preview
                    if generateInstructions {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                            SectionHeader(title: "Instructions", icon: "list.clipboard.fill")

                            Text(result.instructions)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(Tokens.Spacing.m)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .standardGlassCard()
                        }
                    }

                    // Questions preview
                    VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                        HStack {
                            SectionHeader(title: "Questions", icon: "questionmark.bubble.fill")
                            Spacer()
                            Text("\(result.questions.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                                .padding(.horizontal, Tokens.Spacing.s)
                                .padding(.vertical, Tokens.Spacing.xs)
                                .background(Color.purple.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                            ForEach(Array(result.questions.enumerated()), id: \.offset) { index, question in
                                HStack(alignment: .top, spacing: Tokens.Spacing.s) {
                                    Text("\(index + 1).")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.purple)
                                        .frame(width: 24, alignment: .trailing)

                                    Text(question)
                                        .font(.subheadline)
                                }

                                if index < result.questions.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .padding(Tokens.Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .standardGlassCard()
                    }
                }

                // Action buttons
                GlassActionButton(
                    title: "Apply to Questionnaire",
                    icon: "checkmark.circle.fill",
                    tintColor: .green
                ) {
                    applyResult()
                }

                GlassActionButton(
                    title: "Regenerate",
                    icon: "arrow.clockwise",
                    tintColor: .purple
                ) {
                    service.reset()
                }

                Spacer().frame(height: Tokens.Spacing.quadXL)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
        }
    }

    // MARK: - Actions

    private func applyResult() {
        guard let result = service.completedResult else { return }
        let options = AIAssistOptions(
            generateTitleAndDescription: generateTitleAndDescription,
            generateInstructions: generateInstructions,
            replaceExisting: replaceExisting
        )
        onApply(result, options)
        dismiss()
    }
}

/// Options the user selected in the AI assist flyout.
struct AIAssistOptions {
    let generateTitleAndDescription: Bool
    let generateInstructions: Bool
    let replaceExisting: Bool
}
#endif
