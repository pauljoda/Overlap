//
//  OnlineSessionSnapshotApplier.swift
//  Overlap
//
//  Shared mapper from hosted session snapshots to local Overlap state.
//

import Foundation

enum OnlineSessionSnapshotApplier {
    @MainActor
    static func apply(session: HostedOnlineSession, to overlap: Overlap) -> Bool {
        overlap.participants = session.participantDisplayNames

        var restoredResponses: [String: [Answer?]] = [:]
        for participant in session.participantDisplayNames {
            var answers = Array(repeating: Answer?.none, count: overlap.questions.count)
            if let map = session.participantAnswers[participant] {
                for (key, raw) in map {
                    guard let idx = Int(key),
                          idx >= 0,
                          idx < answers.count,
                          let answer = Answer(rawValue: raw)
                    else { continue }
                    answers[idx] = answer
                }
            }
            restoredResponses[participant] = answers
        }
        overlap.restoreResponses(restoredResponses)

        let originalParticipantID = overlap.onlineParticipantID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let originalParticipant = overlap.onlineParticipantDisplayName
        let resolvedParticipant = resolveParticipantName(
            participantID: originalParticipantID,
            participantName: originalParticipant,
            session: session
        )
        overlap.onlineParticipantDisplayName = resolvedParticipant
        if let resolvedParticipant {
            overlap.onlineParticipantID = session.participantIDsByDisplayName[resolvedParticipant]
                ?? originalParticipantID
        }

        if let resolvedParticipant,
           let resolvedIndex = session.participantDisplayNames.firstIndex(of: resolvedParticipant) {
            overlap.currentParticipantIndex = resolvedIndex
            if let idx = session.participantQuestionIndices[resolvedParticipant] {
                overlap.currentQuestionIndex = min(max(0, idx), overlap.totalQuestions)
            } else {
                overlap.currentQuestionIndex = 0
            }
        } else {
            overlap.currentParticipantIndex = 0
            overlap.currentQuestionIndex = 0
        }

        let wasRemovedFromSession = overlap.isOnline
            && (originalParticipant != nil || !(originalParticipantID ?? "").isEmpty)
            && resolvedParticipant == nil

        if wasRemovedFromSession {
            overlap.currentState = .instructions
            overlap.isCompleted = false
            overlap.completeDate = nil
        } else if shouldShowInstructionsBeforeAnswering(
            participant: resolvedParticipant,
            session: session
        ) {
            overlap.currentState = overlap.isOnline ? .nextParticipant : .instructions
            overlap.isCompleted = false
            overlap.completeDate = nil
        } else if shouldContinueAnswering(
            participant: resolvedParticipant,
            session: session
        ) {
            overlap.currentState = .answering
            overlap.isCompleted = false
            overlap.completeDate = nil
        } else {
            applyPhase(session.phase, to: overlap)
        }

        return wasRemovedFromSession
    }

    @MainActor
    static func applyPhase(_ phase: HostedOnlineSession.Phase, to overlap: Overlap) {
        switch phase {
        case .lobby:
            overlap.currentState = .instructions
        case .active:
            overlap.currentState = .answering
        case .awaiting:
            overlap.currentState = .awaitingResponses
        case .complete:
            overlap.currentState = .complete
        }

        if phase == .complete {
            overlap.isCompleted = true
            if overlap.completeDate == nil {
                overlap.completeDate = Date.now
            }
        } else {
            overlap.isCompleted = false
            overlap.completeDate = nil
        }
    }

    private static func resolveParticipantName(
        participantID: String?,
        participantName: String?,
        session: HostedOnlineSession
    ) -> String? {
        if let participantID,
           !participantID.isEmpty,
           let mappedName = session.participantIDsByDisplayName.first(where: {
               $0.value.caseInsensitiveCompare(participantID) == .orderedSame
           })?.key {
            return mappedName
        }

        guard let participantName else { return nil }
        return session.participantDisplayNames.first {
            $0.caseInsensitiveCompare(participantName) == .orderedSame
        }
    }

    private static func shouldShowInstructionsBeforeAnswering(
        participant: String?,
        session: HostedOnlineSession
    ) -> Bool {
        guard let participant else { return false }
        guard session.phase != .lobby else { return true }

        let statusRaw = session.participantStatuses[participant]
        let status = statusRaw.flatMap { HostedOnlineSession.ParticipantStatus(rawValue: $0) } ?? .joined
        if status == .submitted {
            return false
        }

        let answeredCount = session.participantAnsweredCounts[participant] ?? 0
        let questionIndex = session.participantQuestionIndices[participant] ?? 0
        let hasStarted = answeredCount > 0 || questionIndex > 0 || status == .answering
        return !hasStarted
    }

    private static func shouldContinueAnswering(
        participant: String?,
        session: HostedOnlineSession
    ) -> Bool {
        guard let participant else { return false }
        guard session.totalQuestions > 0 else { return false }

        let statusRaw = session.participantStatuses[participant]
        let status = statusRaw.flatMap { HostedOnlineSession.ParticipantStatus(rawValue: $0) } ?? .joined
        if status == .submitted {
            return false
        }

        let answeredCount = session.participantAnsweredCounts[participant] ?? 0
        return answeredCount < session.totalQuestions
    }
}
