//
//  OnlineSubscriptionService.swift
//  Overlap
//
//  Host-only subscription gate for online sessions.
//

import Foundation
import Combine
#if canImport(StoreKit)
import StoreKit
#endif

enum OnlineSubscriptionError: LocalizedError {
    case unavailable
    case unknownProduct
    case pending
    case unverified
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Subscriptions are not available on this build."
        case .unknownProduct:
            return "Subscription product is not available."
        case .pending:
            return "Purchase is pending approval."
        case .unverified:
            return "Could not verify this transaction."
        case .failed(let message):
            return message
        }
    }
}

@MainActor
final class OnlineSubscriptionService: ObservableObject {
    static let shared = OnlineSubscriptionService()

    @Published private(set) var entitlementExpiration: Date?
    @Published private(set) var isStoreKitLoading = false
    #if canImport(StoreKit)
    @Published private(set) var products: [Product] = []
    #endif
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

    func grantDevelopmentEntitlement(days: Int? = nil) {
        #if DEBUG
        let resolvedDays = days ?? OnlineConfiguration.sessionLifetimeDays
        let expiration = Calendar.current.date(byAdding: .day, value: resolvedDays, to: Date.now)
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

    @MainActor
    func loadProducts() async {
        #if canImport(StoreKit)
        isStoreKitLoading = true
        defer { isStoreKitLoading = false }

        do {
            let fetched = try await Product.products(for: OnlineConfiguration.hostSubscriptionProductIDs)
            products = fetched
        } catch {
            products = []
        }
        #endif
    }

    @MainActor
    func refreshFromStoreKit() async {
        #if canImport(StoreKit)
        var latestExpiration: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard OnlineConfiguration.hostSubscriptionProductIDs.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            let candidate = transaction.expirationDate ?? Date.distantFuture
            if let currentLatest = latestExpiration {
                if candidate > currentLatest {
                    latestExpiration = candidate
                }
            } else {
                latestExpiration = candidate
            }
        }

        setEntitlementExpiration(latestExpiration)
        #endif
    }

    @MainActor
    func purchase(productID: String) async throws {
        #if canImport(StoreKit)
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = products.first(where: { $0.id == productID }) else {
            throw OnlineSubscriptionError.unknownProduct
        }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw OnlineSubscriptionError.failed(error.localizedDescription)
        }

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw OnlineSubscriptionError.unverified
            }
            await transaction.finish()
            await refreshFromStoreKit()

        case .pending:
            throw OnlineSubscriptionError.pending

        case .userCancelled:
            return

        @unknown default:
            throw OnlineSubscriptionError.failed("Purchase did not complete.")
        }
        #else
        throw OnlineSubscriptionError.unavailable
        #endif
    }

    @MainActor
    func restorePurchases() async throws {
        #if canImport(StoreKit)
        try await AppStore.sync()
        await refreshFromStoreKit()
        #else
        throw OnlineSubscriptionError.unavailable
        #endif
    }

    private func formattedPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "$\(price)"
    }
}
