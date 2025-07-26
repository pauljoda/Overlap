//
//  CardView.swift
//  Overlay
//
//  Created by Paul Davis on 7/12/25.
//


import SwiftUI

struct CardView: View {
    // Paramaters
    /// The question to display on the card
    let question: Question
    /// Callback to handle the answer selection
    var onSwipe: (Answer) -> Void

    // State Variables
    /// The current offset of the card during drag
    @State private var offset = CGSize.zero
    /// Flag to indicate if the card has been answered
    @State private var isAnswered = false
    /// The selected answer after swiping
    @State private var selectedAnswer: AnswerType?
    
    // MARK: - Configuration Variables
    ///Configuration for various thresholds and visual styles
    private let dragThreshold: CGFloat = 100
    /// Configuration for swipe thresholds and animations
    private let swipeThresholdMultiplier: CGFloat = 0.25 // 25% of screen width
    /// Velocity threshold for swipe detection
    private let velocityThreshold: CGFloat = 500
    /// Configuration for exit distance multiplier
    private let velocityMultiplier: CGFloat = 0.3
    /// Multiplier for how far the card exits the screen
    private let exitDistanceMultiplier: CGFloat = 1.5
    
    // Visual Configuration
    /// Configuration for card appearance
    private let cardCornerRadius: CGFloat = 20
    /// Configuration for card shadow
    private let cardPadding: CGFloat = 40 // 20 on each side
    /// Configuration for card border
    private let borderWidth: CGFloat = 1
    /// Shadow configuration
    private let shadowRadius: CGFloat = 10
    /// Shadow offset values
    private let shadowOffsetX: CGFloat = 0
    /// Shadow offset values
    private let shadowOffsetY: CGFloat = 4
    /// Shadow opacity
    private let shadowOpacity: Double = 0.1
    
    // Color Configuration
    ///Configuration for card colors and opacity
    private let colorOpacity: Double = 0.8
    /// Threshold for when to fade help text
    private let helpTextFadeThreshold: CGFloat = 0.3
    
    // Animation Configuration
    /// Configuration for animation effects
    private let rotationDivisor: CGFloat = 10
    /// Configuration for scaling effects
    private let scaleDivisor: CGFloat = 0.05
    /// Configuration for exit animation duration
    private let scaleEffectMultiplier: CGFloat = 0.1
    /// Configuration for exit animation duration
    private let exitAnimationDuration: Double = 0.6
    /// Delay before calling the swipe callback
    private let delayBeforeCallback: Double = 0.5
    /// Spring animation configuration
    private let springResponse: Double = 0.5
    /// Spring damping configuration
    private let springDamping: Double = 0.6
    
    // Answers Layout Configuration
    /// Configuration for layout spacing
    private let questionHorizontalPadding: CGFloat = 30
    /// Configuration for help text layout
    private let helpTextSpacing: CGFloat = 30
    /// Configuration for help text icon spacing
    private let helpTextIconSpacing: CGFloat = 8
    /// Configuration for help text bottom padding
    private let helpTextBottomPadding: CGFloat = 30
    /// Configuration for help text bottom padding
    private let contentPadding: CGFloat = 20

    /// How far along the card drag is relative to the drag threshold
    private var dragProgress: CGFloat {
        let threshold: CGFloat = dragThreshold
        return max(abs(offset.width), abs(offset.height)) / threshold
    }

    /// The color of the card based on the drag direction
    private var cardColor: Color {
        let horizontal = offset.width
        let vertical = offset.height
        
        // More left and right than up
        if abs(horizontal) > abs(vertical) {
            return horizontal < 0 ? .red.opacity(colorOpacity) : .green.opacity(colorOpacity)
        } else if vertical < 0 {
            return .yellow.opacity(colorOpacity)
        }
        return Color(.systemBackground)
    }
    
    private var rotationAngle: Double {
        return Double(offset.width / rotationDivisor)
    }
    
    private var cardScale: CGFloat {
        return 1.0 - abs(offset.width) / UIScreen.main.bounds.width * scaleDivisor
    }

    var body: some View {
        GeometryReader { geometry in
            // Card stack
            ZStack {
                
                // Main card Background
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .stroke(Color(.separator), lineWidth: borderWidth)
                    )
                    .shadow(
                        color: Color.black.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: shadowOffsetX,
                        y: shadowOffsetY
                    )
                
                // Interior Card content
                VStack {
                    Spacer()
                    
                    // Question text
                    Text(question.text)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, questionHorizontalPadding)
                    
                    Spacer()
                    
                    // Help instructions - single line at bottom
                    HStack(spacing: helpTextSpacing) {
                        HStack(spacing: helpTextIconSpacing) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.red)
                                .font(.title3)
                            Text(question.answerTexts[.no] ?? "No")
                                .foregroundColor(.red)
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: helpTextIconSpacing) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.yellow)
                                .font(.title3)
                            Text(question.answerTexts[.maybe] ?? "Maybe")
                                .foregroundColor(.yellow)
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: helpTextIconSpacing) {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text(question.answerTexts[.yes] ?? "Yes")
                                .foregroundColor(.green)
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                    .opacity(dragProgress > helpTextFadeThreshold ? 0.3 : 1.0)
                    .padding(.bottom, helpTextBottomPadding)
                }
                .padding(contentPadding)
            }
            .frame(width: geometry.size.width - cardPadding, height: geometry.size.height - cardPadding)
            .position(x: geometry.size.width / 2 + offset.width, y: geometry.size.height / 2 + offset.height)
            .rotationEffect(.degrees(Double(offset.width / rotationDivisor)))
            .scaleEffect(1.0 - abs(offset.width) / geometry.size.width * scaleEffectMultiplier)
                .gesture(
                    // Gesture logic to handle card swiping and dragging
                    DragGesture()
                        .onChanged { gesture in
                            if !isAnswered {
                                offset = gesture.translation
                            }
                        }
                        .onEnded { gesture in
                            if !isAnswered {
                                let horizontal = gesture.translation.width
                                let vertical = gesture.translation.height
                                let velocity = gesture.velocity
                                
                                // Calculate if we should trigger based on distance OR velocity (like Tinder)
                                let swipeThreshold: CGFloat = geometry.size.width * swipeThresholdMultiplier
                                let velocityThreshold: CGFloat = self.velocityThreshold
                                
                                let shouldTriggerHorizontal = abs(horizontal) > swipeThreshold || abs(velocity.width) > velocityThreshold
                                let shouldTriggerVertical = abs(vertical) > swipeThreshold || abs(velocity.height) > velocityThreshold
                                
                                if shouldTriggerHorizontal || shouldTriggerVertical {
                                    let answer: AnswerType?
                                    
                                    // Determine the answer based on the primary direction
                                    if abs(horizontal) > abs(vertical) || abs(velocity.width) > abs(velocity.height) {
                                        // Horizontal movement (left/right)
                                        answer = (horizontal < 0 || velocity.width < 0) ? .no : .yes
                                    } else if vertical < 0 || velocity.height < 0 {
                                        // Upward movement only
                                        answer = .maybe
                                    } else {
                                        // Downward movement - not a valid answer, should return to center
                                        answer = nil
                                    }
                                    
                                    // Only proceed if we have a valid answer
                                    if let validAnswer = answer {
                                        selectedAnswer = validAnswer
                                        
                                        // Calculate final position based on direction and add velocity momentum
                                        let velocityMultiplier: CGFloat = self.velocityMultiplier
                                        
                                        // Calculate final width position
                                        let finalWidth: CGFloat
                                        if horizontal < 0 {
                                            finalWidth = -geometry.size.width * exitDistanceMultiplier + velocity.width * velocityMultiplier
                                        } else if horizontal > 0 {
                                            finalWidth = geometry.size.width * exitDistanceMultiplier + velocity.width * velocityMultiplier
                                        } else if velocity.width < 0 {
                                            finalWidth = -geometry.size.width * exitDistanceMultiplier + velocity.width * velocityMultiplier
                                        } else {
                                            finalWidth = geometry.size.width * exitDistanceMultiplier + velocity.width * velocityMultiplier
                                        }
                                        
                                        // Calculate final height position
                                        let finalHeight: CGFloat
                                        if vertical < 0 {
                                            finalHeight = -geometry.size.height * exitDistanceMultiplier + velocity.height * velocityMultiplier
                                        } else if vertical > 0 {
                                            finalHeight = geometry.size.height * exitDistanceMultiplier + velocity.height * velocityMultiplier
                                        } else if velocity.height < 0 {
                                            finalHeight = -geometry.size.height * exitDistanceMultiplier + velocity.height * velocityMultiplier
                                        } else {
                                            finalHeight = geometry.size.height * exitDistanceMultiplier + velocity.height * velocityMultiplier
                                        }
                                        
                                        let finalOffset = CGSize(width: finalWidth, height: finalHeight)
                                        
                                        withAnimation(.easeOut(duration: exitAnimationDuration)) {
                                            offset = finalOffset
                                        }
                                        
                                        // Call onSwipe after animation has time to complete
                                        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeCallback) {
                                            isAnswered = true
                                            onSwipe(Answer(type: validAnswer, text: question.answerTexts[validAnswer] ?? ""))
                                        }
                                    } else {
                                        // Invalid direction (downward), return to center
                                        withAnimation(.spring(response: springResponse, dampingFraction: springDamping, blendDuration: 0)) {
                                            offset = .zero
                                        }
                                    }
                                } else {
                                    // Reset with spring animation if not swiped far enough
                                    withAnimation(.spring(response: springResponse, dampingFraction: springDamping, blendDuration: 0)) {
                                        offset = .zero
                                    }
                                }
                            }
                        }
                )
            }
            .clipped()
        }
    }

#Preview {
    CardView(
        question: Question(text: "Do you like pizza?")
    ) { answer in
        print("Selected answer: \(answer)")
    }
    .background(Color(.systemGroupedBackground))
}