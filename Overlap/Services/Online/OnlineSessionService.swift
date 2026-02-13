//
//  OnlineSessionService.swift
//  Overlap
//
//  Backend-ready session API with local persistence stubs.
//

import Foundation
import Combine

struct HostedOnlineSession: Codable, Hashable, Identifiable {
    enum Status: String, Codable {
        case open
        case closed
        case expired
    }

    var id: String
    var questionnaireID: UUID
    var questionnaireTitle: String
    var hostAppleUserID: String
    var hostDisplayName: String
    var createdAt: Date
    var expiresAt: Date
    var maxParticipants: Int
    var inviteToken: String
    var inviteCode: String
    var participantDisplayNames: [String]
    var status: Status

    var shareURL: URL {
        OnlineConfiguration.baseInviteURL
            .appending(path: "j")
            .appending(path: inviteToken)
    }

    var isExpired: Bool {
        expiresAt < Date.now || status == .expired
    }
}

struct JoinedOnlineSession: Hashable {
    var sessionID: String
    var questionnaireTitle: String
    var hostDisplayName: String
    var participantDisplayNames: [String]
    var expiresAt: Date
}

enum OnlineSessionError: LocalizedError {
    case sessionNotFound
    case sessionExpired
    case sessionClosed
    case participantLimitReached
    case invalidDisplayName

    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "That invite link/code is not valid."
        case .sessionExpired:
            return "This session has expired. Ask the host to extend it."
        case .sessionClosed:
            return "This session is no longer open for responses."
        case .participantLimitReached:
            return "This session has reached the participant limit."
        case .invalidDisplayName:
            return "Enter a display name to continue."
        }
    }
}

final class OnlineSessionService: ObservableObject {
    static let shared = OnlineSessionService()

    @Published private(set) var sessionsByID: [String: HostedOnlineSession] = [:]

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sessionsByID = "onlineHostedSessionsByID"
    }

    private init() {
        loadPersistedSessions()
    }

    func createHostedSession(
        questionnaire: Questionnaire,
        host: OnlineHostAccount,
        hostDisplayName: String
    ) -> HostedOnlineSession {
        let trimmedHostName = sanitizeDisplayName(hostDisplayName)

        let session = HostedOnlineSession(
            id: UUID().uuidString,
            questionnaireID: questionnaire.id,
            questionnaireTitle: questionnaire.title,
            hostAppleUserID: host.appleUserID,
            hostDisplayName: trimmedHostName,
            createdAt: Date.now,
            expiresAt: Calendar.current.date(byAdding: .day, value: OnlineConfiguration.sessionLifetimeDays, to: Date.now) ?? Date.now,
            maxParticipants: OnlineConfiguration.maxParticipants,
            inviteToken: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            inviteCode: Self.generateInviteCode(),
            participantDisplayNames: [trimmedHostName],
            status: .open
        )

        sessionsByID[session.id] = session
        persistSessions()

        return session
    }

    func hostedSession(id: String) -> HostedOnlineSession? {
        guard var session = sessionsByID[id] else { return nil }

        if session.expiresAt < Date.now, session.status == .open {
            session.status = .expired
            sessionsByID[id] = session
            persistSessions()
        }

        return session
    }

    func latestHostedSession(
        questionnaireID: UUID,
        hostAppleUserID: String
    ) -> HostedOnlineSession? {
        let candidate = sessionsByID.values
            .filter { session in
                session.questionnaireID == questionnaireID
                    && session.hostAppleUserID == hostAppleUserID
            }
            .sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }
            .first

        guard let candidate else { return nil }
        return hostedSession(id: candidate.id)
    }

    func extendSession(sessionID: String, days: Int = OnlineConfiguration.sessionLifetimeDays) {
        guard var session = sessionsByID[sessionID] else { return }
        let anchor = max(Date.now, session.expiresAt)
        session.expiresAt = Calendar.current.date(byAdding: .day, value: days, to: anchor) ?? anchor
        if session.status == .expired {
            session.status = .open
        }
        sessionsByID[sessionID] = session
        persistSessions()
    }

    func closeSession(sessionID: String) {
        guard var session = sessionsByID[sessionID] else { return }
        session.status = .closed
        sessionsByID[sessionID] = session
        persistSessions()
    }

    func joinSession(invite: String, displayName: String) throws -> JoinedOnlineSession {
        let trimmedInvite = invite.trimmingCharacters(in: .whitespacesAndNewlines)
        let participantName = sanitizeDisplayName(displayName)

        guard !participantName.isEmpty else {
            throw OnlineSessionError.invalidDisplayName
        }

        guard !trimmedInvite.isEmpty,
              let sessionID = findSessionID(forInvite: trimmedInvite),
              var session = sessionsByID[sessionID]
        else {
            throw OnlineSessionError.sessionNotFound
        }

        if session.status == .closed {
            throw OnlineSessionError.sessionClosed
        }

        if session.expiresAt < Date.now {
            session.status = .expired
            sessionsByID[sessionID] = session
            persistSessions()
            throw OnlineSessionError.sessionExpired
        }

        let existingIndex = session.participantDisplayNames.firstIndex {
            $0.caseInsensitiveCompare(participantName) == .orderedSame
        }

        if existingIndex == nil,
           session.participantDisplayNames.count >= session.maxParticipants {
            throw OnlineSessionError.participantLimitReached
        }

        if existingIndex == nil {
            session.participantDisplayNames.append(participantName)
            sessionsByID[sessionID] = session
            persistSessions()
        }

        return JoinedOnlineSession(
            sessionID: session.id,
            questionnaireTitle: session.questionnaireTitle,
            hostDisplayName: session.hostDisplayName,
            participantDisplayNames: session.participantDisplayNames,
            expiresAt: session.expiresAt
        )
    }

    func parseInvite(from url: URL) -> String? {
        if let token = parseToken(from: url) {
            return token
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
           !code.isEmpty {
            return code.uppercased()
        }

        return nil
    }

    private func parseToken(from url: URL) -> String? {
        if url.scheme == OnlineConfiguration.inviteScheme,
           url.host == "join",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
           !token.isEmpty {
            return token
        }

        if url.host == OnlineConfiguration.inviteHost {
            let path = url.path
            let prefix = OnlineConfiguration.invitePathPrefix
            if path.hasPrefix(prefix) {
                let token = String(path.dropFirst(prefix.count))
                return token.isEmpty ? nil : token
            }
        }

        return nil
    }

    private func findSessionID(forInvite invite: String) -> String? {
        let normalizedInvite = invite.trimmingCharacters(in: .whitespacesAndNewlines)

        if let direct = sessionsByID.first(where: { $0.value.inviteToken.caseInsensitiveCompare(normalizedInvite) == .orderedSame }) {
            return direct.key
        }

        if let directCode = sessionsByID.first(where: { $0.value.inviteCode.caseInsensitiveCompare(normalizedInvite) == .orderedSame }) {
            return directCode.key
        }

        if let url = URL(string: normalizedInvite),
           let parsed = parseInvite(from: url) {
            return findSessionID(forInvite: parsed)
        }

        return nil
    }

    private func sanitizeDisplayName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadPersistedSessions() {
        guard let data = defaults.data(forKey: Keys.sessionsByID) else { return }
        guard let decoded = try? JSONDecoder().decode([String: HostedOnlineSession].self, from: data) else { return }
        sessionsByID = decoded
    }

    private func persistSessions() {
        guard let data = try? JSONEncoder().encode(sessionsByID) else { return }
        defaults.set(data, forKey: Keys.sessionsByID)
    }

    private static func generateInviteCode() -> String {
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let chunk = (0..<3).map { _ in letters.randomElement()! }
        let chunkTwo = (0..<3).map { _ in letters.randomElement()! }
        return String(chunk + ["-"] + chunkTwo)
    }
}
