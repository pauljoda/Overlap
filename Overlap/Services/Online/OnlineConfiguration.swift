//
//  OnlineConfiguration.swift
//  Overlap
//
//  Centralized configuration values for hosted online sessions.
//

import Foundation

enum OnlineConfiguration {
    static let maxParticipants = 25
    static let sessionLifetimeDays = 30

    // Placeholder domain for universal-link invites.
    static let inviteHost = "join.overlapapp.link"
    static let invitePathPrefix = "/j/"
    static let inviteScheme = "overlap"

    static var baseInviteURL: URL {
        URL(string: "https://\(inviteHost)")!
    }

    static let monthlyPriceUSD: Decimal = 2.99
    static let yearlyPriceUSD: Decimal = 24.99
}
