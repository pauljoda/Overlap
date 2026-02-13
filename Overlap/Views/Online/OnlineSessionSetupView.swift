//
//  OnlineSessionSetupView.swift
//  Overlap
//
//  Host setup flow for paid online sessions.
//

import AuthenticationServices
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnlineSessionSetupView: View {
    let questionnaire: Questionnaire

    @Environment(\.navigationPath) private var navigationPath
    @Environment(\.onlineSubscriptionService) private var subscriptionService
    @Environment(\.onlineHostAuthService) private var authService
    @Environment(\.onlineSessionService) private var sessionService

    @StateObject private var userPreferences = UserPreferences.shared

    @State private var hostDisplayName = ""
    @State private var activeSessionID: String?
    @State private var errorMessage: String?
    @State private var didCopyCode = false

    private var activeSession: HostedOnlineSession? {
        guard let activeSessionID else { return nil }
        return sessionService.hostedSession(id: activeSessionID)
    }

    private var canCreateSession: Bool {
        subscriptionService.hasOnlineHostAccess
            && authService.isSignedIn
            && !hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GlassScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xl) {
                    header
                    subscriptionGate
                    authSection
                    hostNameSection
                    sessionActions
                    inviteSection
                }
                .padding(Tokens.Spacing.xl)
                .frame(maxWidth: Tokens.Size.maxContentWidth)
            }
        }
        .navigationTitle("Online Host")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Online Setup", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await subscriptionService.refreshFromStoreKit()
            bootstrapDisplayName()
            bootstrapSessionIfAvailable()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Text(questionnaire.title)
                .font(.title2)
                .fontWeight(.bold)

            Text("Host an online session with invite links and code fallback.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Participant limit: \(OnlineConfiguration.maxParticipants) • Expires in \(OnlineConfiguration.sessionLifetimeDays) days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var subscriptionGate: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Label("Host Subscription", systemImage: "crown.fill")
                .font(.headline)

            Text(subscriptionService.subscriptionSummary)
                .font(.footnote)
                .foregroundColor(.secondary)

            Text("Monthly: \(currency(OnlineConfiguration.monthlyPriceUSD)) • Yearly: \(currency(OnlineConfiguration.yearlyPriceUSD))")
                .font(.caption)
                .foregroundColor(.secondary)

            #if DEBUG
            HStack(spacing: Tokens.Spacing.s) {
                Button(subscriptionService.hasOnlineHostAccess ? "Disable Dev Access" : "Enable Dev Access") {
                    if subscriptionService.hasOnlineHostAccess {
                        subscriptionService.setDebugOverride(false)
                        subscriptionService.clearEntitlement()
                    } else {
                        subscriptionService.setDebugOverride(true)
                        subscriptionService.grantDevelopmentEntitlement()
                    }
                }
                .buttonStyle(.bordered)

                Button("Grant 30d") {
                    subscriptionService.grantDevelopmentEntitlement()
                }
                .buttonStyle(.bordered)
            }
            #else
            Button("Purchase Online Hosting") {
                errorMessage = "StoreKit purchase flow will be connected in the next step."
            }
            .buttonStyle(.borderedProminent)
            #endif
        }
        .padding()
        .standardGlassCard()
    }

    private var authSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Label("Host Sign-In", systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)

            if let account = authService.account {
                Text("Signed in as \(account.displayName)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text("Sign in with Apple to host online sessions.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    authService.handleAppleSignInResult(result)
                    if let account = authService.account {
                        hostDisplayName = account.displayName
                    }
                }
            )
            .frame(height: 44)

            if authService.isSignedIn {
                Button("Sign Out") {
                    authService.signOut()
                    activeSessionID = nil
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .standardGlassCard()
    }

    private var hostNameSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Label("Host Display Name", systemImage: "text.cursor")
                .font(.headline)

            TextField("Display name", text: $hostDisplayName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .onSubmit(saveHostDisplayName)

            Text("Guests will see this name in the session lobby.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .standardGlassCard()
    }

    private var sessionActions: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Label("Session", systemImage: "network.badge.shield.half.filled")
                .font(.headline)

            Button {
                createOrRefreshSession()
            } label: {
                Text(activeSession == nil ? "Create Online Session" : "Refresh Invite")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canCreateSession)

            if !canCreateSession {
                Text("Requires active host access, Apple sign-in, and a display name.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .standardGlassCard()
    }

    @ViewBuilder
    private var inviteSection: some View {
        if let activeSession {
            VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                Label("Invite Guests", systemImage: "square.and.arrow.up")
                    .font(.headline)

                Text("Share Link")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(activeSession.shareURL.absoluteString)
                    .font(.footnote)
                    .textSelection(.enabled)

                ShareLink(
                    item: activeSession.shareURL,
                    subject: Text("Join my Overlap session"),
                    message: Text("Join \"\(activeSession.questionnaireTitle)\" on Overlap. If needed, use code \(activeSession.inviteCode).")
                ) {
                    Label("Share Invite", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Text("Code: \(activeSession.inviteCode)")
                        .font(.headline)

                    Spacer()

                    Button(didCopyCode ? "Copied" : "Copy") {
                        copyInviteCode(activeSession.inviteCode)
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    Text("Participants: \(activeSession.participantDisplayNames.count)/\(activeSession.maxParticipants)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Expires \(activeSession.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: Tokens.Spacing.s) {
                    Button("Extend 30 Days") {
                        sessionService.extendSession(sessionID: activeSession.id)
                    }
                    .buttonStyle(.bordered)

                    Button("Guest Join Preview") {
                        navigate(
                            to: .joinSession(prefilledInvite: activeSession.inviteCode),
                            using: navigationPath
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .standardGlassCard()
        }
    }

    private func createOrRefreshSession() {
        guard canCreateSession else {
            errorMessage = "Complete subscription, sign-in, and display name first."
            return
        }

        saveHostDisplayName()

        guard let host = authService.account else {
            errorMessage = "Sign in with Apple first."
            return
        }

        let session = sessionService.createHostedSession(
            questionnaire: questionnaire,
            host: host,
            hostDisplayName: hostDisplayName
        )

        activeSessionID = session.id
        didCopyCode = false
    }

    private func bootstrapDisplayName() {
        if hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hostDisplayName = authService.account?.displayName
                ?? userPreferences.userDisplayName
                ?? ""
        }
    }

    private func bootstrapSessionIfAvailable() {
        guard let host = authService.account,
              let existing = sessionService.latestHostedSession(
                questionnaireID: questionnaire.id,
                hostAppleUserID: host.appleUserID
              )
        else {
            return
        }

        activeSessionID = existing.id
    }

    private func saveHostDisplayName() {
        let trimmed = hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        hostDisplayName = trimmed
        userPreferences.setDisplayName(trimmed)
        authService.updateDisplayName(trimmed)
    }

    private func copyInviteCode(_ inviteCode: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = inviteCode
        #endif
        didCopyCode = true
    }

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$\(value)"
    }
}

#Preview {
    NavigationStack {
        OnlineSessionSetupView(questionnaire: SampleData.sampleQuestionnaire)
    }
}
