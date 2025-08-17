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
    @ObservedObject var cloudKitService: CloudKitService
    @State private var manualName = ""
    @State private var isRequestingPermission = false
    @State private var showingManualEntry = false
    
    private var permissionButtonText: String {
        if isRequestingPermission {
            return "Requesting..."
        } else if cloudKitService.discoverabilityPermission == .granted {
            return "Permission Granted ✓"
        } else if cloudKitService.discoverabilityPermission == .denied {
            return "Request Again"
        } else {
            return "Use iCloud Name"
        }
    }
    
    private var permissionButtonColor: Color {
        if cloudKitService.discoverabilityPermission == .granted {
            return .green
        } else if cloudKitService.discoverabilityPermission == .denied {
            return .orange
        } else {
            return .blue
        }
    }
    
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
                    
                    Text("To share overlaps with others, we need a display name to identify you to participants.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: Tokens.Spacing.l) {
                    // Option 1: Use iCloud Name
                    VStack(spacing: Tokens.Spacing.m) {
                        Text("Option 1: Use your iCloud name")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("This will use the name from your Apple ID. You'll need to allow the app to discover your identity.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            requestDiscoverabilityPermission()
                        }) {
                            HStack {
                                if isRequestingPermission {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.key.fill")
                                }
                                Text(permissionButtonText)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Tokens.Spacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: Tokens.Radius.m)
                                    .fill(permissionButtonColor.gradient)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(isRequestingPermission || cloudKitService.discoverabilityPermission == .granted)
                        .glassEffect(in: .rect(cornerRadius: Tokens.Radius.m))
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Option 2: Manual Entry
                    VStack(spacing: Tokens.Spacing.m) {
                        Text("Option 2: Enter a custom name")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Enter any name you'd like others to see when you share overlaps.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if showingManualEntry {
                            VStack(spacing: Tokens.Spacing.s) {
                                TextField("Enter your display name", text: $manualName)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        setManualName()
                                    }
                                
                                HStack(spacing: Tokens.Spacing.s) {
                                    Button("Cancel") {
                                        showingManualEntry = false
                                        manualName = ""
                                    }
                                    .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button("Set Name") {
                                        setManualName()
                                    }
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .disabled(manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        } else {
                            Button(action: {
                                showingManualEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "textformat")
                                    Text("Enter Custom Name")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Tokens.Spacing.m)
                                .background(
                                    RoundedRectangle(cornerRadius: Tokens.Radius.m)
                                        .stroke(.secondary, lineWidth: 1)
                                )
                                .foregroundColor(.primary)
                            }
                            .glassEffect(in: .rect(cornerRadius: Tokens.Radius.m))
                        }
                    }
                }
                
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
    }
    
    private func requestDiscoverabilityPermission() {
        isRequestingPermission = true
        
        Task {
            let status = await cloudKitService.requestDiscoverabilityPermission()
            
            await MainActor.run {
                isRequestingPermission = false
                
                if status == .granted {
                    // Refetch the display name now that we have permission
                    Task {
                        await cloudKitService.fetchUserDisplayName()
                        // Dismiss if we successfully got a name
                        if let name = cloudKitService.userDisplayName,
                           !name.starts(with: "User "),
                           !name.contains("CloudKit User") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func setManualName() {
        let trimmedName = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        cloudKitService.setManualDisplayName(trimmedName)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        DisplayNameSetupView(cloudKitService: CloudKitService())
    }
}