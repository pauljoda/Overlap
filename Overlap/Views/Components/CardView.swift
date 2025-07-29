//
//  CardView.swift
//  Overlap
//
//  Created by Paul Davis on 7/25/25.
//

import SwiftUI

enum DragDirection {
    case left, right, up
}

struct CardView: View {
    // Paramaters
    /// The question to display on the card
    let question: Question
    /// Callback to handle the answer selection
    var onSwipe: (Answer) -> Void
    /// Callback to handle emphasis changes for the background
    var onEmphasisChange: ((BlobEmphasis) -> Void)?

    // State Variables
    /// The current offset of the card during drag
    @State private var offset = CGSize.zero
    /// Flag to indicate if the card has been answered
    @State private var isAnswered = false
    /// The selected answer after swiping
    @State private var selectedAnswer: AnswerType?
    
    // MARK: - Configuration Variables
    ///Configuration for various thresholds and visual styles
    private let dragThreshold: CGFloat = 80
    /// Velocity threshold for swipe detection
    private let velocityThreshold: CGFloat = 400
    /// Configuration for exit distance multiplier
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
    
    // Color Configuration (simplified)
    /// Threshold for when to fade help text
    private let helpTextFadeThreshold: CGFloat = 0.3
    
    // Animation Configuration
    /// Configuration for animation effects
    private let rotationDivisor: CGFloat = 10
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
        return max(abs(offset.width), abs(offset.height)) / dragThreshold
    }

    /// The color of the card (simplified - no color changes during drag)
    private var cardColor: Color {
        return Color(.systemBackground)
    }
    
    /// Determines the current emphasis based on drag position
    private var currentEmphasis: BlobEmphasis {
        guard max(abs(offset.width), abs(offset.height)) > 20 else {
            return .none
        }
        
        let absWidth = abs(offset.width)
        let absHeight = abs(offset.height)
        
        if absWidth > absHeight {
            return offset.width < 0 ? .red : .green
        } else if offset.height < 0 {
            return .yellow
        }
        
        return .none
    }
    
    /// Determines the answer direction based on final movement
    private func determineAnswerDirection(from translation: CGSize, velocity: CGSize) -> DragDirection? {
        let absWidth = abs(translation.width)
        let absHeight = abs(translation.height)
        let absVelWidth = abs(velocity.width)
        let absVelHeight = abs(velocity.height)
        
        // Determine dominant direction based on both distance and velocity
        let horizontalStrength = absWidth + absVelWidth * 0.1 // Small velocity contribution
        let verticalStrength = absHeight + absVelHeight * 0.1
        
        if horizontalStrength > verticalStrength {
            return translation.width < 0 ? .left : .right
        } else if translation.height < 0 {
            return .up
        }
        
        return nil // Downward movement not allowed
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
                        .opacity(0.7)
                
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
                .gesture(
                    // Simplified free movement gesture
                    DragGesture()
                        .onChanged { gesture in
                            if !isAnswered {
                                // Allow completely free movement
                                offset = gesture.translation
                                
                                // Notify about emphasis change
                                onEmphasisChange?(currentEmphasis)
                            }
                        }
                        .onEnded { gesture in
                            if !isAnswered {
                                let distance = max(abs(offset.width), abs(offset.height))
                                let velocity = max(abs(gesture.velocity.width), abs(gesture.velocity.height))
                                
                                // Check if we should trigger based on distance or velocity
                                let shouldTrigger = distance > dragThreshold || velocity > velocityThreshold
                                
                                if shouldTrigger {
                                    // Determine answer based on final position and velocity
                                    if let direction = determineAnswerDirection(from: gesture.translation, velocity: gesture.velocity) {
                                        let answer: AnswerType
                                        
                                        switch direction {
                                        case .left:
                                            answer = .no
                                        case .right:
                                            answer = .yes
                                        case .up:
                                            answer = .maybe
                                        }
                                        
                                        selectedAnswer = answer
                                        
                                        // Calculate exit position based on direction
                                        let exitOffset: CGSize
                                        switch direction {
                                        case .left:
                                            exitOffset = CGSize(width: -geometry.size.width * exitDistanceMultiplier, height: gesture.translation.height)
                                        case .right:
                                            exitOffset = CGSize(width: geometry.size.width * exitDistanceMultiplier, height: gesture.translation.height)
                                        case .up:
                                            exitOffset = CGSize(width: gesture.translation.width, height: -geometry.size.height * exitDistanceMultiplier)
                                        }
                                        
                                        // Animate exit
                                        withAnimation(.easeOut(duration: exitAnimationDuration)) {
                                            offset = exitOffset
                                        }
                                        
                                        // Call completion callback
                                        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeCallback) {
                                            isAnswered = true
                                            onSwipe(Answer(type: answer, text: question.answerTexts[answer] ?? ""))
                                        }
                                    } else {
                                        // Invalid direction (downward), return to center
                                        withAnimation(.spring(response: springResponse, dampingFraction: springDamping, blendDuration: 0)) {
                                            offset = .zero
                                        }
                                        
                                        // Reset emphasis when returning to center
                                        onEmphasisChange?(.none)
                                    }
                                } else {
                                    // Reset to center with spring animation
                                    withAnimation(.spring(response: springResponse, dampingFraction: springDamping, blendDuration: 0)) {
                                        offset = .zero
                                    }
                                    
                                    // Reset emphasis when returning to center
                                    onEmphasisChange?(.none)
                                }
                            }
                        }
                )
            }
        }
    }


#Preview {
    struct CardViewPreview: View {
        @State private var blobEmphasis: BlobEmphasis = .none
        
        var body: some View {
            ZStack {
                BlobBackgroundView(emphasis: blobEmphasis)
                CardView(
                    question: Question(text: "Do you like pizza?"),
                    onSwipe: { answer in
                        print("Selected answer: \(answer)")
                    },
                    onEmphasisChange: { emphasis in
                        blobEmphasis = emphasis
                    }
                )
            }
        }
    }
    
    return CardViewPreview()
}
