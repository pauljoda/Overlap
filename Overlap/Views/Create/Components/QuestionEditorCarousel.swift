//
//  QuestionEditorCarousel.swift
//  Overlap
//
//  A card-based, swipeable question editor with a trailing "add" card.
//

import SwiftUI

struct QuestionEditorCarousel: View {
    @Binding var questions: [String]
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?
    @Binding var selectedIndex: Int

    @State private var selection: Int = 0
    @State private var newlyAddedIndex: Int? = nil
    @State private var addFeedbackKey: Int = 0
    
    // Pull-to-add gesture states
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var pullProgress: Double = 0
    @State private var canTriggerAdd: Bool = false
    
    private let pullThreshold: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            addQuestionButton
            carouselWithGesture
            pageIndicators
        }
    }
    
    private var addQuestionButton: some View {
        HStack {
            Spacer()
            Button(action: addQuestion) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .actionGlassButton(tint: .blue)
            .accessibilityLabel("Add Question")
        }
    }
    
    private var carouselWithGesture: some View {
        ZStack {
            questionCarousel
            pullToAddIndicator
        }
    }
    
    private var questionCarousel: some View {
        TabView(selection: $selection) {
            ForEach(questions.indices, id: \.self) { index in
                QuestionEditCard(
                    question: $questions[index],
                    number: index + 1,
                    canRemove: questions.count > 1,
                    onRemove: { removeQuestion(at: index) },
                    isNew: newlyAddedIndex == index,
                    onNewAnimationComplete: { newlyAddedIndex = nil },
                    focusedField: $focusedField,
                    questionIndex: index
                )
                .tag(index)
                .padding(.horizontal, Tokens.Spacing.l)
                .opacity(0.8)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 460)
        .sensoryFeedback(.success, trigger: addFeedbackKey)
        .onChange(of: selection) { _, newValue in
            if newValue < questions.count {
                selectedIndex = newValue
            }
        }
        .onChange(of: selectedIndex) { _, newValue in
            if newValue != selection && newValue < questions.count {
                selection = newValue
            }
        }
        .offset(x: dragOffset)
        .simultaneousGesture(pullToAddGesture)
    }
    
    private var pullToAddGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged(handleDragChanged)
            .onEnded(handleDragEnded)
    }
    
    @ViewBuilder
    private var pullToAddIndicator: some View {
        if isDragging && pullProgress > 0 {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    PullToAddIndicator(progress: pullProgress, canTrigger: canTriggerAdd)
                        .offset(x: -40) // Position it more visibly
                        .zIndex(1) // Ensure it's above other content
                }
                Spacer()
            }
            .allowsHitTesting(false) // Don't interfere with gestures
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pullProgress)
        }
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 6) {
            ForEach(0..<questions.count, id: \.self) { idx in
                Circle()
                    .fill(idx == min(selection, questions.count - 1) ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Tokens.Spacing.s)
    }

    
    private func handleDragChanged(_ value: DragGesture.Value) {
        // Only respond to horizontal drag when on the last card
        guard selection == questions.count - 1 else { 
            // Reset state if not on last card
            if isDragging {
                withAnimation(.easeOut(duration: 0.2)) {
                    isDragging = false
                    pullProgress = 0
                    canTriggerAdd = false
                    dragOffset = 0
                }
            }
            return 
        }
        
        let translation = value.translation.width
        
        // Only allow leftward drag (negative translation)
        if translation < 0 {
            isDragging = true
            let dragDistance = abs(translation)
            dragOffset = max(-pullThreshold, translation)
            
            // Calculate progress based on drag distance
            pullProgress = min(1.0, dragDistance / pullThreshold)
            
            // Determine if we've dragged far enough to trigger add
            let wasCanTrigger = canTriggerAdd
            canTriggerAdd = dragDistance >= pullThreshold
            
            // Provide haptic feedback when threshold is reached for the first time
            if canTriggerAdd && !wasCanTrigger {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        } else {
            // Reset state if dragging right or not dragging left enough
            withAnimation(.easeOut(duration: 0.2)) {
                isDragging = false
                pullProgress = 0
                canTriggerAdd = false
                dragOffset = 0
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard isDragging else { return }
        
        if canTriggerAdd {
            // Add new question
            addQuestionWithAnimation()
        }
        
        // Reset state
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
            pullProgress = 0
        }
        
        isDragging = false
        canTriggerAdd = false
    }

    private func addQuestion() {
        questions.append("")
        let newIndex = max(questions.count - 1, 0)
        selection = newIndex
        selectedIndex = newIndex
        // Set focus immediately without delay to prevent keyboard dismissal
        focusedField = .question(newIndex)
    }

    private func addQuestionWithAnimation() {
        questions.append("")
        let newIndex = max(questions.count - 1, 0)
        // Set focus immediately to maintain keyboard
        focusedField = .question(newIndex)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selection = newIndex
            selectedIndex = newIndex
        }
        
        addFeedbackKey &+= 1
        newlyAddedIndex = newIndex
    }

    private func removeQuestion(at index: Int) {
        guard questions.count > 1, index < questions.count else { return }
        questions.remove(at: index)
        var newSelection = selection
        if newSelection > index { newSelection -= 1 }
        newSelection = min(newSelection, max(questions.count - 1, 0))
        selection = newSelection
        selectedIndex = newSelection
        // Set focus immediately to maintain keyboard
        focusedField = .question(newSelection)
    }
}

private struct PullToAddIndicator: View {
    let progress: Double
    let canTrigger: Bool
    
    var body: some View {
        // Simple green plus icon
        Image(systemName: "plus")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.green)
            .scaleEffect(0.8 + (progress * 0.6)) // Scale from 0.8 to 1.4
            .opacity(0.4 + (progress * 0.6)) // Fade in as progress increases
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: progress)
    }
}

#Preview("Carousel – 3 Questions") {
    struct Wrapper: View {
        @State var questions = [
            "What's your ideal vacation?",
            "Do you prefer mornings or nights?",
            "Dogs, cats, or both?"
        ]
        @FocusState private var focusedField: CreateQuestionnaireView.FocusedField?
        @State private var selectedIndex = 0
        var body: some View {
            VStack {
                QuestionEditorCarousel(
                    questions: $questions, 
                    focusedField: $focusedField,
                    selectedIndex: $selectedIndex
                )
            }
            .padding()
            .background(BlobBackgroundView())
        }
    }
    return Wrapper()
}
