//
//  CreateQuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI
import SwiftData

struct CreateQuestionnaireView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionnaire = Questionnaire()
    @State private var questions: [String] = [""]
    @State private var showingColorPicker = false
    @State private var selectedColorType: ColorType = .start
    @FocusState private var focusedField: FocusedField?
    
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
        let hasTitle = !questionnaire.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasInformation = !questionnaire.information.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasInstructions = !questionnaire.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAuthor = !questionnaire.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasValidQuestions = questions.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return hasTitle && hasInformation && hasInstructions && hasAuthor && hasValidQuestions
    }
    
    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: .none)
            
            ScrollView {
                VStack(spacing: 24) {
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
                    QuestionsSection(
                        questions: $questions,
                        focusedField: $focusedField
                    )
                    
                    // Bottom padding for floating button
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .safeAreaInset(edge: .bottom) {
                // Floating Save Button
                GlassActionButton(
                    title: "Create Questionnaire",
                    icon: "plus.circle.fill",
                    isEnabled: isValid,
                    tintColor: .blue,
                    action: saveQuestionnaire
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                //.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 0))
            }
        }
        .navigationTitle("Create Questionnaire")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onTapGesture {
            focusedField = nil
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(
                selectedColor: selectedColorType == .start ? 
                    Binding(
                        get: { questionnaire.startColor },
                        set: { questionnaire.startColor = $0 }
                    ) :
                    Binding(
                        get: { questionnaire.endColor },
                        set: { questionnaire.endColor = $0 }
                    ),
                colorType: selectedColorType
            )
            .presentationDetents([.height(400)])
        }
    }
    
    private func saveQuestionnaire() {
        // Clean up empty questions
        let cleanedQuestions = questions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        questionnaire.questions = cleanedQuestions
        questionnaire.creationDate = Date.now
        
        // Save to SwiftData
        modelContext.insert(questionnaire)
        
        do {
            try modelContext.save()
            // Navigate back or to the questionnaire
            dismiss()
        } catch {
            print("Failed to save questionnaire: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        CreateQuestionnaireView()
    }
    .modelContainer(for: Questionnaire.self, inMemory: true)
}
