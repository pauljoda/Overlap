//
//  CreateQuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftData
import SwiftUI

struct CreateQuestionnaireView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.navigationPath) private var navigationPath

    // Editing support
    let editingQuestionnaire: Questionnaire?
    private var isEditing: Bool { editingQuestionnaire != nil }

    @State private var questionnaire = Questionnaire()
    @State private var questions: [String] = [""]

    // Create a binding that works with either the editing questionnaire or the local one
    private var questionnaireBinding: Binding<Questionnaire> {
        if isEditing {
            return Binding(
                get: { editingQuestionnaire! },
                set: { _ in }  // SwiftData will handle the changes automatically
            )
        } else {
            return $questionnaire
        }
    }

    @FocusState private var focusedField: FocusedField?

    // Feedback triggers for modern SwiftUI sensory feedback
    @State private var saveFeedbackKey: Int = 0
    @State private var saveSucceeded: Bool = false
    // Track currently selected question card for auto-focus
    @State private var selectedQuestionIndex: Int = 0

    init(editingQuestionnaire: Questionnaire? = nil) {
        self.editingQuestionnaire = editingQuestionnaire
    }
    
    enum FocusedField: Hashable {
        case title
        case information
        case instructions
        case author
        case question(Int)

        // Check if this field is in the questions section
        var isQuestionField: Bool {
            switch self {
            case .question:
                return true
            case .title, .information, .instructions, .author:
                return false
            }
        }
    }

    private var isValid: Bool {
        let currentQuestionnaire = questionnaireBinding.wrappedValue
        let hasTitle = !currentQuestionnaire.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let hasInformation = !currentQuestionnaire.information
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        let hasInstructions = !currentQuestionnaire.instructions
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        let hasAuthor = !currentQuestionnaire.author.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let hasValidQuestions = questions.contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return hasTitle && hasInformation && hasInstructions && hasAuthor
            && hasValidQuestions
    }

    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xl) {
                // Header
                CreateQuestionnaireHeader(
                    questionnaire: questionnaireBinding.wrappedValue
                )

                // Basic Information Section
                BasicInformationSection(
                    questionnaire: questionnaireBinding,
                    focusedField: $focusedField
                )

                // Visual Customization Section
                VisualCustomizationSection(
                    questionnaire: questionnaireBinding
                )

                // Questions Section - now self-contained with header
                QuestionEditor(
                    questions: $questions,
                    focusedField: $focusedField,
                    selectedIndex: $selectedQuestionIndex
                )

            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.xl)

            // Simple spacer to allow scrolling above keyboard
            Spacer()
                .frame(height: Tokens.Size.cardMaxHeight + Tokens.Spacing.quadXL)
        }
        .navigationTitle(
            isEditing ? "Edit Questionnaire" : "Create Questionnaire"
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .scrollDismissesKeyboard(.interactively)
        // Modern haptics without UIKit
        .sensoryFeedback(
            saveSucceeded ? .success : .error,
            trigger: saveFeedbackKey
        )
        .onAppear {
            loadQuestionnaireForEditing()
            // Auto-focus the first field on load
            DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Duration.medium) {
                focusedField = .title
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            // Auto-focus the currently selected question when entering questions section
            if let newValue = newValue, newValue.isQuestionField {
                if case .question(let index) = newValue {
                    selectedQuestionIndex = index
                }
            }
        }
        .onChange(of: selectedQuestionIndex) { oldValue, newValue in
            // When the selected question changes in carousel (scroll/swipe), auto-focus it if we're in question mode
            if let currentField = focusedField, currentField.isQuestionField {
                focusedField = .question(newValue)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isValid {
                    Button(action: saveQuestionnaire) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityLabel("Save Questionnaire")
                    .accessibilityHint(
                        "Saves your questionnaire and closes this screen"
                    )
                } else {
                    Button(action: saveQuestionnaire) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    .accessibilityLabel("Save Questionnaire")
                    .accessibilityHint("Complete all fields to enable Save")
                }
            }

            // Keyboard toolbar - removed navigation, only show Done button
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }

    }

    private func saveQuestionnaire() {
        // Clean up empty questions
        let cleanedQuestions =
            questions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let currentQuestionnaire = questionnaireBinding.wrappedValue

        // Guard on validity with subtle haptic
        guard isValid else {
            saveSucceeded = false
            saveFeedbackKey &+= 1
            // Direct focus to the first missing field
            if currentQuestionnaire.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .title
            } else if currentQuestionnaire.information.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .information
            } else if currentQuestionnaire.instructions.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .instructions
            } else if currentQuestionnaire.author.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .author
            } else if cleanedQuestions.isEmpty {
                focusedField = .question(0)
                // Ensure there's at least one empty question to focus on
                if questions.isEmpty {
                    questions = [""]
                }
            }
            return
        }

        // Trim main fields before saving
        currentQuestionnaire.title = currentQuestionnaire.title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        currentQuestionnaire.information = currentQuestionnaire.information
            .trimmingCharacters(in: .whitespacesAndNewlines)
        currentQuestionnaire.instructions = currentQuestionnaire.instructions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        currentQuestionnaire.author = currentQuestionnaire.author
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        currentQuestionnaire.questions = cleanedQuestions
        currentQuestionnaire.creationDate = Date.now

        // Save to SwiftData
        if !isEditing {
            modelContext.insert(currentQuestionnaire)
        } 

        do {
            try modelContext.save()
            saveSucceeded = true
            saveFeedbackKey &+= 1

            if isEditing {
                // For editing, just dismiss back to detail view
                dismiss()
            } else {
                // For new questionnaires, navigate to detail and replace the create screen
                navigate(to: currentQuestionnaire, using: navigationPath, replaceCurrent: true)
            }
        } catch {
            print("Failed to save questionnaire: \(error)")
        }
    }

    private func loadQuestionnaireForEditing() {
        guard let editingQuestionnaire = editingQuestionnaire else { return }

        // Load the questions from the existing questionnaire
        questions =
            editingQuestionnaire.questions.isEmpty
            ? [""] : editingQuestionnaire.questions
    }

}

#Preview {
    NavigationStack {
        CreateQuestionnaireView()
    }
    .modelContainer(for: Questionnaire.self, inMemory: true)
}

#Preview("Editing Questionnaire") {
    let container = try! ModelContainer(
        for: Questionnaire.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let sampleQuestionnaire = Questionnaire(
        title: "Work From Home Survey",
        information: "A survey about remote work preferences and productivity",
        instructions:
            "Please answer all questions honestly based on your experience",
        author: "HR Team",
        questions: [
            "Do you prefer working from home or in the office?",
            "How productive are you when working remotely?",
            "What tools help you stay connected with your team?",
        ]
    )

    context.insert(sampleQuestionnaire)
    try! context.save()

    return NavigationStack {
        CreateQuestionnaireView(editingQuestionnaire: sampleQuestionnaire)
    }
    .modelContainer(container)
}
