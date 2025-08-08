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
    @State private var showingColorPicker = false
    @State private var selectedColorType: ColorType = .start
    @FocusState private var focusedField: FocusedField?
    // Remember user's preferred editor mode across launches
    @AppStorage("useListEditor") private var useListEditor: Bool = false
    // Feedback triggers for modern SwiftUI sensory feedback
    @State private var saveFeedbackKey: Int = 0
    @State private var saveSucceeded: Bool = false
    
    init(editingQuestionnaire: Questionnaire? = nil) {
        self.editingQuestionnaire = editingQuestionnaire
    }
    
    enum ColorType {
        case start, end
    }

    enum FocusedField: Hashable {
        case title
        case information
        case instructions
        case author
        case question(Int)
    }

    private var isValid: Bool {
        let hasTitle = !questionnaire.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let hasInformation = !questionnaire.information.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let hasInstructions = !questionnaire.instructions.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let hasAuthor = !questionnaire.author.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let hasValidQuestions = questions.contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return hasTitle && hasInformation && hasInstructions && hasAuthor
            && hasValidQuestions
    }

    // Binding to the currently selected gradient color (start or end)
    private var selectedColorBinding: Binding<Color> {
        Binding(
            get: {
                selectedColorType == .start
                    ? questionnaire.startColor : questionnaire.endColor
            },
            set: { newValue in
                if selectedColorType == .start {
                    questionnaire.startColor = newValue
                } else {
                    questionnaire.endColor = newValue
                }
            }
        )
    }

    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xxl) {
                // Header
                CreateQuestionnaireHeader(questionnaire: questionnaire)

                // Basic Information Section
                BasicInformationSection(
                    questionnaire: $questionnaire,
                    focusedField: $focusedField
                )

                // Visual Customization Section
                VisualCustomizationSection(
                    questionnaire: $questionnaire,
                    showingColorPicker: $showingColorPicker,
                    selectedColorType: $selectedColorType
                )

                // Questions Section
                VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
                    HStack(
                        alignment: .firstTextBaseline,
                        spacing: Tokens.Spacing.l
                    ) {
                        SectionHeader(
                            title: "Questions",
                            icon: "questionmark.bubble.fill"
                        )
                        Spacer(minLength: Tokens.Spacing.l)
                        Picker("Editor", selection: $useListEditor) {
                            Image(systemName: "square.on.square")
                                .font(.title2)
                                .tag(false)
                                .accessibilityLabel("Carousel")
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .tag(true)
                                .accessibilityLabel("List")
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.large)
                        .accessibilityLabel("Question editor style")
                        .accessibilityValue(useListEditor ? "List" : "Carousel")
                    }
                    .padding(.vertical, Tokens.Spacing.s)

                    Group {
                        if useListEditor {
                            QuestionListEditor(
                                questions: $questions,
                                focusedField: $focusedField
                            )
                            .frame(minHeight: 320, maxHeight: 520)
                            .id(useListEditor)  // force layout refresh on mode change
                        } else {
                            QuestionEditorCarousel(
                                questions: $questions,
                                focusedField: $focusedField
                            )
                        }
                    }
                    .transition(.opacity)
                }

            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.xl)
        }
        .navigationTitle(isEditing ? "Edit Questionnaire" : "Create Questionnaire")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .scrollDismissesKeyboard(.interactively)
        // Modern haptics without UIKit
        .sensoryFeedback(.selection, trigger: useListEditor)
        .sensoryFeedback(
            saveSucceeded ? .success : .error,
            trigger: saveFeedbackKey
        )
        .onAppear {
            loadQuestionnaireForEditing()
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
                    .accessibilityHint("Saves your questionnaire and closes this screen")
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
        }
        .onTapGesture {
            focusedField = nil
        }
        .animation(.easeInOut(duration: 0.2), value: useListEditor)
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(
                selectedColor: selectedColorBinding,
                colorType: selectedColorType
            )
            .presentationDetents([.height(400)])
        }
    }

    private func saveQuestionnaire() {
        // Clean up empty questions
        let cleanedQuestions =
            questions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Guard on validity with subtle haptic
        guard isValid else {
            saveSucceeded = false
            saveFeedbackKey &+= 1
            // Direct focus to the first missing field
            if questionnaire.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .title
            } else if questionnaire.information.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .information
            } else if questionnaire.instructions.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .instructions
            } else if questionnaire.author.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                focusedField = .author
            } else if cleanedQuestions.isEmpty {
                focusedField = .question(0)
            }
            return
        }

        // Trim main fields before saving
        questionnaire.title = questionnaire.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        questionnaire.information = questionnaire.information
            .trimmingCharacters(in: .whitespacesAndNewlines)
        questionnaire.instructions = questionnaire.instructions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        questionnaire.author = questionnaire.author.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        questionnaire.questions = cleanedQuestions
        questionnaire.creationDate = Date.now
        
        // Save to SwiftData
        if isEditing {
            // For editing, we already have the questionnaire in the context
            // Just update the existing one
        } else {
            // For new questionnaires, insert into context
            modelContext.insert(questionnaire)
        }
        
        do {
            try modelContext.save()
            saveSucceeded = true
            saveFeedbackKey &+= 1
            
            if isEditing {
                // For editing, just dismiss back to detail view
                dismiss()
            } else {
                // For new questionnaires, navigate to detail
                navigate(to: questionnaire, using: navigationPath)
            }
        } catch {
            print("Failed to save questionnaire: \(error)")
        }
    }
    
    private func loadQuestionnaireForEditing() {
        guard let editingQuestionnaire = editingQuestionnaire else { return }
        
        // Load the existing questionnaire data
        questionnaire = editingQuestionnaire
        questions = editingQuestionnaire.questions.isEmpty ? [""] : editingQuestionnaire.questions
    }
    }


#Preview {
    NavigationStack {
        CreateQuestionnaireView()
    }
    .modelContainer(for: Questionnaire.self, inMemory: true)
}
