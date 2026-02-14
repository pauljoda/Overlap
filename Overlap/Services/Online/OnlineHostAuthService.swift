//
//  OnlineHostAuthService.swift
//  Overlap
//
//  Apple Sign In identity holder for online session hosts.
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import Security
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct OnlineHostAccount: Codable, Equatable {
    var appleUserID: String
    var displayName: String
    var email: String?
    var lastSignInDate: Date
    var isDevelopmentAccount: Bool

    init(
        appleUserID: String,
        displayName: String,
        email: String?,
        lastSignInDate: Date,
        isDevelopmentAccount: Bool = false
    ) {
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.email = email
        self.lastSignInDate = lastSignInDate
        self.isDevelopmentAccount = isDevelopmentAccount
    }

    private enum CodingKeys: String, CodingKey {
        case appleUserID
        case displayName
        case email
        case lastSignInDate
        case isDevelopmentAccount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appleUserID = try container.decode(String.self, forKey: .appleUserID)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        lastSignInDate = try container.decode(Date.self, forKey: .lastSignInDate)
        isDevelopmentAccount = try container.decodeIfPresent(Bool.self, forKey: .isDevelopmentAccount) ?? false
    }
}

enum OnlineHostAuthError: LocalizedError {
    case missingNonce
    case invalidIdentityToken

    var errorDescription: String? {
        switch self {
        case .missingNonce:
            return "Apple sign-in nonce was missing. Try again."
        case .invalidIdentityToken:
            return "Could not read Apple identity token."
        }
    }
}

final class OnlineHostAuthService: ObservableObject {
    static let shared = OnlineHostAuthService()

    @Published private(set) var account: OnlineHostAccount?
    @Published private(set) var lastErrorMessage: String?

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let account = "onlineHostAccount"
    }

    private init() {
        if let data = defaults.data(forKey: Keys.account) {
            account = try? JSONDecoder().decode(OnlineHostAccount.self, from: data)
        }
    }

    var isSignedIn: Bool {
        account != nil
    }

    #if DEBUG
    var usingDevelopmentAccount: Bool {
        account?.isDevelopmentAccount ?? false
    }
    #endif

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
        request.requestedScopes = [.fullName, .email]
        let nonce = Self.randomNonceString()
        request.nonce = Self.sha256(nonce)
        return nonce
    }

    @MainActor
    func handleAppleSignInResult(
        _ result: Result<ASAuthorization, Error>,
        rawNonce: String?
    ) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                lastErrorMessage = "Could not read Apple credential."
                return
            }

            let formatter = PersonNameComponentsFormatter()
            let defaultName = account?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let nameFromCredential = formatter
                .string(from: credential.fullName ?? PersonNameComponents())
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = nameFromCredential.isEmpty ? defaultName : nameFromCredential

            do {
                let resolvedUserID = try await resolveHostIdentifier(
                    credential: credential,
                    rawNonce: rawNonce
                )

                let account = OnlineHostAccount(
                    appleUserID: resolvedUserID,
                    displayName: resolvedName,
                    email: credential.email,
                    lastSignInDate: Date.now,
                    isDevelopmentAccount: false
                )

                persist(account)
                lastErrorMessage = nil
            } catch {
                lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }

        case .failure(let error):
            lastErrorMessage = error.localizedDescription
        }
    }

    func signOut() {
        account = nil
        defaults.removeObject(forKey: Keys.account)

        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        if FirebaseApp.app() != nil {
            try? Auth.auth().signOut()
        }
        #endif
    }

    #if DEBUG
    func signInForDevelopment(displayName: String?) {
        let trimmed = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedName = trimmed.isEmpty ? "Dev Host" : trimmed

        signOut()

        let account = OnlineHostAccount(
            appleUserID: "debug-host",
            displayName: resolvedName,
            email: nil,
            lastSignInDate: Date.now,
            isDevelopmentAccount: true
        )

        persist(account)
        lastErrorMessage = nil
    }
    #endif

    private func persist(_ account: OnlineHostAccount) {
        self.account = account
        if let data = try? JSONEncoder().encode(account) {
            defaults.set(data, forKey: Keys.account)
        }
    }

    private func resolveHostIdentifier(
        credential: ASAuthorizationAppleIDCredential,
        rawNonce: String?
    ) async throws -> String {
        #if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else {
            return credential.user
        }

        guard let rawNonce, !rawNonce.isEmpty else {
            throw OnlineHostAuthError.missingNonce
        }

        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8),
              !idTokenString.isEmpty
        else {
            throw OnlineHostAuthError.invalidIdentityToken
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )

        let result = try await Auth.auth().signIn(with: firebaseCredential)
        return result.user.uid
        #else
        return credential.user
        #endif
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        result.reserveCapacity(length)

        for _ in 0..<length {
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode == errSecSuccess {
                result.append(charset[Int(random) % charset.count])
            } else if let fallback = charset.randomElement() {
                result.append(fallback)
            }
        }

        return result
    }
}
