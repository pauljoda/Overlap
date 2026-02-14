//
//  SettingsView.swift
//  Overlap
//
//  User settings including display name and favorite participant groups.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionService: OnlineSubscriptionService
    @Query(sort: \FavoriteGroup.createdAt, order: .reverse) private var favoriteGroups: [FavoriteGroup]
    @AppStorage("userDisplayName") private var userDisplayName = ""
    @State private var editingGroup: FavoriteGroup?
    @State private var showingNewGroup = false
    @State private var isRestoringPurchases = false
    @State private var restoreMessage: String?
    @State private var showingSubscriptionFlyout = false

    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xxl) {
                header

                displayNameSection

                favoriteGroupsSection

                subscriptionSection

                aboutSection

                #if DEBUG
                developerSection
                #endif

                Spacer().frame(height: Tokens.Spacing.quadXL)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.xl)
            .frame(maxWidth: Tokens.Size.maxContentWidth)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewGroup) {
            FavoriteGroupEditor(group: nil)
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(item: $editingGroup) { group in
            FavoriteGroupEditor(group: group)
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingSubscriptionFlyout) {
            SubscriptionFlyout()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.ultraThinMaterial)
        }
        .alert(
            "Restore Purchases",
            isPresented: Binding(
                get: { restoreMessage != nil },
                set: { _ in restoreMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .task {
            await subscriptionService.refreshFromStoreKit()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Tokens.Spacing.l) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: Tokens.Size.iconLarge))
                .foregroundColor(.gray)

            VStack(spacing: Tokens.Spacing.s) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Personalize your Overlap experience.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Display Name

    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Display Name", icon: "person.fill")

            TextField("Your name", text: $userDisplayName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(Tokens.Spacing.l)
                .standardGlassCard()

            Text("Auto-fills when joining sessions or starting overlaps.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Online Host Access", icon: "crown.fill")

            if subscriptionService.hasOnlineHostAccess {
                // Active subscription card
                VStack(spacing: Tokens.Spacing.l) {
                    HStack(spacing: Tokens.Spacing.m) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                            Text("Active")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            if let expiration = subscriptionService.entitlementExpiration {
                                Text("Renews \(expiration.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    Button {
                        Task { await restorePurchases() }
                    } label: {
                        HStack(spacing: Tokens.Spacing.s) {
                            if isRestoringPurchases {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Tokens.Spacing.m)
                    }
                    .disabled(isRestoringPurchases)
                }
                .padding(Tokens.Spacing.l)
                .standardGlassCard()
            } else {
                // Subscribe prompt card
                Button {
                    showingSubscriptionFlyout = true
                } label: {
                    HStack(spacing: Tokens.Spacing.m) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                            Text("Subscribe for Online")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text("Host live sessions with invite links.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(Tokens.Spacing.l)
                    .standardGlassCard()
                }
            }
        }
    }

    // MARK: - Favorite Groups

    private var favoriteGroupsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            HStack {
                SectionHeader(title: "Favorite Groups", icon: "person.3.fill")
                Spacer()
                Button {
                    showingNewGroup = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            if favoriteGroups.isEmpty {
                VStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "person.3")
                        .font(.system(size: Tokens.Size.iconSmall))
                        .foregroundColor(.secondary)

                    Text("No groups yet. Create one to quickly fill participants when starting local overlaps.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Tokens.Spacing.xl)
                .standardGlassCard()
            } else {
                ForEach(favoriteGroups) { group in
                    favoriteGroupRow(group)
                }
            }
        }
    }

    private func favoriteGroupRow(_ group: FavoriteGroup) -> some View {
        Button {
            editingGroup = group
        } label: {
            HStack(spacing: Tokens.Spacing.m) {
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(group.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(group.participants.isEmpty
                         ? "No participants"
                         : group.participants.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(group.participants.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Tokens.Spacing.s)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Tokens.Spacing.l)
            .standardGlassCard()
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteGroup(group)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func deleteGroup(_ group: FavoriteGroup) {
        modelContext.delete(group)
        try? modelContext.save()
    }

    @MainActor
    private func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.hasOnlineHostAccess {
                restoreMessage = "Your subscription has been restored successfully."
            } else {
                restoreMessage = "No active subscriptions were found."
            }
        } catch {
            restoreMessage = error.localizedDescription
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "About", icon: "info.circle.fill")

            HStack(spacing: Tokens.Spacing.m) {
                Group {
                    if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
                       let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                       let iconFiles = primary["CFBundleIconFiles"] as? [String],
                       let iconName = iconFiles.last,
                       let uiImage = UIImage(named: iconName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if let uiImage = UIImage(named: "AppIcon60x60") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text("Overlap")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("Version \(appVersion) (\(appBuild))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(Tokens.Spacing.l)
            .standardGlassCard()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    // MARK: - Developer (DEBUG only)

    #if DEBUG
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Developer", icon: "hammer.fill")

            VStack(spacing: Tokens.Spacing.m) {
                HStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "ladybug.fill")
                        .font(.title3)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text("Debug Override")
                            .font(.body)
                            .fontWeight(.medium)

                        Text(subscriptionService.debugOverrideEnabled
                             ? "Bypassing subscription check"
                             : "Using real subscription status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { subscriptionService.debugOverrideEnabled },
                        set: { enabled in
                            subscriptionService.setDebugOverride(enabled)
                            if enabled {
                                subscriptionService.grantDevelopmentEntitlement()
                            }
                        }
                    ))
                    .labelsHidden()
                }

                if subscriptionService.hasOnlineHostAccess {
                    Button {
                        subscriptionService.setDebugOverride(false)
                        subscriptionService.clearEntitlement()
                    } label: {
                        HStack(spacing: Tokens.Spacing.s) {
                            Image(systemName: "trash")
                            Text("Remove Subscription")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Tokens.Spacing.m)
                    }
                }
            }
            .padding(Tokens.Spacing.l)
            .standardGlassCard()
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: FavoriteGroup.self, inMemory: true)
    .environmentObject(OnlineSubscriptionService.shared)
}
