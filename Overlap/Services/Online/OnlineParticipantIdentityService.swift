//
//  OnlineParticipantIdentityService.swift
//  Overlap
//
//  Persistent per-device participant identity for guest online sessions.
//

import Foundation

final class OnlineParticipantIdentityService {
    static let shared = OnlineParticipantIdentityService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let participantID = "onlineParticipantDeviceID"
    }

    let participantID: String

    private init() {
        if let existing = defaults.string(forKey: Keys.participantID),
           !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            participantID = existing
            return
        }

        let created = UUID().uuidString.lowercased()
        participantID = created
        defaults.set(created, forKey: Keys.participantID)
    }
}
