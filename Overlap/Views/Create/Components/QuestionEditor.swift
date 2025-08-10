//
//  QuestionEditor.swift
//  Overlap
//
//  A unified question editor that supports both carousel and list modes.
//

import SwiftUI

struct QuestionEditor: View {
    @Binding var questions: [String]
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?
    @Binding var selectedIndex: Int
    
    enum EditorMode {
        case carousel
        case list
    }
    
    // Remember user's preferred editor mode across launches
    @AppStorage("useListEditor") private var useListEditor: Bool = false
    
    // Computed mode based on user preference
    private var mode: EditorMode {
        useListEditor ? .list : .carousel
    }
    
    // Carousel-specific state
    @State private var selection: Int = 0
    @State private var newlyAddedIndex: Int? = nil
    @State private var addFeedbackKey: Int = 0
    
    // Pull-to-add now handled by TabView selection changes
    
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
            // Section header
            SectionHeader(
                title: "Questions",
                icon: "questionmark.bubble.fill"
            )
            
            // Controls row: picker on left, add button on right
            HStack(spacing: Tokens.Spacing.m) {
                Picker("Editor", selection: $useListEditor) {
                    Image(systemName: "rectangle.stack")
                        .font(.title2)
                        .tag(false)
                        .accessibilityLabel("Carousel")
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .tag(true)
                        .accessibilityLabel("List")
                }
                .pickerStyle(.segmented)
                .glassEffect(.clear.interactive())
                .controlSize(.large)
                .frame(height: Tokens.Size.buttonCompact)
                .accessibilityLabel("Question editor style")
                .accessibilityValue(useListEditor ? "List" : "Carousel")
                
                Spacer()
                
                // Add button
                Button(action: addQuestion) {
                    Image(systemName: "plus")
                        .font(.system(size: Tokens.FontSize.extraLarge * 0.375, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: Tokens.Size.buttonCompact, height: Tokens.Size.buttonCompact)
                        .background(
                            Circle()
                                .fill(.blue)
                                .glassEffect(.regular.interactive())
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Question")
            }
            .padding(.horizontal, Tokens.Spacing.l)
            .padding(.vertical, Tokens.Spacing.s)
            
            // Editor content based on mode
            Group {
                switch mode {
                case .carousel:
                    carouselEditor
                        .frame(height: Tokens.Size.cardMaxHeight + Tokens.Spacing.quadXL)  // Height constraint only for carousel
                    pageIndicators
                case .list:
                    listEditor
                }
            }
            .id(useListEditor)  // force layout refresh on mode change
            .transition(.opacity)
        }
        .sensoryFeedback(.selection, trigger: useListEditor)
        // Clamp focus to valid indices if the underlying array changed
        .onChange(of: focusedField) { _, newValue in
            if case .question(let idx) = newValue {
                let maxIndex = max(questions.count - 1, 0)
                if idx > maxIndex {
                    focusedField = .question(maxIndex)
                }
            }
        }
    }
    
    // MARK: - Carousel Mode
    
    private var carouselEditor: some View {
        ZStack {
            TabView(selection: $selection) {
                ForEach(questions.indices, id: \.self) { index in
                    // Create a safe binding that checks bounds
                    let safeBinding = Binding<String>(
                        get: {
                            // Ensure index is still valid
                            guard index < questions.count else { return "" }
                            return questions[index]
                        },
                        set: { newValue in
                            // Ensure index is still valid before setting
                            guard index < questions.count else { return }
                            questions[index] = newValue
                        }
                    )
                    
                    QuestionEditCard(
                        question: safeBinding,
                        number: index + 1,
                        canRemove: questions.count > 1,
                        onRemove: { removeQuestion(at: index) },
                        isNew: newlyAddedIndex == index,
                        onNewAnimationComplete: { newlyAddedIndex = nil },
                        focusedField: $focusedField,
                        questionIndex: index
                    )
                    .frame(height: Tokens.Size.cardMaxHeight - Tokens.Spacing.quadXL)  // Card height with some padding
                    .tag(index)
                    .padding(.horizontal, Tokens.Spacing.l)
                    .opacity(Tokens.Opacity.prominent)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .sensoryFeedback(.success, trigger: addFeedbackKey)
            .onChange(of: selection) { _, newValue in
                updateSelectedIndex(newValue)
                // Clear focus when moving to a different card to prevent pull-to-add issues
                focusedField = nil
                
                // Check if user is trying to go beyond the last card
                if newValue >= questions.count {
                                    // User tried to go beyond the last card - add a new question
                DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Duration.fast) {
                    addQuestion()
                    // Reset selection to the new last card
                    selection = questions.count - 1
                }
                }
            }
            .onChange(of: selectedIndex) { _, newValue in
                updateSelection(newValue)
            }
            .onChange(of: questions.count) { oldCount, newCount in
                // If questions were removed and our selection is now invalid, fix it
                if selection >= newCount && newCount > 0 {
                    selection = newCount - 1
                    selectedIndex = newCount - 1
                }
            }
            // No more drag offset needed
        }
    }
    
    private var pageIndicators: some View {
        HStack(spacing: Tokens.Spacing.xs) {
            ForEach(0..<questions.count, id: \.self) { idx in
                Circle()
                    .fill(idx == min(selection, questions.count - 1) ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: Tokens.Spacing.xs, height: Tokens.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Tokens.Spacing.s)
    }
    
        // Pull-to-add is now handled by detecting when selection goes beyond the last card
    
    // MARK: - List Mode
    
    private var listEditor: some View {
        VStack(spacing: Tokens.Spacing.s) {
            ForEach(questions.indices, id: \.self) { index in
                // Create a safe binding that checks bounds
                let safeBinding = Binding<String>(
                    get: {
                        // Ensure index is still valid
                        guard index < questions.count else { return "" }
                        return questions[index]
                    },
                    set: { newValue in
                        // Ensure index is still valid before setting
                        guard index < questions.count else { return }
                        questions[index] = newValue
                    }
                )
                
                HStack(spacing: Tokens.Spacing.m) {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: Tokens.Size.iconSmall - 10)
                    
                    TextField(
                        "Question \(index + 1)",
                        text: safeBinding,
                        axis: .vertical
                    )
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(1...4)
                    .submitLabel(index == questions.count - 1 ? .done : .next)
                    .focused($focusedField, equals: .question(index))
                    .onSubmit {
                        handleSubmit(at: index)
                    }
                    
                    // Delete button for each row
                    if questions.count > 1 {
                        Button(action: { removeQuestion(at: index) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, Tokens.Spacing.m)
                .padding(.horizontal, Tokens.Spacing.l)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: Tokens.Radius.m))
                .onAppear {
                    if newlyAddedIndex == index {
                                    // Clear the newly added state after a brief moment in list mode
            DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Duration.medium) {
                if newlyAddedIndex == index {
                    newlyAddedIndex = nil
                }
            }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: Tokens.Scale.pressed).combined(with: .opacity),
                    removal: .scale(scale: Tokens.Scale.pressed).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, Tokens.Spacing.l)
        .opacity(Tokens.Opacity.prominent)
    }
    
    // MARK: - Shared Logic
    
    private func addQuestion() {
        questions.append("")
        let newIndex = questions.count - 1
        
        if mode == .carousel {
            // Animate to the new card with a bouncy spring animation
            withAnimation(.spring(response: Tokens.Spring.response, dampingFraction: 0.7)) {
                selection = newIndex
                selectedIndex = newIndex
            }
            addFeedbackKey &+= 1
            newlyAddedIndex = newIndex
            
            // Set focus after card animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Duration.slow + Tokens.Duration.medium) {
                focusedField = .question(newIndex)
            }
        } else {
            selectedIndex = newIndex
            newlyAddedIndex = newIndex
            
            // Set focus immediately for list mode
            focusedField = .question(newIndex)
        }
    }

    // addQuestionWithAnimation removed: addQuestion handles animations for both modes
    
    private func removeQuestion(at index: Int) {
        // CRITICAL: Prevent deletion if it would leave us with no questions
        if questions.count <= 1 {
            return // Exit immediately, do not proceed with deletion
        }
        
        guard index < questions.count, index >= 0 else { return }
        
        // Store current state before any changes
        let currentMode = mode
        let currentSelection = (currentMode == .carousel ? selection : selectedIndex)
        
        // Clear focus state immediately (SwiftUI-only)
        focusedField = nil
        
        // Use a transaction to batch updates and prevent intermediate states
        var newSelectionAfterRemoval = currentSelection
        withAnimation(.easeInOut(duration: Tokens.Duration.fast)) {
            // Remove the question
            questions.remove(at: index)
            
            // Calculate new selection immediately
            if currentSelection >= questions.count {
                // If we were at or beyond the deleted item, go to the new last item
                newSelectionAfterRemoval = max(0, questions.count - 1)
            } else if currentSelection > index {
                // If we were after the deleted item, shift back by one
                newSelectionAfterRemoval = max(0, currentSelection - 1)
            }
            // Ensure selection is valid
            newSelectionAfterRemoval = min(max(0, newSelectionAfterRemoval), max(0, questions.count - 1))
            
            // Update selection based on mode
            if currentMode == .carousel {
                selection = newSelectionAfterRemoval
            }
            selectedIndex = newSelectionAfterRemoval
        }
        
        // Only set focus after ensuring the UI has updated
        DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Duration.medium) {
            // Double-check that our new selection is still valid
            if newSelectionAfterRemoval < questions.count && newSelectionAfterRemoval >= 0 && !questions.isEmpty {
                focusedField = .question(newSelectionAfterRemoval)
            }
        }
    }
    

    
    private func handleSubmit(at index: Int) {
        // Ensure index is still valid
        guard index < questions.count else { return }
        
        if index == questions.count - 1 {
            addQuestion()
        } else if index + 1 < questions.count {
            focusedField = .question(index + 1)
        }
    }
    
    private func updateSelectedIndex(_ newValue: Int) {
        let safeSelection = min(max(newValue, 0), max(questions.count - 1, 0))
        if safeSelection < questions.count && safeSelection != selectedIndex {
            selectedIndex = safeSelection
        }
    }
    
    private func updateSelection(_ newValue: Int) {
        let safeIndex = min(max(newValue, 0), max(questions.count - 1, 0))
        if safeIndex != selection && safeIndex < questions.count {
            selection = safeIndex
        }
    }
}

// PullToAddIndicator removed - no longer needed

#Preview("Question Editor") {
    struct Wrapper: View {
        @State var questions = [
            "What's your ideal vacation?",
            "Do you prefer mornings or nights?",
            "Dogs, cats, or both?"
        ]
        @FocusState private var focusedField: CreateQuestionnaireView.FocusedField?
        @State private var selectedIndex = 0
        
        var body: some View {
            QuestionEditor(
                questions: $questions,
                focusedField: $focusedField,
                selectedIndex: $selectedIndex
            )
            .frame(height: Tokens.Size.cardMaxHeight + Tokens.Spacing.huge)
            .padding()
            .background(BlobBackgroundView())
        }
    }
    return Wrapper()
}
