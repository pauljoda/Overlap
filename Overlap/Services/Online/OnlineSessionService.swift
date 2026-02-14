//
//  OnlineSessionService.swift
//  Overlap
//
//  Backend-aware session API with local fallback stubs.
//

import Foundation
import Combine
import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct HostedOnlineSession: Codable, Hashable, Identifiable {
    enum Status: String, Codable {
        case open
        case closed
        case expired
    }

    enum Phase: String, Codable {
        case lobby
        case active
        case awaiting
        case complete
    }

    enum ParticipantStatus: String, Codable {
        case invited
        case joined
        case answering
        case submitted
    }

    var id: String
    var questionnaireID: UUID
    var questionnaireTitle: String
    var questionnaireInformation: String
    var questionnaireInstructions: String
    var questionnaireQuestions: [String]
    var hostAppleUserID: String
    var hostDisplayName: String
    var createdAt: Date
    var updatedAt: Date
    var expiresAt: Date
    var maxParticipants: Int
    var inviteToken: String
    var inviteCode: String
    var participantDisplayNames: [String]
    var participantIDsByDisplayName: [String: String]
    var participantStatuses: [String: String]
    var participantAnsweredCounts: [String: Int]
    var participantQuestionIndices: [String: Int]
    var participantAnswers: [String: [String: String]]
    var totalQuestions: Int
    var questionnaireIconEmoji: String
    var questionnaireStartColorHex: String
    var questionnaireEndColorHex: String
    var phase: Phase
    var status: Status

    var shareURL: URL {
        URL(string: "\(OnlineConfiguration.inviteScheme)://join?token=\(inviteToken)")!
    }

    var isExpired: Bool {
        expiresAt < Date.now || status == .expired
    }
}

struct JoinedOnlineSession: Hashable {
    var sessionID: String
    var questionnaireID: UUID
    var questionnaireTitle: String
    var questionnaireInformation: String
    var questionnaireInstructions: String
    var questionnaireQuestions: [String]
    var questionnaireIconEmoji: String
    var questionnaireStartColorHex: String
    var questionnaireEndColorHex: String
    var hostDisplayName: String
    var participantDisplayNames: [String]
    var participantIDsByDisplayName: [String: String]
    var participantStatuses: [String: String]
    var participantQuestionIndices: [String: Int]
    var participantAnsweredCounts: [String: Int]
    var phase: HostedOnlineSession.Phase
    var participantID: String
    var participantDisplayName: String
    var expiresAt: Date
}

struct SessionPreview {
    var sessionID: String
    var questionnaireTitle: String
    var hostDisplayName: String
    var participantCount: Int
    var maxParticipants: Int
    var iconEmoji: String
    var startColorHex: String
    var endColorHex: String
    var expiresAt: Date
}

enum OnlineSessionError: LocalizedError {
    case sessionNotFound
    case sessionExpired
    case sessionClosed
    case participantLimitReached
    case invalidDisplayName
    case participantNotInSession
    case backendFailure(String)

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
        case .participantNotInSession:
            return "You are no longer part of this session."
        case .backendFailure(let message):
            return message
        }
    }
}

@MainActor
final class OnlineSessionService: ObservableObject {
    static let shared = OnlineSessionService()

    @Published private(set) var sessionsByID: [String: HostedOnlineSession] = [:]

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sessionsByID = "onlineHostedSessionsByID"
    }

    private enum FirestoreFields {
        static let id = "id"
        static let questionnaireID = "questionnaireID"
        static let questionnaireTitle = "questionnaireTitle"
        static let questionnaireInformation = "questionnaireInformation"
        static let questionnaireInstructions = "questionnaireInstructions"
        static let questionnaireQuestions = "questionnaireQuestions"
        static let hostAppleUserID = "hostAppleUserID"
        static let hostDisplayName = "hostDisplayName"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let expiresAt = "expiresAt"
        static let maxParticipants = "maxParticipants"
        static let inviteToken = "inviteToken"
        static let inviteCode = "inviteCode"
        static let participantDisplayNames = "participantDisplayNames"
        static let participantIDsByDisplayName = "participantIDsByDisplayName"
        static let participantStatuses = "participantStatuses"
        static let participantAnsweredCounts = "participantAnsweredCounts"
        static let participantQuestionIndices = "participantQuestionIndices"
        static let participantAnswers = "participantAnswers"
        static let totalQuestions = "totalQuestions"
        static let questionnaireIconEmoji = "questionnaireIconEmoji"
        static let questionnaireStartColorHex = "questionnaireStartColorHex"
        static let questionnaireEndColorHex = "questionnaireEndColorHex"
        static let phase = "phase"
        static let status = "status"
    }

    #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
    private var activeSessionListeners: [String: ListenerRegistration] = [:]
    #endif

    private init() {
        loadPersistedSessions()
    }

    var backendSummary: String {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        return shouldUseFirebaseBackend ? "Firebase Firestore" : "Local fallback"
        #else
        return "Local fallback"
        #endif
    }

    // MARK: - Backend-aware async API

    func createHostedSessionOnline(
        questionnaire: Questionnaire,
        host: OnlineHostAccount,
        hostDisplayName: String
    ) async throws -> HostedOnlineSession {
        let session = makeHostedSession(
            questionnaire: questionnaire,
            host: host,
            hostDisplayName: hostDisplayName
        )

        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            try await writeSessionToFirestore(session)
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #endif

        sessionsByID[session.id] = session
        persistSessions()
        return session
    }

    func latestHostedSessionOnline(
        questionnaireID: UUID,
        hostAppleUserID: String
    ) async throws -> HostedOnlineSession? {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            if let remote = try await fetchLatestSessionFromFirestore(
                questionnaireID: questionnaireID,
                hostAppleUserID: hostAppleUserID
            ) {
                sessionsByID[remote.id] = remote
                persistSessions()
                return hostedSession(id: remote.id)
            }
            return nil
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return latestHostedSession(
            questionnaireID: questionnaireID,
            hostAppleUserID: hostAppleUserID
        )
        #endif
    }

    func extendSessionOnline(
        sessionID: String,
        days: Int = 30
    ) async throws {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            try await extendSessionInFirestore(sessionID: sessionID, days: days)
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        extendSession(sessionID: sessionID, days: days)
        #endif
    }

    func closeSessionOnline(sessionID: String) async throws {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            try await closeSessionInFirestore(sessionID: sessionID)
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        closeSession(sessionID: sessionID)
        #endif
    }

    func joinSessionOnline(
        invite: String,
        displayName: String,
        participantID: String
    ) async throws -> JoinedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let joined = try await joinSessionInFirestore(
                invite: invite,
                displayName: displayName,
                participantID: participantID
            )
            return joined
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return try joinSession(
            invite: invite,
            displayName: displayName,
            participantID: participantID
        )
        #endif
    }

    func previewSession(invite: String) async throws -> SessionPreview {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let normalizedInvite = normalizedInvite(invite)
            guard !normalizedInvite.isEmpty else {
                throw OnlineSessionError.sessionNotFound
            }
            guard let document = try await findSessionDocument(invite: normalizedInvite),
                  let session = session(from: document)
            else {
                throw OnlineSessionError.sessionNotFound
            }
            return SessionPreview(
                sessionID: session.id,
                questionnaireTitle: session.questionnaireTitle,
                hostDisplayName: session.hostDisplayName,
                participantCount: session.participantDisplayNames.count,
                maxParticipants: session.maxParticipants,
                iconEmoji: session.questionnaireIconEmoji,
                startColorHex: session.questionnaireStartColorHex,
                endColorHex: session.questionnaireEndColorHex,
                expiresAt: session.expiresAt
            )
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return try previewSessionLocally(invite: invite)
        #endif
    }

    func addParticipantOnline(sessionID: String, displayName: String) async throws -> HostedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let updated = try await mutateSessionInFirestore(sessionID: sessionID) { session in
                try Self.addParticipant(displayName: displayName, to: &session)
            }
            sessionsByID[updated.id] = updated
            persistSessions()
            return updated
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return try addParticipantLocally(sessionID: sessionID, displayName: displayName)
        #endif
    }

    func renameParticipantOnline(
        sessionID: String,
        oldDisplayName: String,
        newDisplayName: String
    ) async throws -> HostedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let updated = try await mutateSessionInFirestore(sessionID: sessionID) { session in
                try Self.renameParticipant(
                    oldDisplayName: oldDisplayName,
                    newDisplayName: newDisplayName,
                    in: &session
                )
            }
            sessionsByID[updated.id] = updated
            persistSessions()
            return updated
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return try renameParticipantLocally(
            sessionID: sessionID,
            oldDisplayName: oldDisplayName,
            newDisplayName: newDisplayName
        )
        #endif
    }

    func removeParticipantOnline(
        sessionID: String,
        displayName: String
    ) async throws -> HostedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let updated = try await mutateSessionInFirestore(sessionID: sessionID) { session in
                try Self.removeParticipant(displayName: displayName, from: &session)
            }
            sessionsByID[updated.id] = updated
            persistSessions()
            return updated
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return try removeParticipantLocally(sessionID: sessionID, displayName: displayName)
        #endif
    }

    func submitParticipantAnswerOnline(
        sessionID: String,
        participantID: String,
        questionIndex: Int,
        answer: Answer
    ) async throws -> HostedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let updated = try await mutateSessionInFirestore(sessionID: sessionID) { session in
                try Self.applyAnswer(
                    participantID: participantID,
                    questionIndex: questionIndex,
                    answer: answer,
                    to: &session
                )
            }
            sessionsByID[updated.id] = updated
            persistSessions()
            return updated
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        return try submitParticipantAnswerLocally(
            sessionID: sessionID,
            participantID: participantID,
            questionIndex: questionIndex,
            answer: answer
        )
        #endif
    }

    func beginSessionOnline(sessionID: String) async throws -> HostedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let updated = try await mutateSessionInFirestore(sessionID: sessionID) { session in
                session.phase = .active
                session.updatedAt = Date.now
            }
            sessionsByID[updated.id] = updated
            persistSessions()
            return updated
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        guard var session = sessionsByID[sessionID] else {
            throw OnlineSessionError.sessionNotFound
        }
        session.phase = .active
        session.updatedAt = Date.now
        sessionsByID[sessionID] = session
        persistSessions()
        return session
        #endif
    }

    func beginParticipantOnline(
        sessionID: String,
        participantID: String
    ) async throws -> HostedOnlineSession {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        do {
            try requireFirebaseBackend()
            let updated = try await mutateSessionInFirestore(sessionID: sessionID) { session in
                try Self.markParticipantAsAnswering(
                    participantID: participantID,
                    in: &session
                )
            }
            sessionsByID[updated.id] = updated
            persistSessions()
            return updated
        } catch let sessionError as OnlineSessionError {
            throw sessionError
        } catch {
            throw mapFirebaseError(error)
        }
        #else
        guard var session = sessionsByID[sessionID] else {
            throw OnlineSessionError.sessionNotFound
        }
        try Self.markParticipantAsAnswering(participantID: participantID, in: &session)
        sessionsByID[sessionID] = session
        persistSessions()
        return session
        #endif
    }

    func startSessionObservation(sessionID: String) {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        guard shouldUseFirebaseBackend else { return }
        guard activeSessionListeners[sessionID] == nil else { return }

        let listener = sessionsCollection().document(sessionID).addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            guard let snapshot, snapshot.exists, let session = self.session(from: snapshot) else { return }
            Task { @MainActor in
                self.sessionsByID[session.id] = session
                self.persistSessions()
            }
        }

        activeSessionListeners[sessionID] = listener
        #endif
    }

    func stopSessionObservation(sessionID: String) {
        #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
        activeSessionListeners[sessionID]?.remove()
        activeSessionListeners.removeValue(forKey: sessionID)
        #endif
    }

    // MARK: - Local fallback API

    func createHostedSession(
        questionnaire: Questionnaire,
        host: OnlineHostAccount,
        hostDisplayName: String
    ) -> HostedOnlineSession {
        let session = makeHostedSession(
            questionnaire: questionnaire,
            host: host,
            hostDisplayName: hostDisplayName
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

    func extendSession(sessionID: String, days: Int = 30) {
        guard var session = sessionsByID[sessionID] else { return }
        let anchor = max(Date.now, session.expiresAt)
        session.expiresAt = Calendar.current.date(byAdding: .day, value: days, to: anchor) ?? anchor
        if session.status == .expired {
            session.status = .open
        }
        session.updatedAt = Date.now
        sessionsByID[sessionID] = session
        persistSessions()
    }

    func closeSession(sessionID: String) {
        guard var session = sessionsByID[sessionID] else { return }
        session.status = .closed
        session.updatedAt = Date.now
        sessionsByID[sessionID] = session
        persistSessions()
    }

    func joinSession(
        invite: String,
        displayName: String,
        participantID: String
    ) throws -> JoinedOnlineSession {
        let trimmedInvite = invite.trimmingCharacters(in: .whitespacesAndNewlines)
        let participantName = sanitizeDisplayName(displayName)
        let resolvedParticipantID = participantID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !participantName.isEmpty, !resolvedParticipantID.isEmpty else {
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

        let existingDisplayNameForID = session.participantIDsByDisplayName.first {
            $0.value.caseInsensitiveCompare(resolvedParticipantID) == .orderedSame
        }?.key

        let existingIndex = session.participantDisplayNames.firstIndex {
            $0.caseInsensitiveCompare(participantName) == .orderedSame
        }
        let existingMappedIDForName: String? = {
            guard let existingIndex else { return nil }
            let existingName = session.participantDisplayNames[existingIndex]
            return session.participantIDsByDisplayName[existingName]
        }()

        if let existingMappedIDForName,
           existingDisplayNameForID == nil,
           existingMappedIDForName.caseInsensitiveCompare(resolvedParticipantID) != .orderedSame {
            throw OnlineSessionError.backendFailure("Display name is already in use. Try a different name.")
        }

        if existingIndex == nil && existingDisplayNameForID == nil,
           session.participantDisplayNames.count >= session.maxParticipants {
            throw OnlineSessionError.participantLimitReached
        }

        let resolvedName: String
        if let existingDisplayNameForID {
            resolvedName = existingDisplayNameForID
        } else if let existingIndex {
            resolvedName = session.participantDisplayNames[existingIndex]
        } else {
            resolvedName = participantName
            session.participantDisplayNames.append(participantName)
            session.participantStatuses[participantName] = HostedOnlineSession.ParticipantStatus.joined.rawValue
            session.participantAnsweredCounts[participantName] = 0
            session.participantQuestionIndices[participantName] = 0
            session.participantAnswers[participantName] = [:]
        }

        session.participantIDsByDisplayName[resolvedName] = resolvedParticipantID
        if session.participantStatuses[resolvedName] != HostedOnlineSession.ParticipantStatus.joined.rawValue {
            session.participantStatuses[resolvedName] = HostedOnlineSession.ParticipantStatus.joined.rawValue
        }

        if session.phase == .complete {
            session.phase = .active
        }
        session.updatedAt = Date.now
        sessionsByID[sessionID] = session
        persistSessions()

        return JoinedOnlineSession(
            sessionID: session.id,
            questionnaireID: session.questionnaireID,
            questionnaireTitle: session.questionnaireTitle,
            questionnaireInformation: session.questionnaireInformation,
            questionnaireInstructions: session.questionnaireInstructions,
            questionnaireQuestions: session.questionnaireQuestions,
            questionnaireIconEmoji: session.questionnaireIconEmoji,
            questionnaireStartColorHex: session.questionnaireStartColorHex,
            questionnaireEndColorHex: session.questionnaireEndColorHex,
            hostDisplayName: session.hostDisplayName,
            participantDisplayNames: session.participantDisplayNames,
            participantIDsByDisplayName: session.participantIDsByDisplayName,
            participantStatuses: session.participantStatuses,
            participantQuestionIndices: session.participantQuestionIndices,
            participantAnsweredCounts: session.participantAnsweredCounts,
            phase: session.phase,
            participantID: resolvedParticipantID,
            participantDisplayName: resolvedName,
            expiresAt: session.expiresAt
        )
    }

    // MARK: - Invite parsing

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

    private func normalizedInvite(_ invite: String) -> String {
        let trimmed = invite.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if let url = URL(string: trimmed),
           let parsed = parseInvite(from: url) {
            return sanitizeInvite(parsed)
        }

        return sanitizeInvite(trimmed)
    }

    private func findSessionID(forInvite invite: String) -> String? {
        let normalizedInvite = normalizedInvite(invite)

        if let direct = sessionsByID.first(where: { $0.value.inviteToken.caseInsensitiveCompare(normalizedInvite) == .orderedSame }) {
            return direct.key
        }

        if let directCode = sessionsByID.first(where: { $0.value.inviteCode.caseInsensitiveCompare(normalizedInvite) == .orderedSame }) {
            return directCode.key
        }

        return nil
    }

    // MARK: - Helpers

    private func makeHostedSession(
        questionnaire: Questionnaire,
        host: OnlineHostAccount,
        hostDisplayName: String
    ) -> HostedOnlineSession {
        let trimmedHostName = sanitizeDisplayName(hostDisplayName)
        let resolvedHostName = trimmedHostName.isEmpty ? "Host" : trimmedHostName
        let now = Date.now

        return HostedOnlineSession(
            id: UUID().uuidString,
            questionnaireID: questionnaire.id,
            questionnaireTitle: questionnaire.title,
            questionnaireInformation: questionnaire.information,
            questionnaireInstructions: questionnaire.instructions,
            questionnaireQuestions: questionnaire.questions,
            hostAppleUserID: host.appleUserID,
            hostDisplayName: resolvedHostName,
            createdAt: now,
            updatedAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: OnlineConfiguration.sessionLifetimeDays, to: now) ?? now,
            maxParticipants: OnlineConfiguration.maxParticipants,
            inviteToken: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
            inviteCode: Self.generateInviteCode(),
            participantDisplayNames: [resolvedHostName],
            participantIDsByDisplayName: [resolvedHostName: host.appleUserID],
            participantStatuses: [resolvedHostName: HostedOnlineSession.ParticipantStatus.joined.rawValue],
            participantAnsweredCounts: [resolvedHostName: 0],
            participantQuestionIndices: [resolvedHostName: 0],
            participantAnswers: [resolvedHostName: [:]],
            totalQuestions: questionnaire.questions.count,
            questionnaireIconEmoji: questionnaire.iconEmoji,
            questionnaireStartColorHex: questionnaire.startColor.toHex(),
            questionnaireEndColorHex: questionnaire.endColor.toHex(),
            phase: .lobby,
            status: .open
        )
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

    private func previewSessionLocally(invite: String) throws -> SessionPreview {
        let trimmedInvite = invite.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInvite.isEmpty,
              let sessionID = findSessionID(forInvite: trimmedInvite),
              let session = sessionsByID[sessionID]
        else {
            throw OnlineSessionError.sessionNotFound
        }
        return SessionPreview(
            sessionID: session.id,
            questionnaireTitle: session.questionnaireTitle,
            hostDisplayName: session.hostDisplayName,
            participantCount: session.participantDisplayNames.count,
            maxParticipants: session.maxParticipants,
            iconEmoji: session.questionnaireIconEmoji,
            startColorHex: session.questionnaireStartColorHex,
            endColorHex: session.questionnaireEndColorHex,
            expiresAt: session.expiresAt
        )
    }

    private func addParticipantLocally(
        sessionID: String,
        displayName: String
    ) throws -> HostedOnlineSession {
        guard var session = sessionsByID[sessionID] else {
            throw OnlineSessionError.sessionNotFound
        }

        try Self.addParticipant(displayName: displayName, to: &session)
        sessionsByID[session.id] = session
        persistSessions()
        return session
    }

    private func renameParticipantLocally(
        sessionID: String,
        oldDisplayName: String,
        newDisplayName: String
    ) throws -> HostedOnlineSession {
        guard var session = sessionsByID[sessionID] else {
            throw OnlineSessionError.sessionNotFound
        }

        try Self.renameParticipant(
            oldDisplayName: oldDisplayName,
            newDisplayName: newDisplayName,
            in: &session
        )
        sessionsByID[session.id] = session
        persistSessions()
        return session
    }

    private func removeParticipantLocally(
        sessionID: String,
        displayName: String
    ) throws -> HostedOnlineSession {
        guard var session = sessionsByID[sessionID] else {
            throw OnlineSessionError.sessionNotFound
        }

        try Self.removeParticipant(displayName: displayName, from: &session)
        sessionsByID[session.id] = session
        persistSessions()
        return session
    }

    private func submitParticipantAnswerLocally(
        sessionID: String,
        participantID: String,
        questionIndex: Int,
        answer: Answer
    ) throws -> HostedOnlineSession {
        guard var session = sessionsByID[sessionID] else {
            throw OnlineSessionError.sessionNotFound
        }

        try Self.applyAnswer(
            participantID: participantID,
            questionIndex: questionIndex,
            answer: answer,
            to: &session
        )
        sessionsByID[session.id] = session
        persistSessions()
        return session
    }

    private static func addParticipant(
        displayName: String,
        to session: inout HostedOnlineSession
    ) throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw OnlineSessionError.invalidDisplayName }

        let alreadyExists = session.participantDisplayNames.contains {
            $0.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !alreadyExists else { return }

        guard session.participantDisplayNames.count < session.maxParticipants else {
            throw OnlineSessionError.participantLimitReached
        }

        let wasComplete = session.phase == .complete

        session.participantDisplayNames.append(trimmed)
        session.participantStatuses[trimmed] = HostedOnlineSession.ParticipantStatus.invited.rawValue
        session.participantAnsweredCounts[trimmed] = 0
        session.participantQuestionIndices[trimmed] = 0
        session.participantAnswers[trimmed] = [:]
        session.updatedAt = Date.now

        if wasComplete {
            session.phase = .active
        } else {
            recomputePhase(&session)
        }
    }

    private static func renameParticipant(
        oldDisplayName: String,
        newDisplayName: String,
        in session: inout HostedOnlineSession
    ) throws {
        let oldTrimmed = oldDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTrimmed = newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !oldTrimmed.isEmpty, !newTrimmed.isEmpty else {
            throw OnlineSessionError.invalidDisplayName
        }

        guard let idx = session.participantDisplayNames.firstIndex(where: {
            $0.caseInsensitiveCompare(oldTrimmed) == .orderedSame
        }) else {
            throw OnlineSessionError.sessionNotFound
        }

        let duplicateTarget = session.participantDisplayNames.contains {
            $0.caseInsensitiveCompare(newTrimmed) == .orderedSame
                && $0.caseInsensitiveCompare(oldTrimmed) != .orderedSame
        }
        guard !duplicateTarget else { return }

        let previousPhase = session.phase
        let previousName = session.participantDisplayNames[idx]
        session.participantDisplayNames[idx] = newTrimmed
        if session.hostDisplayName.caseInsensitiveCompare(previousName) == .orderedSame {
            session.hostDisplayName = newTrimmed
        }

        if let value = session.participantStatuses.removeValue(forKey: previousName) {
            session.participantStatuses[newTrimmed] = value
        }
        if let value = session.participantAnsweredCounts.removeValue(forKey: previousName) {
            session.participantAnsweredCounts[newTrimmed] = value
        }
        if let value = session.participantQuestionIndices.removeValue(forKey: previousName) {
            session.participantQuestionIndices[newTrimmed] = value
        }
        if let value = session.participantAnswers.removeValue(forKey: previousName) {
            session.participantAnswers[newTrimmed] = value
        }
        if let participantID = session.participantIDsByDisplayName.removeValue(forKey: previousName) {
            session.participantIDsByDisplayName[newTrimmed] = participantID
        }

        session.updatedAt = Date.now
        if previousPhase == .complete {
            session.phase = .active
        } else {
            recomputePhase(&session)
        }
    }

    private static func removeParticipant(
        displayName: String,
        from session: inout HostedOnlineSession
    ) throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw OnlineSessionError.invalidDisplayName }

        guard let idx = session.participantDisplayNames.firstIndex(where: {
            $0.caseInsensitiveCompare(trimmed) == .orderedSame
        }) else {
            return
        }

        let previousPhase = session.phase
        let existingName = session.participantDisplayNames[idx]
        if session.hostDisplayName.caseInsensitiveCompare(existingName) == .orderedSame {
            throw OnlineSessionError.backendFailure("Host cannot be removed from the session.")
        }
        session.participantDisplayNames.remove(at: idx)
        session.participantStatuses.removeValue(forKey: existingName)
        session.participantAnsweredCounts.removeValue(forKey: existingName)
        session.participantQuestionIndices.removeValue(forKey: existingName)
        session.participantAnswers.removeValue(forKey: existingName)
        session.participantIDsByDisplayName.removeValue(forKey: existingName)
        session.updatedAt = Date.now

        if previousPhase == .complete {
            session.phase = .active
        } else {
            recomputePhase(&session)
        }
    }

    private static func applyAnswer(
        participantID: String,
        questionIndex: Int,
        answer: Answer,
        to session: inout HostedOnlineSession
    ) throws {
        let trimmed = participantID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw OnlineSessionError.invalidDisplayName }
        guard questionIndex >= 0 else { throw OnlineSessionError.backendFailure("Invalid question index.") }
        guard questionIndex < session.totalQuestions else {
            throw OnlineSessionError.backendFailure("Question index out of range.")
        }

        let mappedParticipant = session.participantIDsByDisplayName.first {
            $0.value.caseInsensitiveCompare(trimmed) == .orderedSame
        }?.key
        let fallbackParticipant = session.participantDisplayNames.first {
            $0.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard let participantName = mappedParticipant ?? fallbackParticipant else {
            throw OnlineSessionError.participantNotInSession
        }

        var answers = session.participantAnswers[participantName] ?? [:]
        answers[String(questionIndex)] = answer.rawValue
        session.participantAnswers[participantName] = answers

        let answeredCount = answers.count
        session.participantAnsweredCounts[participantName] = answeredCount
        session.participantQuestionIndices[participantName] = questionIndex + 1

        if answeredCount >= session.totalQuestions && session.totalQuestions > 0 {
            session.participantStatuses[participantName] = HostedOnlineSession.ParticipantStatus.submitted.rawValue
        } else {
            session.participantStatuses[participantName] = HostedOnlineSession.ParticipantStatus.answering.rawValue
        }

        session.updatedAt = Date.now
        recomputePhase(&session)
    }

    private static func markParticipantAsAnswering(
        participantID: String,
        in session: inout HostedOnlineSession
    ) throws {
        let trimmed = participantID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw OnlineSessionError.invalidDisplayName }

        guard let participantName = participantName(for: trimmed, in: session) else {
            throw OnlineSessionError.participantNotInSession
        }

        let statusRaw = session.participantStatuses[participantName]
        let status = statusRaw.flatMap { HostedOnlineSession.ParticipantStatus(rawValue: $0) } ?? .joined
        if status != .submitted {
            session.participantStatuses[participantName] = HostedOnlineSession.ParticipantStatus.answering.rawValue
        }

        if session.participantQuestionIndices[participantName] == nil {
            session.participantQuestionIndices[participantName] = 0
        }
        if session.participantAnsweredCounts[participantName] == nil {
            session.participantAnsweredCounts[participantName] = 0
        }
        if session.participantAnswers[participantName] == nil {
            session.participantAnswers[participantName] = [:]
        }

        if session.phase == .lobby {
            session.phase = .active
        }

        session.updatedAt = Date.now
        recomputePhase(&session)
    }

    private static func participantName(
        for participantID: String,
        in session: HostedOnlineSession
    ) -> String? {
        if let mapped = session.participantIDsByDisplayName.first(where: {
            $0.value.caseInsensitiveCompare(participantID) == .orderedSame
        })?.key {
            return mapped
        }

        return session.participantDisplayNames.first {
            $0.caseInsensitiveCompare(participantID) == .orderedSame
        }
    }

    private static func recomputePhase(_ session: inout HostedOnlineSession) {
        guard session.status == .open else { return }
        let participants = session.participantDisplayNames

        guard !participants.isEmpty else {
            session.phase = .lobby
            return
        }

        let submittedCount = participants.filter {
            session.participantStatuses[$0] == HostedOnlineSession.ParticipantStatus.submitted.rawValue
        }.count

        if submittedCount == participants.count {
            if participants.count < 2 {
                session.phase = .awaiting
                return
            }
            session.phase = .complete
            return
        }

        if submittedCount > 0 {
            session.phase = .awaiting
            return
        }

        if session.phase == .lobby {
            return
        }

        session.phase = .active
    }

    // MARK: - Firebase implementation

    #if canImport(FirebaseCore) && canImport(FirebaseFirestore)
    private var shouldUseFirebaseBackend: Bool {
        FirebaseApp.app() != nil
    }

    private func requireFirebaseBackend() throws {
        guard shouldUseFirebaseBackend else {
            throw OnlineSessionError.backendFailure(
                "Firebase is not configured on this build. Ensure GoogleService-Info.plist is bundled and app startup calls FirebaseApp.configure()."
            )
        }
    }

    private func sessionsCollection() -> CollectionReference {
        Firestore.firestore().collection("onlineSessions")
    }

    private func mutateSessionInFirestore(
        sessionID: String,
        mutation: (inout HostedOnlineSession) throws -> Void
    ) async throws -> HostedOnlineSession {
        let docRef = sessionsCollection().document(sessionID)
        let snapshot = try await docRef.getDocument()
        guard var session = session(from: snapshot) else {
            throw OnlineSessionError.sessionNotFound
        }

        try mutation(&session)
        try await docRef.setData(firestoreData(from: session), merge: true)
        return session
    }

    private func writeSessionToFirestore(_ session: HostedOnlineSession) async throws {
        try await sessionsCollection()
            .document(session.id)
            .setData(firestoreData(from: session), merge: true)
    }

    private func fetchLatestSessionFromFirestore(
        questionnaireID: UUID,
        hostAppleUserID: String
    ) async throws -> HostedOnlineSession? {
        let snapshot = try await sessionsCollection()
            .whereField(FirestoreFields.questionnaireID, isEqualTo: questionnaireID.uuidString)
            .whereField(FirestoreFields.hostAppleUserID, isEqualTo: hostAppleUserID)
            .getDocuments()

        let decoded = snapshot.documents.compactMap { session(from: $0) }
        let candidate = decoded.sorted { lhs, rhs in lhs.createdAt > rhs.createdAt }.first
        guard let candidate else { return nil }

        if candidate.expiresAt < Date.now, candidate.status == .open {
            try? await sessionsCollection().document(candidate.id).updateData([
                FirestoreFields.status: HostedOnlineSession.Status.expired.rawValue
            ])
        }

        return candidate
    }

    private func extendSessionInFirestore(sessionID: String, days: Int) async throws {
        let docRef = sessionsCollection().document(sessionID)
        let snapshot = try await docRef.getDocument()
        guard var session = session(from: snapshot) else { return }

        let anchor = max(Date.now, session.expiresAt)
        session.expiresAt = Calendar.current.date(byAdding: .day, value: days, to: anchor) ?? anchor
        if session.status == .expired {
            session.status = .open
        }

        try await docRef.updateData([
            FirestoreFields.expiresAt: Timestamp(date: session.expiresAt),
            FirestoreFields.updatedAt: Timestamp(date: Date.now),
            FirestoreFields.status: session.status.rawValue
        ])
    }

    private func closeSessionInFirestore(sessionID: String) async throws {
        try await sessionsCollection().document(sessionID).updateData([
            FirestoreFields.updatedAt: Timestamp(date: Date.now),
            FirestoreFields.status: HostedOnlineSession.Status.closed.rawValue
        ])
    }

    private func joinSessionInFirestore(
        invite: String,
        displayName: String,
        participantID: String
    ) async throws -> JoinedOnlineSession {
        let participantName = sanitizeDisplayName(displayName)
        let resolvedParticipantID = participantID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !participantName.isEmpty, !resolvedParticipantID.isEmpty else {
            throw OnlineSessionError.invalidDisplayName
        }

        let normalizedInvite = normalizedInvite(invite)
        guard !normalizedInvite.isEmpty else {
            throw OnlineSessionError.sessionNotFound
        }

        guard let document = try await findSessionDocument(invite: normalizedInvite) else {
            throw OnlineSessionError.sessionNotFound
        }

        guard var session = session(from: document) else {
            throw OnlineSessionError.sessionNotFound
        }

        if session.status == .closed {
            throw OnlineSessionError.sessionClosed
        }

        if session.expiresAt < Date.now {
            try? await document.reference.updateData([
                FirestoreFields.status: HostedOnlineSession.Status.expired.rawValue
            ])
            throw OnlineSessionError.sessionExpired
        }

        let existingDisplayNameForID = session.participantIDsByDisplayName.first {
            $0.value.caseInsensitiveCompare(resolvedParticipantID) == .orderedSame
        }?.key
        let existingIndex = session.participantDisplayNames.firstIndex {
            $0.caseInsensitiveCompare(participantName) == .orderedSame
        }
        let existingMappedIDForName: String? = {
            guard let existingIndex else { return nil }
            let existingName = session.participantDisplayNames[existingIndex]
            return session.participantIDsByDisplayName[existingName]
        }()

        if let existingMappedIDForName,
           existingDisplayNameForID == nil,
           existingMappedIDForName.caseInsensitiveCompare(resolvedParticipantID) != .orderedSame {
            throw OnlineSessionError.backendFailure("Display name is already in use. Try a different name.")
        }

        if existingIndex == nil && existingDisplayNameForID == nil,
           session.participantDisplayNames.count >= session.maxParticipants {
            throw OnlineSessionError.participantLimitReached
        }

        let resolvedName: String
        if let existingDisplayNameForID {
            resolvedName = existingDisplayNameForID
        } else if let existingIndex {
            resolvedName = session.participantDisplayNames[existingIndex]
        } else {
            resolvedName = participantName
            session.participantDisplayNames.append(participantName)
            session.participantStatuses[participantName] = HostedOnlineSession.ParticipantStatus.joined.rawValue
            session.participantAnsweredCounts[participantName] = 0
            session.participantQuestionIndices[participantName] = 0
            session.participantAnswers[participantName] = [:]
        }

        session.participantIDsByDisplayName[resolvedName] = resolvedParticipantID
        if session.participantStatuses[resolvedName] != HostedOnlineSession.ParticipantStatus.joined.rawValue {
            session.participantStatuses[resolvedName] = HostedOnlineSession.ParticipantStatus.joined.rawValue
        }

        if session.phase == .complete {
            session.phase = .active
        }
        session.updatedAt = Date.now

        try await document.reference.setData(
            firestoreData(from: session),
            merge: true
        )

        let refreshed = try await document.reference.getDocument()
        if let refreshedSession = self.session(from: refreshed) {
            session = refreshedSession
        }

        sessionsByID[session.id] = session
        persistSessions()

        return JoinedOnlineSession(
            sessionID: session.id,
            questionnaireID: session.questionnaireID,
            questionnaireTitle: session.questionnaireTitle,
            questionnaireInformation: session.questionnaireInformation,
            questionnaireInstructions: session.questionnaireInstructions,
            questionnaireQuestions: session.questionnaireQuestions,
            questionnaireIconEmoji: session.questionnaireIconEmoji,
            questionnaireStartColorHex: session.questionnaireStartColorHex,
            questionnaireEndColorHex: session.questionnaireEndColorHex,
            hostDisplayName: session.hostDisplayName,
            participantDisplayNames: session.participantDisplayNames,
            participantIDsByDisplayName: session.participantIDsByDisplayName,
            participantStatuses: session.participantStatuses,
            participantQuestionIndices: session.participantQuestionIndices,
            participantAnsweredCounts: session.participantAnsweredCounts,
            phase: session.phase,
            participantID: resolvedParticipantID,
            participantDisplayName: resolvedName,
            expiresAt: session.expiresAt
        )
    }

    private func findSessionDocument(invite: String) async throws -> DocumentSnapshot? {
        let uppercase = invite.uppercased()
        let lowercase = invite.lowercased()

        let byToken = try await sessionsCollection()
            .whereField(FirestoreFields.inviteToken, isEqualTo: lowercase)
            .limit(to: 1)
            .getDocuments()

        if let tokenDoc = byToken.documents.first {
            return tokenDoc
        }

        let byCode = try await sessionsCollection()
            .whereField(FirestoreFields.inviteCode, isEqualTo: uppercase)
            .limit(to: 1)
            .getDocuments()

        return byCode.documents.first
    }

    private func firestoreData(from session: HostedOnlineSession) -> [String: Any] {
        [
            FirestoreFields.id: session.id,
            FirestoreFields.questionnaireID: session.questionnaireID.uuidString,
            FirestoreFields.questionnaireTitle: session.questionnaireTitle,
            FirestoreFields.questionnaireInformation: session.questionnaireInformation,
            FirestoreFields.questionnaireInstructions: session.questionnaireInstructions,
            FirestoreFields.questionnaireQuestions: session.questionnaireQuestions,
            FirestoreFields.hostAppleUserID: session.hostAppleUserID,
            FirestoreFields.hostDisplayName: session.hostDisplayName,
            FirestoreFields.createdAt: Timestamp(date: session.createdAt),
            FirestoreFields.updatedAt: Timestamp(date: session.updatedAt),
            FirestoreFields.expiresAt: Timestamp(date: session.expiresAt),
            FirestoreFields.maxParticipants: session.maxParticipants,
            FirestoreFields.inviteToken: session.inviteToken,
            FirestoreFields.inviteCode: session.inviteCode,
            FirestoreFields.participantDisplayNames: session.participantDisplayNames,
            FirestoreFields.participantIDsByDisplayName: session.participantIDsByDisplayName,
            FirestoreFields.participantStatuses: session.participantStatuses,
            FirestoreFields.participantAnsweredCounts: session.participantAnsweredCounts,
            FirestoreFields.participantQuestionIndices: session.participantQuestionIndices,
            FirestoreFields.participantAnswers: session.participantAnswers,
            FirestoreFields.totalQuestions: session.totalQuestions,
            FirestoreFields.questionnaireIconEmoji: session.questionnaireIconEmoji,
            FirestoreFields.questionnaireStartColorHex: session.questionnaireStartColorHex,
            FirestoreFields.questionnaireEndColorHex: session.questionnaireEndColorHex,
            FirestoreFields.phase: session.phase.rawValue,
            FirestoreFields.status: session.status.rawValue
        ]
    }

    private func session(from snapshot: DocumentSnapshot) -> HostedOnlineSession? {
        guard let data = snapshot.data() else { return nil }
        return session(from: data, fallbackID: snapshot.documentID)
    }

    private func session(from data: [String: Any], fallbackID: String) -> HostedOnlineSession? {
        let id = (data[FirestoreFields.id] as? String) ?? fallbackID
        guard let questionnaireIDString = data[FirestoreFields.questionnaireID] as? String,
              let questionnaireID = UUID(uuidString: questionnaireIDString),
              let questionnaireTitle = data[FirestoreFields.questionnaireTitle] as? String,
              let hostAppleUserID = data[FirestoreFields.hostAppleUserID] as? String,
              let hostDisplayName = data[FirestoreFields.hostDisplayName] as? String,
              let maxParticipants = data[FirestoreFields.maxParticipants] as? Int,
              let inviteToken = data[FirestoreFields.inviteToken] as? String,
              let inviteCode = data[FirestoreFields.inviteCode] as? String,
              let participantDisplayNames = data[FirestoreFields.participantDisplayNames] as? [String],
              let statusRaw = data[FirestoreFields.status] as? String,
              let status = HostedOnlineSession.Status(rawValue: statusRaw)
        else {
            return nil
        }

        let questionnaireInformation = (data[FirestoreFields.questionnaireInformation] as? String) ?? ""
        let questionnaireInstructions = (data[FirestoreFields.questionnaireInstructions] as? String) ?? ""
        let questionnaireQuestions = (data[FirestoreFields.questionnaireQuestions] as? [String]) ?? []

        guard let createdAt = Self.date(from: data[FirestoreFields.createdAt]),
              let expiresAt = Self.date(from: data[FirestoreFields.expiresAt])
        else {
            return nil
        }
        let updatedAt = Self.date(from: data[FirestoreFields.updatedAt]) ?? createdAt

        let participantStatuses =
            (data[FirestoreFields.participantStatuses] as? [String: String])
            ?? Dictionary(
                uniqueKeysWithValues: participantDisplayNames.map {
                    ($0, HostedOnlineSession.ParticipantStatus.joined.rawValue)
                }
            )
        let participantIDsByDisplayName =
            (data[FirestoreFields.participantIDsByDisplayName] as? [String: String])
            ?? Dictionary(
                uniqueKeysWithValues: participantDisplayNames.map { name in
                    let participantID = Self.legacyParticipantID(
                        sessionID: id,
                        participantName: name,
                        hostAppleUserID: hostAppleUserID,
                        hostDisplayName: hostDisplayName
                    )
                    return (name, participantID)
                }
            )
        let participantAnsweredCounts =
            (data[FirestoreFields.participantAnsweredCounts] as? [String: Int])
            ?? Dictionary(uniqueKeysWithValues: participantDisplayNames.map { ($0, 0) })
        let participantQuestionIndices =
            (data[FirestoreFields.participantQuestionIndices] as? [String: Int])
            ?? Dictionary(uniqueKeysWithValues: participantDisplayNames.map { ($0, 0) })
        let participantAnswers =
            (data[FirestoreFields.participantAnswers] as? [String: [String: String]])
            ?? [:]
        let totalQuestions =
            (data[FirestoreFields.totalQuestions] as? Int)
            ?? questionnaireQuestions.count
        let phaseRaw = (data[FirestoreFields.phase] as? String) ?? HostedOnlineSession.Phase.lobby.rawValue
        let phase = HostedOnlineSession.Phase(rawValue: phaseRaw) ?? .lobby

        let questionnaireIconEmoji = (data[FirestoreFields.questionnaireIconEmoji] as? String) ?? "📝"
        let questionnaireStartColorHex = (data[FirestoreFields.questionnaireStartColorHex] as? String) ?? "#0000FF"
        let questionnaireEndColorHex = (data[FirestoreFields.questionnaireEndColorHex] as? String) ?? "#800080"

        return HostedOnlineSession(
            id: id,
            questionnaireID: questionnaireID,
            questionnaireTitle: questionnaireTitle,
            questionnaireInformation: questionnaireInformation,
            questionnaireInstructions: questionnaireInstructions,
            questionnaireQuestions: questionnaireQuestions,
            hostAppleUserID: hostAppleUserID,
            hostDisplayName: hostDisplayName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt,
            maxParticipants: maxParticipants,
            inviteToken: inviteToken,
            inviteCode: inviteCode,
            participantDisplayNames: participantDisplayNames,
            participantIDsByDisplayName: participantIDsByDisplayName,
            participantStatuses: participantStatuses,
            participantAnsweredCounts: participantAnsweredCounts,
            participantQuestionIndices: participantQuestionIndices,
            participantAnswers: participantAnswers,
            totalQuestions: totalQuestions,
            questionnaireIconEmoji: questionnaireIconEmoji,
            questionnaireStartColorHex: questionnaireStartColorHex,
            questionnaireEndColorHex: questionnaireEndColorHex,
            phase: phase,
            status: status
        )
    }

    private static func date(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }

        if let date = value as? Date {
            return date
        }

        if let seconds = value as? TimeInterval {
            return Date(timeIntervalSince1970: seconds)
        }

        return nil
    }

    private static func legacyParticipantID(
        sessionID: String,
        participantName: String,
        hostAppleUserID: String,
        hostDisplayName: String
    ) -> String {
        if participantName.caseInsensitiveCompare(hostDisplayName) == .orderedSame {
            return hostAppleUserID
        }

        let normalized = participantName
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
        return "legacy-\(sessionID)-\(normalized)"
    }

    private func mapFirebaseError(_ error: Error) -> OnlineSessionError {
        let nsError = error as NSError

        if nsError.domain == FirestoreErrorDomain {
            if nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                return .backendFailure(
                    "Firestore permission denied. Check rules for onlineSessions and App Check enforcement."
                )
            }

            if nsError.code == FirestoreErrorCode.failedPrecondition.rawValue {
                return .backendFailure(
                    "Firestore requires an index for this query. Create the suggested index from the console link."
                )
            }
        }

        return .backendFailure(error.localizedDescription)
    }
    #endif

    private func sanitizeInvite(_ value: String) -> String {
        var result = value.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
                .union(CharacterSet(charactersIn: ".,;:!?\"'()[]{}"))
        )
        result = result.replacingOccurrences(of: " ", with: "")
        return result
    }
}
