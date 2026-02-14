//
//  QuestionnaireAwaitingResponsesView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

struct QuestionnaireAwaitingResponsesView: View {
    let overlap: Overlap
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @EnvironmentObject private var onlineHostAuthService: OnlineHostAuthService
    @State private var isAnimated = false
    @State private var showingHostManagement = false

    private var hostedSession: HostedOnlineSession? {
        guard overlap.isOnline, let sessionID = overlap.onlineSessionID else { return nil }
        return onlineSessionService.hostedSession(id: sessionID)
    }

    private var completedParticipants: [String] {
        if let hostedSession {
            return hostedSession.participantDisplayNames.filter {
                hostedSession.participantStatuses[$0] == HostedOnlineSession.ParticipantStatus.submitted.rawValue
            }
        }

        return overlap.participants.filter { overlap.isParticipantComplete($0) }
    }

    private var pendingParticipants: [String] {
        if let hostedSession {
            return hostedSession.participantDisplayNames.filter {
                hostedSession.participantStatuses[$0] != HostedOnlineSession.ParticipantStatus.submitted.rawValue
            }
        }

        return overlap.participants.filter { !overlap.isParticipantComplete($0) }
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
                    // Header
                    VStack(spacing: Tokens.Spacing.xl) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: Tokens.Size.iconHuge))
                            .foregroundColor(.orange)
                            .scaleEffect(isAnimated ? 1.0 : 0.8)
                            .animation(.spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping), value: isAnimated)

                        Text(Tokens.Strings.awaitingResponses)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .opacity(isAnimated ? 1 : 0)
                            .animation(.easeIn(duration: Tokens.Duration.medium).delay(0.2), value: isAnimated)

                        Text("Some participants have finished, waiting for others to complete their responses.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Tokens.Spacing.xl)
                            .opacity(isAnimated ? 1 : 0)
                            .animation(.easeIn(duration: Tokens.Duration.medium).delay(0.4), value: isAnimated)
                    }

                    // Participants Status
                    VStack(spacing: Tokens.Spacing.l) {
                        if !completedParticipants.isEmpty {
                            ParticipantStatusSection(
                                title: Tokens.Strings.completedResponses,
                                icon: "checkmark.circle.fill",
                                participants: completedParticipants,
                                color: .green,
                                isAnimated: isAnimated,
                                delay: Tokens.Delay.long
                            )
                        }

                        if !pendingParticipants.isEmpty {
                            ParticipantStatusSection(
                                title: Tokens.Strings.pendingResponses,
                                icon: "clock.circle.fill",
                                participants: pendingParticipants,
                                color: .orange,
                                isAnimated: isAnimated,
                                delay: Tokens.Delay.extraLong
                            )
                        }
                    }

                    VStack(spacing: Tokens.Spacing.m) {
                        if isCurrentDeviceHost, let hostedSession {
                            hostShareContent(session: hostedSession)
                        } else {
                            Label("Waiting for the host to continue the session.", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .opacity(isAnimated ? 1 : 0)
                                .offset(y: isAnimated ? 0 : 20)
                                .animation(.easeIn(duration: Tokens.Duration.medium).delay(Tokens.Delay.extraLong + 0.2), value: isAnimated)
                        }
                    }
                    .padding(.top, Tokens.Spacing.l)

                    // Bottom spacing for floating button
                    Spacer()
                        .frame(height: isCurrentDeviceHost
                               ? Tokens.Size.buttonLarge + Tokens.Spacing.xl * 3
                               : Tokens.Spacing.quadXL)
                }
                .padding(Tokens.Spacing.xl)
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
                    .offset(y: isAnimated ? 0 : 20)
                    .animation(.easeIn(duration: Tokens.Duration.medium).delay(Tokens.Delay.extraLong + 0.2), value: isAnimated)
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
            if overlap.isOnline, let sessionID = overlap.onlineSessionID {
                onlineSessionService.startSessionObservation(sessionID: sessionID)
            }
        }
    }

    /// Share content (invite card + text) in scroll area — button floats separately
    @ViewBuilder
    private func hostShareContent(session: HostedOnlineSession) -> some View {
        VStack(spacing: Tokens.Spacing.m) {
            Text(pendingParticipants.isEmpty
                 ? "Invite participants to keep this session active."
                 : "Share invite details so everyone can join.")
                .font(.caption)
                .foregroundColor(.secondary)

            InviteCodeCard(
                code: session.inviteCode,
                shareURL: session.shareURL,
                questionnaireTitle: session.questionnaireTitle
            )
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.easeIn(duration: Tokens.Duration.medium).delay(Tokens.Delay.extraLong + 0.2), value: isAnimated)
    }
}

struct ParticipantStatusSection: View {
    let title: String
    let icon: String
    let participants: [String]
    let color: Color
    let isAnimated: Bool
    let delay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            HStack(spacing: Tokens.Spacing.s) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            VStack(spacing: Tokens.Spacing.xs) {
                ForEach(participants, id: \.self) { participant in
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(color)
                            .frame(width: 16)

                        Text(participant)
                            .font(.body)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, Tokens.Spacing.m)
                    .padding(.vertical, Tokens.Spacing.s)
                    .standardGlassCard()
                }
            }
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.easeIn(duration: Tokens.Duration.medium).delay(delay), value: isAnimated)
    }
}

#Preview {
    let sampleOverlap = Overlap(
        participants: ["Alice", "Bob", "Charlie"],
        questionnaire: SampleData.sampleQuestionnaire,
        currentState: .awaitingResponses
    )

    QuestionnaireAwaitingResponsesView(overlap: sampleOverlap)
        .environmentObject(OnlineSessionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
}
