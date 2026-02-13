//
//  OnlineHostAuthService.swift
//  Overlap
//
//  Apple Sign In identity holder for online session hosts.
//

import AuthenticationServices
import Combine
import Foundation

struct OnlineHostAccount: Codable, Equatable {
    var appleUserID: String
    var displayName: String
    var email: String?
    var lastSignInDate: Date
}

final class OnlineHostAuthService: ObservableObject {
    static let shared = OnlineHostAuthService()

    @Published private(set) var account: OnlineHostAccount?
    @Published private(set) var lastErrorMessage: String?

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let account = "onlineHostAccount"
        static let userDisplayName = "userDisplayName"
    }

    private init() {
        if let data = defaults.data(forKey: Keys.account) {
            account = try? JSONDecoder().decode(OnlineHostAccount.self, from: data)
        }
    }

    var isSignedIn: Bool {
        account != nil
    }

    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                lastErrorMessage = "Could not read Apple credential."
                return
            }

            let formatter = PersonNameComponentsFormatter()
            let defaultName = persistedDisplayName() ?? "Host"
            let nameFromCredential = formatter.string(from: credential.fullName ?? PersonNameComponents()).trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = nameFromCredential.isEmpty ? defaultName : nameFromCredential

            let account = OnlineHostAccount(
                appleUserID: credential.user,
                displayName: resolvedName,
                email: credential.email,
                lastSignInDate: Date.now
            )

            persist(account)
            lastErrorMessage = nil

            if persistedDisplayName() == nil {
                persistDisplayName(resolvedName)
            }

        case .failure(let error):
            lastErrorMessage = error.localizedDescription
        }
    }

    func updateDisplayName(_ displayName: String) {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var account else { return }

        account.displayName = trimmed
        account.lastSignInDate = Date.now
        persist(account)

        if persistedDisplayName() != trimmed {
            persistDisplayName(trimmed)
        }
    }

    func signOut() {
        account = nil
        defaults.removeObject(forKey: Keys.account)
    }

    private func persist(_ account: OnlineHostAccount) {
        self.account = account
        if let data = try? JSONEncoder().encode(account) {
            defaults.set(data, forKey: Keys.account)
        }
    }

    private func persistedDisplayName() -> String? {
        defaults.string(forKey: Keys.userDisplayName)
    }

    private func persistDisplayName(_ displayName: String) {
        defaults.set(displayName, forKey: Keys.userDisplayName)
    }
}
