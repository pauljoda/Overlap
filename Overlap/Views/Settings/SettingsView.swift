//
//  SettingsView.swift
//  Overlap
//
//  A native settings-style screen to edit user preferences.
//  Currently supports editing the display name only.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var displayName: String = ""

    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xl) {
                // Simple settings card
                VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                    Text("Display Name")
                        .font(.headline)
                    TextField("Display Name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit(save)
                        .onChange(of: displayName) { _, _ in save() }

                    Text("Visible to participants when you share overlaps.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .standardGlassCard()

                Spacer(minLength: 0)
            }
            .padding(Tokens.Spacing.xl)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func load() {
        displayName = userPreferences.userDisplayName ?? ""
    }

    private func save() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        userPreferences.userDisplayName = trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
