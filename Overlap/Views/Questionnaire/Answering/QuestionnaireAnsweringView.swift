//
//  QuestionnaireAnsweringView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireAnsweringView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    
    @State private var blobEmphasis: BlobEmphasis = .none
    @State private var syncErrorMessage: String?
    
    /// The scale of the card for animation
    @State private var cardScale: CGFloat = 0.8
    /// The opacity of the card for animation
    @State private var cardOpacity: Double = 0.0

    var body: some View {
        GlassScreen(scrollable: false, emphasis: blobEmphasis) {
            VStack(spacing: Tokens.Spacing.xs) {
                if let currentQuestion = overlap.currentQuestion {
                    CardView(
                        question: currentQuestion,
                        onSwipe: { answer in
                            let answeredQuestionIndex = overlap.currentQuestionIndex

                            if overlap.isOnline,
                               let sessionID = overlap.onlineSessionID {
                                guard let participantID = resolvedCurrentParticipantID(),
                                      isCurrentDeviceParticipant(participantID)
                                else {
                                    syncErrorMessage = "You are no longer part of this session."
                                    overlap.currentState = .instructions
                                    return
                                }

                                Task {
                                    await syncOnlineAnswer(
                                        sessionID: sessionID,
                                        participantID: participantID,
                                        questionIndex: answeredQuestionIndex,
                                        answer: answer
                                    )
                                }
                            } else {
                                // Save answer first (this changes the question index).
                                _ = overlap.saveResponse(answer: answer)

                                do {
                                    try modelContext.save()
                                } catch {
                                    print("QuestionnaireAnsweringView: ModelContext save failed: \(error)")
                                }
                            }

                            // Reset blob emphasis
                            blobEmphasis = .none

                            // Reset card state for next card
                            cardScale = 0.8
                            cardOpacity = 0.0

                            // Animate in the next card with a slight delay to ensure state is updated
                            DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Delay.short) {
                                withAnimation(
                                    .spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping)
                                ) {
                                    cardScale = 1.0
                                    cardOpacity = 1.0
                                }
                            }
                        },
                        onEmphasisChange: { emphasis in
                            blobEmphasis = emphasis
                        }
                    )
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .id(currentQuestion)  // Force SwiftUI to recreate the view
                    .onAppear {
                        // Animate in the first card
                        withAnimation(.spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping)) {
                            cardScale = 1.0
                            cardOpacity = 1.0
                        }
                    }
                } else {
                    Text(Tokens.Strings.noMoreQuestions)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Progress
                QuestionnaireProgress(overlap: overlap)
                    .padding(.top, Tokens.Spacing.m)
                    .padding(.bottom, Tokens.Spacing.xl)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
        }
        .task {
            guard overlap.isOnline, let sessionID = overlap.onlineSessionID else { return }
            onlineSessionService.startSessionObservation(sessionID: sessionID)
        }
        .onReceive(onlineSessionService.$sessionsByID) { _ in
            guard overlap.isOnline,
                  let sessionID = overlap.onlineSessionID,
                  let session = onlineSessionService.hostedSession(id: sessionID)
            else { return }

            let removed = OnlineSessionSnapshotApplier.apply(session: session, to: overlap)
            if removed {
                syncErrorMessage = "You were removed from this online session."
            }
            try? modelContext.save()
        }
        .alert("Online Session", isPresented: Binding(get: { syncErrorMessage != nil }, set: { _ in syncErrorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(syncErrorMessage ?? "")
        }
    }

    @MainActor
    private func syncOnlineAnswer(
        sessionID: String,
        participantID: String,
        questionIndex: Int,
        answer: Answer
    ) async {
        do {
            let session = try await onlineSessionService.submitParticipantAnswerOnline(
                sessionID: sessionID,
                participantID: participantID,
                questionIndex: questionIndex,
                answer: answer
            )
            _ = OnlineSessionSnapshotApplier.apply(session: session, to: overlap)
            try? modelContext.save()
        } catch let error as OnlineSessionError {
            syncErrorMessage = error.localizedDescription
            if case .participantNotInSession = error {
                overlap.currentState = .instructions
            }
        } catch {
            print("QuestionnaireAnsweringView: Online answer sync failed: \(error)")
        }
    }

    private func isCurrentDeviceParticipant(_ participantID: String) -> Bool {
        guard let sessionID = overlap.onlineSessionID,
              let hostedSession = onlineSessionService.hostedSession(id: sessionID)
        else {
            return false
        }

        return hostedSession.participantIDsByDisplayName.values.contains {
            $0.caseInsensitiveCompare(participantID) == .orderedSame
        }
    }

    private func resolvedCurrentParticipantID() -> String? {
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
    ZStack {
        BlobBackgroundView()
        QuestionnaireAnsweringView(overlap: SampleData.sampleOverlap)
    }
    .environmentObject(OnlineSessionService.shared)
}
