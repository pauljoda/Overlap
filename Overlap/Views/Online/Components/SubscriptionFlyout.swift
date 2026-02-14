//
//  SubscriptionFlyout.swift
//  Overlap
//
//  Shared subscription paywall presented as a sheet from both
//  OnlineSessionSetupView and SettingsView.
//

import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif

struct SubscriptionFlyout: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: OnlineSubscriptionService

    @State private var isStoreActionInFlight = false

    var body: some View {
        NavigationStack {
            GlassScreen {
                VStack(spacing: Tokens.Spacing.xxl) {
                    // Header
                    VStack(spacing: Tokens.Spacing.l) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: Tokens.Size.iconLarge))
                            .foregroundColor(.orange)

                        VStack(spacing: Tokens.Spacing.s) {
                            Text("Unlock Online Hosting")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("Host live sessions across devices with real-time sync.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, Tokens.Spacing.l)

                    // Features
                    VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                        featureRow(icon: "link", text: "Link-based invites")
                        featureRow(icon: "person.3.fill", text: "Up to \(OnlineConfiguration.maxParticipants) participants")
                        featureRow(icon: "calendar.badge.clock", text: "\(OnlineConfiguration.sessionLifetimeDays)-day session lifecycle")
                        featureRow(icon: "arrow.triangle.2.circlepath", text: "Live answer sync across devices")
                    }
                    .padding(Tokens.Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .standardGlassCard()

                    // Pricing
                    VStack(spacing: Tokens.Spacing.m) {
                        pricingCard(
                            title: "Yearly",
                            price: currency(OnlineConfiguration.yearlyPriceUSD),
                            detail: yearlySavingsText,
                            badge: "Best value"
                        )

                        pricingCard(
                            title: "Monthly",
                            price: currency(OnlineConfiguration.monthlyPriceUSD),
                            detail: "Flexible month-to-month",
                            badge: nil
                        )
                    }

                    // Subscribe buttons
                    #if canImport(StoreKit)
                    VStack(spacing: Tokens.Spacing.m) {
                        if let yearlyProduct = subscriptionService.products.first(where: { $0.id == OnlineConfiguration.yearlyProductID }) {
                            GlassActionButton(
                                title: "Subscribe Yearly \u{2022} \(yearlyProduct.displayPrice)",
                                icon: "crown.fill",
                                isEnabled: !isStoreActionInFlight,
                                tintColor: .orange
                            ) {
                                Task { await purchase(productID: yearlyProduct.id) }
                            }
                        }

                        if let monthlyProduct = subscriptionService.products.first(where: { $0.id == OnlineConfiguration.monthlyProductID }) {
                            GlassActionButton(
                                title: "Subscribe Monthly \u{2022} \(monthlyProduct.displayPrice)",
                                icon: "crown",
                                isEnabled: !isStoreActionInFlight,
                                tintColor: .blue
                            ) {
                                Task { await purchase(productID: monthlyProduct.id) }
                            }
                        }
                    }
                    #endif

                    // Restore purchases
                    GlassActionButton(
                        title: "Restore Purchases",
                        icon: "arrow.clockwise",
                        isEnabled: !isStoreActionInFlight,
                        tintColor: .blue
                    ) {
                        Task { await restorePurchases() }
                    }

                    #if DEBUG
                    VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                        Text("Development")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(subscriptionService.hasOnlineHostAccess ? "Dev access is currently ON." : "Dev access is currently OFF.")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: Tokens.Spacing.s) {
                            Button(subscriptionService.hasOnlineHostAccess ? "Disable Dev Access" : "Enable Dev Access") {
                                if subscriptionService.hasOnlineHostAccess {
                                    subscriptionService.setDebugOverride(false)
                                    subscriptionService.clearEntitlement()
                                } else {
                                    subscriptionService.setDebugOverride(true)
                                    subscriptionService.grantDevelopmentEntitlement()
                                    dismiss()
                                }
                            }
                            .buttonStyle(.bordered)

                            Button("Grant 30d") {
                                subscriptionService.grantDevelopmentEntitlement()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    #endif

                    Spacer().frame(height: Tokens.Spacing.quadXL)
                }
                .padding(.horizontal, Tokens.Spacing.xl)
            }
            .navigationTitle("Online Hosting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .onChange(of: subscriptionService.hasOnlineHostAccess) { _, hasAccess in
            if hasAccess { dismiss() }
        }
        .task {
            await subscriptionService.loadProducts()
        }
    }

    // MARK: - Helpers

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Tokens.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func pricingCard(title: String, price: String, detail: String, badge: String?) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            HStack(spacing: Tokens.Spacing.s) {
                Text(title)
                    .font(.headline)

                if let badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, Tokens.Spacing.s)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(price)
                .font(.title3)
                .fontWeight(.bold)

            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.Spacing.l)
        .standardGlassCard()
    }

    private var yearlySavingsText: String {
        let monthly = NSDecimalNumber(decimal: OnlineConfiguration.monthlyPriceUSD).doubleValue
        let yearly = NSDecimalNumber(decimal: OnlineConfiguration.yearlyPriceUSD).doubleValue
        let annualMonthlyTotal = monthly * 12

        guard annualMonthlyTotal > yearly else {
            return "Best long-term value"
        }

        let savings = annualMonthlyTotal - yearly
        let percent = (savings / annualMonthlyTotal) * 100
        return "Save \(currencyDecimal(savings))/yr (\(Int(percent.rounded()))%)"
    }

    // MARK: - Actions

    @MainActor
    private func purchase(productID: String) async {
        #if canImport(StoreKit)
        isStoreActionInFlight = true
        defer { isStoreActionInFlight = false }

        do {
            try await subscriptionService.purchase(productID: productID)
            await subscriptionService.refreshFromStoreKit()
        } catch {
            // Errors handled by subscription service
        }
        #endif
    }

    @MainActor
    private func restorePurchases() async {
        isStoreActionInFlight = true
        defer { isStoreActionInFlight = false }

        do {
            try await subscriptionService.restorePurchases()
            await subscriptionService.refreshFromStoreKit()
        } catch {
            // Errors handled by subscription service
        }
    }

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$\(value)"
    }

    private func currencyDecimal(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}

#Preview {
    SubscriptionFlyout()
        .environmentObject(OnlineSubscriptionService.shared)
}
