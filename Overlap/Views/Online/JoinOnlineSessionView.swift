//
//  JoinOnlineSessionView.swift
//  Overlap
//
//  Guest join flow using invite link token or manual invite code.
//

import SwiftUI
import SwiftData

struct JoinOnlineSessionView: View {
    let prefilledInvite: String?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @EnvironmentObject private var sessionService: OnlineSessionService

    @AppStorage("userDisplayName") private var savedDisplayName = ""
    @FocusState private var focusedField: FocusedField?
    @State private var inviteValue = ""
    @State private var displayName = ""
    @State private var joinedSession: JoinedOnlineSession?
    @State private var sessionPreview: SessionPreview?
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var isJoining = false

    private enum FocusedField: Hashable {
        case invite
        case displayName
    }

    private var effectiveInvite: String {
        let manual = inviteValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty {
            return manual
        }
        return prefilledInvite ?? ""
    }

    private var canJoin: Bool {
        !isJoining
            && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (sessionPreview != nil || !effectiveInvite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        ZStack {
            GlassScreen {
                VStack(spacing: Tokens.Spacing.xxl) {
                    header
                    inviteCard
                    nameCard
                    joinedSummary

                    Spacer()
                        .frame(height: Tokens.Size.buttonLarge + Tokens.Spacing.xl * 2)
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.xl)
                .frame(maxWidth: Tokens.Size.maxContentWidth)
            }
            .ignoresSafeArea(.container, edges: .bottom)

            VStack(spacing: Tokens.Spacing.m) {
                Spacer()

                GlassActionButton(
                    title: isJoining ? "Joining..." : "Join Online Session",
                    icon: "arrow.right.circle.fill",
                    isEnabled: canJoin,
                    tintColor: .blue
                ) {
                    Task {
                        await joinSession()
                    }
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
                .offset(y: canJoin ? 0 : 150)
                .animation(.easeInOut(duration: Tokens.Duration.medium), value: canJoin)
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
            if inviteValue.isEmpty, let prefilledInvite {
                inviteValue = prefilledInvite
            }
            if displayName.isEmpty, !savedDisplayName.isEmpty {
                displayName = savedDisplayName
            }
        }
    }

    private var header: some View {
        VStack(spacing: Tokens.Spacing.l) {
            Image(systemName: "person.2.fill")
                .font(.system(size: Tokens.Size.iconLarge))
                .foregroundColor(.teal)

            VStack(spacing: Tokens.Spacing.s) {
                Text("Join an Online Overlap")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text("Open an invite link or paste the fallback code.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var inviteCard: some View {
        if let sessionPreview {
            sessionPreviewCard(preview: sessionPreview)
        } else {
            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                SectionHeader(title: "Invite Link or Code", icon: "link")

                TextField("Paste link or enter code", text: $inviteValue)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                    .focused($focusedField, equals: .invite)
                    .onSubmit { validateInvite() }

                if isValidating {
                    HStack(spacing: Tokens.Spacing.s) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Validating...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Example code: ABC-123")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func sessionPreviewCard(preview: SessionPreview) -> some View {
        VStack(spacing: Tokens.Spacing.l) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: preview.startColorHex), Color(hex: preview.endColorHex)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: Tokens.Size.iconLarge, height: Tokens.Size.iconLarge)

                Text(preview.iconEmoji)
                    .font(.system(size: Tokens.Size.iconLarge * 0.5))
            }

            VStack(spacing: Tokens.Spacing.s) {
                Text(preview.questionnaireTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Host: \(preview.hostDisplayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: Tokens.Spacing.l) {
                HStack(spacing: Tokens.Spacing.xs) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(preview.participantCount)/\(preview.maxParticipants)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: Tokens.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Expires \(preview.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                withAnimation {
                    sessionPreview = nil
                }
            } label: {
                Label("Change Code", systemImage: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.Spacing.xl)
        .largeGlassCard()
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Display Name", icon: "person.fill")

            TextField("Your name", text: $displayName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(Tokens.Spacing.l)
                .standardGlassCard()
                .focused($focusedField, equals: .displayName)
                .onSubmit {
                    Task {
                        await joinSession()
                    }
                }

            Text("Hosts and participants see this in the session.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var joinedSummary: some View {
        if let joinedSession {
            VStack(spacing: Tokens.Spacing.l) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: Tokens.Size.iconMedium))
                    .foregroundColor(.green)

                VStack(spacing: Tokens.Spacing.s) {
                    Text(joinedSession.questionnaireTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Host: \(joinedSession.hostDisplayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: Tokens.Spacing.l) {
                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "person.3.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(joinedSession.participantDisplayNames.count)/\(OnlineConfiguration.maxParticipants)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Expires \(joinedSession.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Tokens.Spacing.xl)
            .largeGlassCard()
        }
    }

    private func validateInvite() {
        let invite = effectiveInvite
        guard !invite.isEmpty else { return }
        isValidating = true
        Task {
            do {
                let preview = try await sessionService.previewSession(invite: invite)
                withAnimation {
                    sessionPreview = preview
                }
                focusedField = .displayName
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isValidating = false
        }
    }

    @MainActor
    private func joinSession() async {
        isJoining = true
        defer { isJoining = false }

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
            let joined = try await sessionService.joinSessionOnline(
                invite: invite,
                displayName: trimmedName,
                participantID: OnlineParticipantIdentityService.shared.participantID
            )
            joinedSession = joined
            try openOrCreateOnlineOverlap(from: joined)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func openOrCreateOnlineOverlap(from joined: JoinedOnlineSession) throws {
        if let existing = try fetchOverlap(forHostedSessionID: joined.sessionID) {
            existing.participants = joined.participantDisplayNames
            existing.onlineParticipantID = joined.participantID
            existing.onlineParticipantDisplayName = joined.participantDisplayName
            applyInitialJoinedState(joined, to: existing)
            try modelContext.save()
            navigate(to: existing, using: navigationPath)
            return
        }

        let created = Overlap(
            participants: joined.participantDisplayNames,
            isOnline: true,
            title: joined.questionnaireTitle,
            information: joined.questionnaireInformation,
            instructions: joined.questionnaireInstructions,
            questions: joined.questionnaireQuestions,
            iconEmoji: joined.questionnaireIconEmoji,
            startColor: Color(hex: joined.questionnaireStartColorHex),
            endColor: Color(hex: joined.questionnaireEndColorHex),
            randomizeQuestions: false,
            currentState: .instructions
        )
        created.onlineSessionID = joined.sessionID
        created.onlineParticipantID = joined.participantID
        created.onlineParticipantDisplayName = joined.participantDisplayName
        applyInitialJoinedState(joined, to: created)
        modelContext.insert(created)
        try modelContext.save()
        navigate(to: created, using: navigationPath)
    }

    @MainActor
    private func fetchOverlap(forHostedSessionID sessionID: String) throws -> Overlap? {
        let descriptor = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { overlap in
                overlap.onlineSessionID == sessionID
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    @MainActor
    private func applyInitialJoinedState(_ joined: JoinedOnlineSession, to overlap: Overlap) {
        let participant = joined.participantDisplayName
        let statusRaw = joined.participantStatuses[participant]
        let status = statusRaw.flatMap { HostedOnlineSession.ParticipantStatus(rawValue: $0) } ?? .joined
        let answeredCount = joined.participantAnsweredCounts[participant] ?? 0
        let questionIndex = joined.participantQuestionIndices[participant] ?? 0

        if status == .submitted {
            OnlineSessionSnapshotApplier.applyPhase(joined.phase, to: overlap)
            return
        }

        if questionIndex > 0 || answeredCount > 0 || status == .answering {
            overlap.currentState = .answering
            overlap.isCompleted = false
            overlap.completeDate = nil
            return
        }

        overlap.currentState = .nextParticipant
        overlap.isCompleted = false
        overlap.completeDate = nil
    }
}

#Preview {
    NavigationStack {
        JoinOnlineSessionView(prefilledInvite: "ABC-123")
    }
    .environmentObject(OnlineSessionService.shared)
}
