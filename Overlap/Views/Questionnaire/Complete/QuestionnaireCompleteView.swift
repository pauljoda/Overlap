//
//  QuestionnaireCompleteView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireCompleteView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @EnvironmentObject private var onlineHostAuthService: OnlineHostAuthService
    @State private var isAnimated = false
    @State private var showingHostManagement = false

    private var hostedSession: HostedOnlineSession? {
        guard overlap.isOnline, let sessionID = overlap.onlineSessionID else { return nil }
        return onlineSessionService.hostedSession(id: sessionID)
    }

    private var isCurrentDeviceHost: Bool {
        guard let hostedSession,
              let account = onlineHostAuthService.account
        else { return false }
        return hostedSession.hostAppleUserID == account.appleUserID
    }

    var body: some View {
        ZStack {
            GlassScreen {
                VStack(spacing: Tokens.Spacing.tripleXL) {
                    // Header Section
                    CompletionHeader(isAnimated: isAnimated, overlap: overlap)

                    // Results Section
                    OverlapResultsView(overlap: overlap, isAnimated: isAnimated)

                    if isCurrentDeviceHost, let hostedSession {
                        hostCompleteActions(session: hostedSession)
                    }

                    // Bottom padding to account for floating button
                    Spacer()
                        .frame(height: isCurrentDeviceHost
                               ? Tokens.Size.buttonLarge + Tokens.Spacing.xl * 3
                               : Tokens.Spacing.quadXL)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Floating manage button
            if isCurrentDeviceHost {
                VStack {
                    Spacer()

                    GlassActionButton(
                        title: "Manage Session",
                        icon: "gearshape.fill",
                        tintColor: .blue
                    ) {
                        showingHostManagement = true
                    }
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 30)
                    .animation(
                        .easeOut(duration: Tokens.Duration.medium).delay(sessionControlsDelay),
                        value: isAnimated
                    )
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .sheet(isPresented: $showingHostManagement) {
            if let sessionID = overlap.onlineSessionID {
                OnlineHostManagementSheet(overlap: overlap, sessionID: sessionID)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
        .onAppear {
            isAnimated = true

            // Set completion date if not already set
            if overlap.completeDate == nil {
                overlap.completeDate = Date.now
                try? modelContext.save()
            }

            if overlap.isOnline, let sessionID = overlap.onlineSessionID {
                onlineSessionService.startSessionObservation(sessionID: sessionID)
            }
        }
    }

    /// Delay for session controls, calculated after all result card animations finish
    private var sessionControlsDelay: Double {
        let fullCount = Double(overlap.getQuestionsWithResponses().filter { _, responses in
            responses.values.allSatisfy { $0 == .yes } && !responses.isEmpty
        }.count)
        let partialCount = Double(overlap.getQuestionsWithResponses().filter { _, responses in
            let hasAtLeastOneMaybe = responses.values.contains { $0 == .maybe }
            let hasNoNo = !responses.values.contains { $0 == .no }
            let notAllYes = !responses.values.allSatisfy { $0 == .yes }
            return hasAtLeastOneMaybe && hasNoNo && notAllYes && !responses.isEmpty
        }.count)
        // Base delay after partial agreement section finishes
        return 1.6 + fullCount * 0.15 + partialCount * 0.15
    }

    @ViewBuilder
    private func hostCompleteActions(session: HostedOnlineSession) -> some View {
        VStack(spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Session Controls", icon: "person.3.fill")

            Text("Share the invite or manage participants.")
                .font(.caption)
                .foregroundColor(.secondary)

            InviteCodeCard(
                code: session.inviteCode,
                shareURL: session.shareURL,
                questionnaireTitle: session.questionnaireTitle
            )
        }
        .padding(.horizontal, Tokens.Spacing.xl)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(
            .easeOut(duration: Tokens.Duration.medium).delay(sessionControlsDelay),
            value: isAnimated
        )
    }
}

#Preview {
    // Create a sample overlap with completed responses for visualization
    let sampleOverlapWithResponses: Overlap = {
        let overlap = Overlap(
            participants: ["Alice", "Bob", "Charlie"],
            questionnaire: SampleData.sampleQuestionnaire,
            currentState: .complete
        )

        // Set a completion date for preview
        overlap.completeDate = Date.now

        // Initialize the session and simulate responses
        overlap.setParticipants(["Alice", "Bob", "Charlie"])

        // Simulate response patterns
        let responsePatterns = [
            [Answer.yes, .yes, .maybe, .no, .yes],      // Alice
            [Answer.yes, .yes, .yes, .yes, .yes],       // Bob
            [Answer.yes, .yes, .maybe, .maybe, .maybe]  // Charlie
        ]

        // Reset and populate responses
        overlap.resetSession()
        for pattern in responsePatterns {
            for answer in pattern {
                _ = overlap.saveResponse(answer: answer)
            }
        }

        return overlap
    }()

    QuestionnaireCompleteView(overlap: sampleOverlapWithResponses)
        .environmentObject(OnlineSessionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
}
