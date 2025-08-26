//
//  CreateQuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SharingGRDB
import SwiftUI

struct CreateQuestionnaireView: View {
    @Dependency(\.defaultDatabase) var database
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
                set: { _ in }  // Read-only binding for editing mode
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
        let hasInformation = !currentQuestionnaire.description
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
                .frame(
                    height: Tokens.Size.cardMaxHeight + Tokens.Spacing.quadXL
                )
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
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Tokens.Duration.medium
            ) {
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

        var currentQuestionnaire = questionnaireBinding.wrappedValue

        // Guard on validity with subtle haptic
        guard isValid else {
            saveSucceeded = false
            saveFeedbackKey &+= 1
            // Direct focus to the first missing field
            if currentQuestionnaire.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .title
            } else if currentQuestionnaire.description.trimmingCharacters(
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
        currentQuestionnaire.description = currentQuestionnaire.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
        currentQuestionnaire.instructions = currentQuestionnaire.instructions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        currentQuestionnaire.author = currentQuestionnaire.author
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        currentQuestionnaire.questions = cleanedQuestions
        currentQuestionnaire.creationDate = Date.now

        // Save to database
        withErrorReporting {
            try database.write { db in
                if !isEditing {
                    try Questionnaire.insert {
                        currentQuestionnaire
                    }
                    .execute(db)
                } else {
                    try Questionnaire.update(currentQuestionnaire).execute(db)
                }
            }
            
            saveSucceeded = true
            saveFeedbackKey &+= 1
            
            if !isEditing {
                // For new questionnaires, navigate to detail and replace the create screen
                navigate(
                    to: currentQuestionnaire,
                    using: navigationPath,
                    replaceCurrent: true
                )
            } else {
                dismiss()
            }
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

#Preview("Current - Combined") {
    let _ = try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
    }
    
    NavigationStack {
        CreateQuestionnaireView()
    }
}

#Preview("Future - GRDB Only") {
    let _ = setupGRDBPreview()
    
    NavigationStack {
        CreateQuestionnaireView()
    }
}
