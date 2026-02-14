//
//  OnlineHostManagementSheet.swift
//  Overlap
//
//  Host controls for sharing and participant management during online sessions.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnlineHostManagementSheet: View {
    let overlap: Overlap
    let sessionID: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionService: OnlineSessionService

    @State private var renameSourceParticipant: String?
    @State private var renameTargetParticipant = ""
    @State private var isActionInFlight = false
    @State private var errorMessage: String?

    private var session: HostedOnlineSession? {
        sessionService.hostedSession(id: sessionID)
    }

    var body: some View {
        NavigationStack {
            List {
                if let session {
                    // Share section
                    Section {
                        InviteCodeCard(
                            code: session.inviteCode,
                            shareURL: session.shareURL,
                            questionnaireTitle: session.questionnaireTitle
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } header: {
                        Label("Share Session", systemImage: "square.and.arrow.up")
                    }

                    // Participants section with swipe actions
                    Section {
                        ForEach(session.participantDisplayNames, id: \.self) { participant in
                            participantRow(participant: participant, session: session)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    let isHost = session.hostDisplayName.caseInsensitiveCompare(participant) == .orderedSame

                                    if !isHost {
                                        Button(role: .destructive) {
                                            Task { await removeParticipant(participant) }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }

                                    Button {
                                        renameSourceParticipant = participant
                                        renameTargetParticipant = participant
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        Label("Participants (\(session.participantDisplayNames.count)/\(session.maxParticipants))", systemImage: "person.3.fill")
                    }
                } else {
                    ContentUnavailableView(
                        "Session Not Found",
                        systemImage: "wifi.exclamationmark",
                        description: Text("The session is no longer available.")
                    )
                }
            }
            .navigationTitle("Manage Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { renameSourceParticipant != nil },
                    set: { isPresented in
                        if !isPresented {
                            renameSourceParticipant = nil
                            renameTargetParticipant = ""
                        }
                    }
                )
            ) {
                renameParticipantSheet
                    .presentationDetents([.fraction(0.3)])
                    .presentationBackground(.ultraThinMaterial)
            }
            .alert(
                "Online Session",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { _ in errorMessage = nil }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                sessionService.startSessionObservation(sessionID: sessionID)
            }
        }
    }

    @ViewBuilder
    private func participantRow(participant: String, session: HostedOnlineSession) -> some View {
        let isHost = session.hostDisplayName.caseInsensitiveCompare(participant) == .orderedSame

        HStack(spacing: Tokens.Spacing.m) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                HStack(spacing: Tokens.Spacing.s) {
                    Text(participant)
                        .font(.body)
                        .fontWeight(.medium)

                    if isHost {
                        Text("Host")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, Tokens.Spacing.s)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                participantStatusPill(participant: participant, session: session)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func participantStatusPill(participant: String, session: HostedOnlineSession) -> some View {
        let (text, color) = participantStatusInfo(participant: participant, session: session)

        HStack(spacing: Tokens.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption)
                .foregroundColor(color)
        }
    }

    private var renameParticipantSheet: some View {
        NavigationStack {
            VStack(spacing: Tokens.Spacing.xl) {
                VStack(spacing: Tokens.Spacing.s) {
                    Text("Rename Participant")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let source = renameSourceParticipant {
                        Text("Renaming \"\(source)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                TextField("New name", text: $renameTargetParticipant)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()

                VStack(spacing: Tokens.Spacing.s) {
                    GlassActionButton(
                        title: "Save",
                        icon: "checkmark",
                        isEnabled: !renameTargetParticipant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        tintColor: .blue
                    ) {
                        Task { await renameParticipant() }
                    }

                    Button {
                        renameSourceParticipant = nil
                        renameTargetParticipant = ""
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(Tokens.Spacing.xl)
        }
    }

    private func participantStatusInfo(
        participant: String,
        session: HostedOnlineSession
    ) -> (String, Color) {
        guard let raw = session.participantStatuses[participant],
              let status = HostedOnlineSession.ParticipantStatus(rawValue: raw)
        else {
            return ("Joined", .blue)
        }

        switch status {
        case .invited:
            return ("Invited", .gray)
        case .joined:
            return ("Joined", .blue)
        case .answering:
            let answered = session.participantAnsweredCounts[participant] ?? 0
            return ("Answering \(answered)/\(session.totalQuestions)", .orange)
        case .submitted:
            return ("Submitted", .green)
        }
    }

    @MainActor
    private func removeParticipant(_ participant: String) async {
        isActionInFlight = true
        defer { isActionInFlight = false }

        do {
            _ = try await sessionService.removeParticipantOnline(
                sessionID: sessionID,
                displayName: participant
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func renameParticipant() async {
        guard let source = renameSourceParticipant else { return }
        let target = renameTargetParticipant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }

        isActionInFlight = true
        defer { isActionInFlight = false }

        do {
            _ = try await sessionService.renameParticipantOnline(
                sessionID: sessionID,
                oldDisplayName: source,
                newDisplayName: target
            )

            if let updatedSession = sessionService.hostedSession(id: sessionID),
               let localParticipantID = overlap.onlineParticipantID,
               let resolvedName = updatedSession.participantIDsByDisplayName.first(where: {
                   $0.value.caseInsensitiveCompare(localParticipantID) == .orderedSame
               })?.key {
                overlap.onlineParticipantDisplayName = resolvedName
            }

            renameSourceParticipant = nil
            renameTargetParticipant = ""
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    OnlineHostManagementSheet(
        overlap: SampleData.sampleOverlap,
        sessionID: "preview-session"
    )
    .environmentObject(OnlineSessionService.shared)
}
