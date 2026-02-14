//
//  AIGeneratingView.swift
//  Overlap
//
//  Animated loading view shown during AI questionnaire generation.
//

#if canImport(FoundationModels)
import FoundationModels
import SwiftUI

struct AIGeneratingView: View {
    let partialResult: GeneratedQuestionnaire.PartiallyGenerated?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var iconScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0
    @State private var statusIndex: Int = 0
    @State private var statusOpacity: Double = 1.0

    private let statusMessages = [
        "Thinking...",
        "Crafting questions...",
        "Shaping your questionnaire...",
        "Almost there...",
    ]

    var body: some View {
        VStack(spacing: Tokens.Spacing.xxl) {
            Spacer()

            // Animated icon with rotating ring
            ZStack {
                // Rotating gradient ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .purple],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(ringRotation))

                // Inner glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)

                // Apple Intelligence icon
                Image(systemName: "apple.intelligence")
                    .font(.system(size: Tokens.Size.iconLarge))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconScale)
            }

            // Status message
            Text(statusMessages[statusIndex])
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .opacity(statusOpacity)
                .animation(.easeInOut(duration: Tokens.Duration.fast), value: statusOpacity)

            // Partial results preview
            if let partial = partialResult {
                VStack(spacing: Tokens.Spacing.m) {
                    if let title = partial.title, !title.isEmpty {
                        HStack(spacing: Tokens.Spacing.s) {
                            Image(systemName: "text.quote")
                                .foregroundColor(.purple)
                            Text(title)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if let questions = partial.questions {
                        let validCount = questions.compactMap({ $0 }).filter({ !$0.isEmpty }).count
                        if validCount > 0 {
                            HStack(spacing: Tokens.Spacing.s) {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.blue)
                                Text("\(validCount) question\(validCount == 1 ? "" : "s") generated")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding(Tokens.Spacing.l)
                .frame(maxWidth: .infinity)
                .standardGlassCard()
                .animation(
                    .spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping),
                    value: partial.title
                )
            }

            Spacer()
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Pulsing icon
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            iconScale = 1.12
        }

        // Rotating ring
        withAnimation(
            .linear(duration: 3.0)
            .repeatForever(autoreverses: false)
        ) {
            ringRotation = 360
        }

        // Cycling status messages
        cycleStatus()
    }

    private func cycleStatus() {
        guard !reduceMotion else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.15)) {
                statusOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                statusIndex = (statusIndex + 1) % statusMessages.count
                withAnimation(.easeIn(duration: 0.15)) {
                    statusOpacity = 1
                }
            }

            cycleStatus()
        }
    }
}
#endif
