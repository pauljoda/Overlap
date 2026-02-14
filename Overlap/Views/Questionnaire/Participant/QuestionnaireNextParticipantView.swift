//
//  QuestionnaireNextParticipantView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireNextParticipantView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @State private var isAnimated = false
    @State private var syncErrorMessage: String?

    var body: some View {
        ZStack {
            BlobBackgroundView(emphasis: .none)

            // Scrollable Content - Full screen
            ScrollView {
                VStack(spacing: Tokens.Spacing.tripleXL) {
                    // Main Participant Section
                    VStack(spacing: Tokens.Spacing.xl) {
                        AnimatedParticipantDisplay(
                            overlap: overlap,
                            subtitle: overlap.isOnline ? "Your Turn" : "Next Participant",
                            isAnimated: isAnimated
                        )

                        // Hand-off Instructions Card - only show for offline overlaps
                        if !overlap.isOnline {
                            InstructionCard(
                                icon: "hand.point.right.fill",
                                text: "Pass to the next participant",
                                isAnimated: isAnimated,
                                animationDelay: Tokens.Delay.medium
                            )
                        }
                    }
                    .padding(.horizontal, Tokens.Spacing.xl)
                    .padding(.top, Tokens.Spacing.quadXL)

                    // Questionnaire Instructions Section
                    QuestionnaireInstructionsSection(
                        overlap: overlap,
                        isAnimated: isAnimated,
                        animationDelay: Tokens.Delay.long
                    )
                    .padding(.horizontal, Tokens.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isAnimated ? 1 : 0)
                    .animation(
                        .easeIn(duration: Tokens.Duration.slow).delay(Tokens.Duration.medium),
                        value: isAnimated
                    )

                    // Bottom spacing to account for floating button
                    Spacer()
                        .frame(height: Tokens.Size.buttonLarge + Tokens.Spacing.xl * 2)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Floating Begin Button - overlayed at bottom
            VStack {
                Spacer()
                
                GlassActionButton(
                    title: Tokens.Strings.beginQuestions,
                    icon: "play.fill",
                    isEnabled: true,
                    tintColor: .green,
                    action: beginAnswering
                )
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : Tokens.Size.buttonStandard)
                .animation(
                    .spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping).delay(Tokens.Spring.response),
                    value: isAnimated
                )
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .onAppear {
            isAnimated = true
        }
        .alert(
            "Online Session",
            isPresented: Binding(
                get: { syncErrorMessage != nil },
                set: { _ in syncErrorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(syncErrorMessage ?? "")
        }
    }

    private func beginAnswering() {
        if overlap.isOnline,
           let sessionID = overlap.onlineSessionID,
           let participantID = resolvedParticipantID() {
            Task {
                await beginAnsweringOnline(sessionID: sessionID, participantID: participantID)
            }
            return
        }

        overlap.currentState = .answering
        try? modelContext.save()
    }

    @MainActor
    private func beginAnsweringOnline(sessionID: String, participantID: String) async {
        do {
            _ = try await onlineSessionService.beginParticipantOnline(
                sessionID: sessionID,
                participantID: participantID
            )
            overlap.currentState = .answering
            try? modelContext.save()
        } catch {
            syncErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func resolvedParticipantID() -> String? {
        if let participantID = overlap.onlineParticipantID?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !participantID.isEmpty {
            return participantID
        }

        guard let sessionID = overlap.onlineSessionID,
              let participantName = overlap.onlineParticipantDisplayName,
              let hostedSession = onlineSessionService.hostedSession(id: sessionID)
        else {
            return nil
        }

        let mappedID = hostedSession.participantIDsByDisplayName.first(where: {
            $0.key.caseInsensitiveCompare(participantName) == .orderedSame
        })?.value
        if let mappedID {
            overlap.onlineParticipantID = mappedID
        }
        return mappedID
    }
}

#Preview {
    QuestionnaireNextParticipantView(overlap: SampleData.sampleOverlap)
        .environmentObject(OnlineSessionService.shared)
}
