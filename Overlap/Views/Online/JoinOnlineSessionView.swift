//
//  JoinOnlineSessionView.swift
//  Overlap
//
//  Guest join flow using invite link token or manual invite code.
//

import SwiftUI

struct JoinOnlineSessionView: View {
    let prefilledInvite: String?

    @Environment(\.onlineSessionService) private var sessionService

    @StateObject private var userPreferences = UserPreferences.shared

    @State private var inviteValue = ""
    @State private var displayName = ""
    @State private var joinedSession: JoinedOnlineSession?
    @State private var errorMessage: String?

    private var effectiveInvite: String {
        let manual = inviteValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty {
            return manual
        }
        return prefilledInvite ?? ""
    }

    var body: some View {
        GlassScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xl) {
                    header
                    inviteCard
                    nameCard
                    joinAction
                    joinedSummary
                }
                .padding(Tokens.Spacing.xl)
                .frame(maxWidth: Tokens.Size.maxContentWidth)
            }
        }
        .navigationTitle("Join Session")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Join Session", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            if displayName.isEmpty {
                displayName = userPreferences.userDisplayName ?? ""
            }

            if inviteValue.isEmpty, let prefilledInvite {
                inviteValue = prefilledInvite
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Text("Join an online Overlap")
                .font(.title2)
                .fontWeight(.bold)

            Text("Open an invite link or paste the fallback code.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Label("Invite Link or Code", systemImage: "link")
                .font(.headline)

            TextField("Paste link or enter code", text: $inviteValue)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Text("Example code: ABC-123")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .standardGlassCard()
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Label("Display Name", systemImage: "person.fill")
                .font(.headline)

            TextField("Your name", text: $displayName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Text("Hosts and participants see this in the session.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .standardGlassCard()
    }

    private var joinAction: some View {
        Button {
            joinSession()
        } label: {
            Text("Join Online Session")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private var joinedSummary: some View {
        if let joinedSession {
            VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                Label("Joined", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                Text(joinedSession.questionnaireTitle)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Host: \(joinedSession.hostDisplayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Participants: \(joinedSession.participantDisplayNames.count)/\(OnlineConfiguration.maxParticipants)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Session expires \(joinedSession.expiresAt.formatted(date: .abbreviated, time: .omitted)).")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Realtime questionnaire answering will attach to this session in the Firebase step.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .standardGlassCard()
        }
    }

    private func joinSession() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter a display name first."
            return
        }

        let invite = effectiveInvite
        guard !invite.isEmpty else {
            errorMessage = "Paste an invite link or enter a code."
            return
        }

        do {
            let joined = try sessionService.joinSession(invite: invite, displayName: trimmedName)
            joinedSession = joined
            userPreferences.setDisplayName(trimmedName)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        JoinOnlineSessionView(prefilledInvite: "ABC-123")
    }
}
