//
//  DisplayNameSetupView.swift
//  Overlap
//
//  User display name setup for CloudKit sharing
//

import SwiftUI
import CloudKit

struct DisplayNameSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var manualName = ""
    @State private var showingManualEntry = true
    
    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xl) {
                // Header
                VStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.blue)
                    
                    Text("Setup Your Display Name")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Enter a name that others will see when you share overlaps with them.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Name Entry Section
                VStack(spacing: Tokens.Spacing.m) {
                    VStack(spacing: Tokens.Spacing.s) {
                        TextField("Enter your display name", text: $manualName)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .onSubmit {
                                setManualName()
                            }
                        
                        Text("This name will be visible to other participants when you share overlaps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button("Set Display Name") {
                        setManualName()
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Tokens.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: Tokens.Radius.m)
                            .fill(Color.blue.gradient)
                    )
                    .disabled(manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .glassEffect(in: .rect(cornerRadius: Tokens.Radius.m))
                }
                .padding()
                .standardGlassCard()
                
                Spacer()
                
                // Skip for now
                Button("Skip for now") {
                    dismiss()
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding(Tokens.Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Pre-populate with the current display name if available
            if let currentName = userPreferences.userDisplayName {
                manualName = currentName
            }
        }
    }

    private func setManualName() {
        let trimmedName = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        userPreferences.userDisplayName = trimmedName
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        DisplayNameSetupView()
    }
}
