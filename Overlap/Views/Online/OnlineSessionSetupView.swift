//
//  OnlineSessionSetupView.swift
//  Overlap
//
//  Host setup flow for paid online sessions.
//  Shows the questionnaire preview with auth/subscription sections, matching
//  the local "Begin Local Overlap" detail page pattern.
//

import AuthenticationServices
import SwiftData
import SwiftUI

struct OnlineSessionSetupView: View {
    let questionnaire: Questionnaire

    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @EnvironmentObject private var subscriptionService: OnlineSubscriptionService
    @EnvironmentObject private var authService: OnlineHostAuthService
    @EnvironmentObject private var sessionService: OnlineSessionService
    @AppStorage("userDisplayName") private var userDisplayName = ""

    @State private var activeSessionID: String?
    @State private var activeOverlapID: UUID?
    @State private var errorMessage: String?
    @State private var pendingAppleSignInNonce: String?
    @State private var isSessionActionInFlight = false
    @State private var showingSubscriptionFlyout = false

    private var activeSession: HostedOnlineSession? {
        guard let activeSessionID else { return nil }
        return sessionService.hostedSession(id: activeSessionID)
    }

    @MainActor
    private var linkedOverlap: Overlap? {
        guard let activeOverlapID else { return nil }
        return try? fetchOverlap(id: activeOverlapID)
    }

    private var resolvedHostDisplayName: String {
        // Try Apple account name first, then fall back to AppStorage display name
        let appleName = authService.account?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !appleName.isEmpty { return appleName }
        return userDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreateSession: Bool {
        subscriptionService.hasOnlineHostAccess
            && authService.isSignedIn
            && !resolvedHostDisplayName.isEmpty
    }

    private var canAttemptPrimaryAction: Bool {
        !isSessionActionInFlight
    }

    private var primaryActionTitle: String {
        if !subscriptionService.hasOnlineHostAccess {
            return "Unlock Online Hosting"
        }

        if !authService.isSignedIn {
            return "Sign In to Host"
        }

        if resolvedHostDisplayName.isEmpty {
            return "Set Display Name in Settings"
        }

        if activeSession == nil {
            return Tokens.Strings.beginOnlineOverlap
        }

        return linkedOverlap == nil ? Tokens.Strings.beginOnlineOverlap : "Open In Progress"
    }

    private var primaryActionIcon: String {
        if !subscriptionService.hasOnlineHostAccess {
            return "crown.fill"
        }

        if !authService.isSignedIn {
            return "person.badge.key.fill"
        }

        return activeSession == nil ? "icloud.fill" : "play.fill"
    }

    private var primaryActionTint: Color {
        subscriptionService.hasOnlineHostAccess ? .blue : .orange
    }

    var body: some View {
        ZStack {
            GlassScreen {
                VStack(spacing: Tokens.Spacing.xxl) {
                    // Questionnaire preview header — matches saved detail pattern
                    QuestionnaireIcon(questionnaire: questionnaire, size: .medium)

                    VStack(spacing: Tokens.Spacing.s) {
                        Text(questionnaire.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("Host a live online session with invite links.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Questionnaire info card
                    overlapInfoCard

                    // Auth section
                    authSection

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
                    title: isSessionActionInFlight ? "Working..." : primaryActionTitle,
                    icon: primaryActionIcon,
                    isEnabled: canAttemptPrimaryAction && !resolvedHostDisplayName.isEmpty,
                    tintColor: primaryActionTint
                ) {
                    Task {
                        await handlePrimaryAction()
                    }
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .navigationTitle("Online Host")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Online Setup", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showingSubscriptionFlyout) {
            SubscriptionFlyout()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.ultraThinMaterial)
                .interactiveDismissDisabled()
        }
        .onChange(of: subscriptionService.hasOnlineHostAccess) { _, hasAccess in
            if hasAccess {
                showingSubscriptionFlyout = false
            }
        }
        .onReceive(sessionService.$sessionsByID) { _ in
            guard let session = activeSession else { return }
            try? syncLinkedOverlap(with: session)
        }
        .task {
            await subscriptionService.loadProducts()
            await subscriptionService.refreshFromStoreKit()
            await bootstrapSessionIfAvailable()

            if !subscriptionService.hasOnlineHostAccess {
                showingSubscriptionFlyout = true
            }
        }
    }

    // MARK: - Overlap Info Card

    private var overlapInfoCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Questionnaire", icon: "doc.text.fill")

            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                Text(questionnaire.instructions)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Tokens.Spacing.m) {
                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(questionnaire.questions.count) questions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)

                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(questionnaire.author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .standardGlassCard()
        }
    }

    // MARK: - Auth Section

    @ViewBuilder
    private var authSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            if authService.isSignedIn {
                SectionHeader(title: "Account", icon: "person.crop.circle.badge.checkmark")

                HStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        if !resolvedHostDisplayName.isEmpty {
                            Text(resolvedHostDisplayName)
                                .font(.body)
                                .fontWeight(.medium)
                        } else {
                            Text("Set a display name in Settings")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }

                        Text(subscriptionService.hasOnlineHostAccess
                             ? "Online hosting unlocked"
                             : "Subscription required to host")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        #if DEBUG
                        if authService.account?.isDevelopmentAccount == true {
                            Text("Development mode")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        #endif
                    }

                    Spacer()

                    if !subscriptionService.hasOnlineHostAccess {
                        Button {
                            showingSubscriptionFlyout = true
                        } label: {
                            Image(systemName: "crown")
                                .font(.body)
                                .foregroundColor(.orange)
                                .frame(width: Tokens.Size.buttonCompact, height: Tokens.Size.buttonCompact)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(Circle())
                    }

                    Button {
                        authService.signOut()
                        activeSessionID = nil
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.body)
                            .foregroundColor(.red)
                            .frame(width: Tokens.Size.buttonCompact, height: Tokens.Size.buttonCompact)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                }
                .padding(Tokens.Spacing.l)
                .standardGlassCard()
            } else {
                SectionHeader(title: "Sign In", icon: "person.crop.circle.badge.checkmark")

                VStack(spacing: Tokens.Spacing.l) {
                    Text("Sign in with Apple to host online sessions and invite participants.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            pendingAppleSignInNonce = authService.prepareAppleSignInRequest(request)
                        },
                        onCompletion: { result in
                            Task {
                                await authService.handleAppleSignInResult(
                                    result,
                                    rawNonce: pendingAppleSignInNonce
                                )
                                pendingAppleSignInNonce = nil
                                // Backfill Apple name into AppStorage if needed
                                if let name = authService.account?.displayName,
                                   !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                   userDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    userDisplayName = name
                                }
                                await bootstrapSessionIfAvailable()
                            }
                        }
                    )
                    .frame(height: Tokens.Size.buttonCompact)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.m))

                    #if DEBUG
                    Button("Use Dev Host") {
                        authService.signInForDevelopment(displayName: nil)
                    }
                    .buttonStyle(.bordered)
                    #endif
                }
                .padding(Tokens.Spacing.l)
                .standardGlassCard()
            }

            if let authError = authService.lastErrorMessage, !authError.isEmpty {
                HStack(spacing: Tokens.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(authError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if !authService.isSignedIn {
                HStack(spacing: Tokens.Spacing.s) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Sign in with Apple to continue.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if resolvedHostDisplayName.isEmpty {
                HStack(spacing: Tokens.Spacing.s) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Set a display name in Settings to host sessions.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else if !subscriptionService.hasOnlineHostAccess {
                HStack(spacing: Tokens.Spacing.s) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Online hosting requires an active subscription.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func handlePrimaryAction() async {
        guard subscriptionService.hasOnlineHostAccess else {
            showingSubscriptionFlyout = true
            return
        }

        guard authService.isSignedIn else {
            errorMessage = "Sign in with Apple first."
            return
        }

        guard !resolvedHostDisplayName.isEmpty else {
            errorMessage = "Set a display name in Settings first."
            return
        }

        if let activeSession {
            do {
                try upsertLocalOverlapAndNavigate(for: activeSession)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            return
        }

        await createOrRefreshSession()
    }

    @MainActor
    private func createOrRefreshSession() async {
        isSessionActionInFlight = true
        defer { isSessionActionInFlight = false }

        guard canCreateSession else {
            errorMessage = "Complete subscription and sign-in first."
            return
        }

        guard let host = authService.account else {
            errorMessage = "Sign in first."
            return
        }

        do {
            let session = try await sessionService.createHostedSessionOnline(
                questionnaire: questionnaire,
                host: host,
                hostDisplayName: resolvedHostDisplayName
            )

            activeSessionID = session.id
            sessionService.startSessionObservation(sessionID: session.id)
            try upsertLocalOverlapAndNavigate(for: session)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func bootstrapSessionIfAvailable() async {
        guard let host = authService.account else {
            activeSessionID = nil
            return
        }

        do {
            let existing = try await sessionService.latestHostedSessionOnline(
                questionnaireID: questionnaire.id,
                hostAppleUserID: host.appleUserID
            )
            activeSessionID = existing?.id
            if let existing {
                sessionService.startSessionObservation(sessionID: existing.id)
                activeOverlapID = try fetchOverlap(forHostedSessionID: existing.id)?.id
            } else {
                activeOverlapID = nil
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func upsertLocalOverlapAndNavigate(for hostedSession: HostedOnlineSession) throws {
        let overlap: Overlap

        if let existing = try fetchOverlap(forHostedSessionID: hostedSession.id) {
            existing.onlineInviteCode = hostedSession.inviteCode
            existing.onlineParticipantID = hostedSession.hostAppleUserID
            if existing.onlineParticipantDisplayName == nil {
                existing.onlineParticipantDisplayName = resolvedHostDisplayName
            }
            _ = OnlineSessionSnapshotApplier.apply(session: hostedSession, to: existing)
            overlap = existing
        } else {
            let created = Overlap(
                participants: hostedSession.participantDisplayNames,
                isOnline: true,
                questionnaire: questionnaire,
                randomizeQuestions: false,
                currentState: .instructions
            )
            created.onlineSessionID = hostedSession.id
            created.onlineInviteCode = hostedSession.inviteCode
            created.onlineParticipantID = hostedSession.hostAppleUserID
            created.onlineParticipantDisplayName = resolvedHostDisplayName
            _ = OnlineSessionSnapshotApplier.apply(session: hostedSession, to: created)
            modelContext.insert(created)
            overlap = created
        }

        try modelContext.save()
        activeOverlapID = overlap.id
        navigate(to: overlap, using: navigationPath)
    }

    @MainActor
    private func syncLinkedOverlap(with hostedSession: HostedOnlineSession) throws {
        guard let linked = try fetchOverlap(forHostedSessionID: hostedSession.id) else { return }

        linked.onlineInviteCode = hostedSession.inviteCode
        _ = OnlineSessionSnapshotApplier.apply(session: hostedSession, to: linked)
        try modelContext.save()
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
    private func fetchOverlap(id: UUID) throws -> Overlap? {
        let descriptor = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { overlap in
                overlap.id == id
            }
        )

        return try modelContext.fetch(descriptor).first
    }

}

#Preview {
    NavigationStack {
        OnlineSessionSetupView(questionnaire: SampleData.sampleQuestionnaire)
    }
    .environmentObject(OnlineSubscriptionService.shared)
    .environmentObject(OnlineHostAuthService.shared)
    .environmentObject(OnlineSessionService.shared)
}
