//
//  OnlineSubscriptionService.swift
//  Overlap
//
//  Host-only subscription gate for online sessions.
//

import Foundation
import Combine

final class OnlineSubscriptionService: ObservableObject {
    static let shared = OnlineSubscriptionService()

    @Published private(set) var entitlementExpiration: Date?
    #if DEBUG
    @Published private(set) var debugOverrideEnabled = false
    #endif

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let entitlementExpiration = "onlineHostEntitlementExpiration"
        static let debugOverrideEnabled = "onlineHostDebugOverrideEnabled"
    }

    private init() {
        entitlementExpiration = defaults.object(forKey: Keys.entitlementExpiration) as? Date
        #if DEBUG
        debugOverrideEnabled = defaults.bool(forKey: Keys.debugOverrideEnabled)
        #endif
    }

    var hasOnlineHostAccess: Bool {
        #if DEBUG
        if debugOverrideEnabled {
            return true
        }
        #endif

        guard let entitlementExpiration else { return false }
        return entitlementExpiration > Date.now
    }

    var subscriptionSummary: String {
        if let entitlementExpiration {
            let formatted = entitlementExpiration.formatted(date: .abbreviated, time: .omitted)
            return "Online host access active through \(formatted)."
        }

        return "Online host access required (\(formattedPrice(OnlineConfiguration.monthlyPriceUSD))/month)."
    }

    func setEntitlementExpiration(_ date: Date?) {
        entitlementExpiration = date
        defaults.set(date, forKey: Keys.entitlementExpiration)
    }

    func grantDevelopmentEntitlement(days: Int = OnlineConfiguration.sessionLifetimeDays) {
        #if DEBUG
        let expiration = Calendar.current.date(byAdding: .day, value: days, to: Date.now)
        setEntitlementExpiration(expiration)
        #endif
    }

    func clearEntitlement() {
        setEntitlementExpiration(nil)
    }

    #if DEBUG
    func setDebugOverride(_ enabled: Bool) {
        debugOverrideEnabled = enabled
        defaults.set(enabled, forKey: Keys.debugOverrideEnabled)
    }
    #endif

    // Placeholder until StoreKit 2 purchase/restore flows are integrated.
    func refreshFromStoreKit() async {
    }

    private func formattedPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "$\(price)"
    }
}
