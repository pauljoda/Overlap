//
//  QuestionEditorCarousel.swift
//  Overlap
//
//  A card-based, swipeable question editor with a trailing “add” card.
//

import SwiftUI

struct QuestionEditorCarousel: View {
    @Binding var questions: [String]
    @FocusState.Binding var focusedField: CreateQuestionnaireView.FocusedField?

    @State private var selection: Int = 0
    @State private var didAutoAddFromTrailingCard = false // legacy; no longer used
    @State private var pendingAddProgress: Double = 0
    @State private var isPendingAdd: Bool = false
    @State private var pendingWorkItem: DispatchWorkItem?
    @State private var newlyAddedIndex: Int? = nil
    @State private var addFeedbackKey: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
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

            TabView(selection: $selection) {
                ForEach(questions.indices, id: \.self) { index in
                    QuestionEditCard(
                        question: $questions[index],
                        number: index + 1,
                        canRemove: questions.count > 1,
                        onRemove: { removeQuestion(at: index) },
                        isNew: newlyAddedIndex == index,
                        onNewAnimationComplete: { newlyAddedIndex = nil }
                    )
                    .tag(index)
                    .padding(.horizontal, Tokens.Spacing.l)
                    .opacity(0.8)
                }

                // Trailing add card – swiping here auto-adds a new question
                AddMoreQuestionCard(progress: pendingAddProgress)
                    .tag(questions.count)
                    .padding(.horizontal, Tokens.Spacing.l)
                    // Add is now handled by selection change below to ensure snapping back
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 460)
            .sensoryFeedback(.success, trigger: addFeedbackKey)
            .onChange(of: selection) { _, newValue in
                // Clamp selection to valid range first to avoid SwiftUI assertion
                let maxIndex = max(questions.count - 1, 0)
                if questions.isEmpty {
                    selection = 0
                    cancelPendingAdd()
                    return
                }
                if newValue > questions.count { // can happen after deletions
                    selection = maxIndex
                    cancelPendingAdd()
                    return
                }

                // If user swiped to the trailing add card, insert and snap to the new card
                if newValue == questions.count {
                    beginPendingAdd()
                } else {
                    cancelPendingAdd()
                }
            }

            // Page indicators including a trailing add indicator
            HStack(spacing: 6) {
                ForEach(0..<questions.count, id: \.self) { idx in
                    Circle()
                        .fill(idx == min(selection, questions.count - 1) ? Color.primary : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                }
                Image(systemName: "plus")
                    .font(.system(size: 8))
                    .foregroundColor(selection == questions.count ? .blue : .secondary.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Tokens.Spacing.s)
        }
    }

    private func addQuestion() {
        questions.append("")
        selection = max(questions.count - 1, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .question(selection)
        }
    }

    private func addQuestionFromSelection() {
        questions.append("")
        let newIndex = max(questions.count - 1, 0)
        DispatchQueue.main.async {
            withAnimation {
                selection = newIndex
            }
            focusedField = .question(newIndex)
            addFeedbackKey &+= 1
            newlyAddedIndex = newIndex
        }
    }

    private func beginPendingAdd() {
        cancelPendingAdd()
        isPendingAdd = true
        pendingAddProgress = 0
        let work = DispatchWorkItem {
            addQuestionFromSelection()
            withAnimation(.easeOut(duration: Tokens.Duration.fast)) { pendingAddProgress = 0 }
            isPendingAdd = false
        }
        pendingWorkItem = work
        // Animate progress like pull-to-refresh
        withAnimation(.linear(duration: 0.35)) { pendingAddProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func cancelPendingAdd() {
        if isPendingAdd {
            pendingWorkItem?.cancel()
            pendingWorkItem = nil
            isPendingAdd = false
            withAnimation(.easeOut(duration: Tokens.Duration.fast)) { pendingAddProgress = 0 }
        }
    }

    private func removeQuestion(at index: Int) {
        guard questions.count > 1, index < questions.count else { return }
        questions.remove(at: index)
        var newSelection = selection
        if newSelection > index { newSelection -= 1 }
        newSelection = min(newSelection, max(questions.count - 1, 0))
        selection = newSelection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .question(selection)
        }
    }
}

private struct QuestionEditCard: View {
    @Binding var question: String
    let number: Int
    let canRemove: Bool
    let onRemove: () -> Void
    let isNew: Bool
    let onNewAnimationComplete: () -> Void
    @FocusState private var isFocused: Bool
    @State private var appearScale: CGFloat = 1.0
    @State private var appearOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Outer subtle ring similar to the answering card
            RoundedRectangle(cornerRadius: 44)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color(.separator).opacity(0.1), .clear]),
                        center: .center, startRadius: 0, endRadius: 220
                    )
                )
                .opacity(0.3)
                .scaleEffect(1.03)

            // Main card with concentric borders
            RoundedRectangle(cornerRadius: 44)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 44 - 8/2)
                        .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                        .padding(8/2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)
                .opacity(0.85)

            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                HStack {
                    Text("Question \(number)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    if canRemove {
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .accessibilityLabel("Remove question \(number)")
                    }
                }

                Spacer()

                // Centered large editor to resemble answering card text
                TextField("Enter your question", text: $question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .padding(.horizontal, Tokens.Spacing.xl)

                Spacer()
            }
            .padding(24)
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
            .onAppear {
                guard isNew else { return }
                appearScale = 0.95
                appearOpacity = 0
                withAnimation(.spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping)) {
                    appearScale = 1
                    appearOpacity = 1
                }
                // Clear new state after the animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    onNewAnimationComplete()
                }
            }
        }
    }
}

private struct AddMoreQuestionCard: View {
    let progress: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Tokens.Radius.xl)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.Radius.xl)
                        .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
                .largeGlassCard()
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

            VStack(spacing: Tokens.Spacing.m) {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 6)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 40, height: 40)
                        .animation(.linear(duration: 0.01), value: progress)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                Text("Swipe to add a question")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview("Carousel – 3 Questions") {
    struct Wrapper: View {
        @State var questions = [
            "What’s your ideal vacation?",
            "Do you prefer mornings or nights?",
            "Dogs, cats, or both?"
        ]
        @FocusState private var focusedField: CreateQuestionnaireView.FocusedField?
        var body: some View {
            VStack {
                QuestionEditorCarousel(questions: $questions, focusedField: $focusedField)
            }
            .padding()
            .background(BlobBackgroundView())
        }
    }
    return Wrapper()
}

