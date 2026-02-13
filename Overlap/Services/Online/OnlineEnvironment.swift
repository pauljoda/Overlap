//
//  OnlineEnvironment.swift
//  Overlap
//
//  Environment keys for the online session services.
//

import SwiftUI

private struct OnlineSubscriptionServiceKey: EnvironmentKey {
    static let defaultValue = OnlineSubscriptionService.shared
}

private struct OnlineHostAuthServiceKey: EnvironmentKey {
    static let defaultValue = OnlineHostAuthService.shared
}

private struct OnlineSessionServiceKey: EnvironmentKey {
    static let defaultValue = OnlineSessionService.shared
}

extension EnvironmentValues {
    var onlineSubscriptionService: OnlineSubscriptionService {
        get { self[OnlineSubscriptionServiceKey.self] }
        set { self[OnlineSubscriptionServiceKey.self] = newValue }
    }

    var onlineHostAuthService: OnlineHostAuthService {
        get { self[OnlineHostAuthServiceKey.self] }
        set { self[OnlineHostAuthServiceKey.self] = newValue }
    }

    var onlineSessionService: OnlineSessionService {
        get { self[OnlineSessionServiceKey.self] }
        set { self[OnlineSessionServiceKey.self] = newValue }
    }
}
