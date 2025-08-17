//
//  JoinOverlapView.swift
//  Overlap
//
//  View for joining shared overlap sessions
//

import SwiftUI
import SwiftData
import CloudKit

struct JoinOverlapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @StateObject private var cloudKitService = CloudKitService()
    
    @State private var isJoining = false
    @State private var joinError: Error?
    @State private var showingError = false
    @State private var joinedOverlap: Overlap?
    
    var body: some View {
        GlassScreen(scrollable: false) {
            VStack(spacing: Tokens.Spacing.xl) {
                
                Spacer()
                
                // Header
                VStack(spacing: Tokens.Spacing.l) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(spacing: Tokens.Spacing.s) {
                        Text("Join Overlap")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Join a shared overlap session by tapping a share link or scanning a QR code")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Status information
                VStack(spacing: Tokens.Spacing.m) {
                    HStack(spacing: Tokens.Spacing.s) {
                        Image(systemName: cloudKitService.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(cloudKitService.isAvailable ? .green : .red)
                        Text("CloudKit: \(cloudKitService.isAvailable ? "Available" : "Unavailable")")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .standardGlassCard()
                    
                    if !cloudKitService.isAvailable {
                        Text("Please ensure you're signed into iCloud to join shared overlaps")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                    Text("How to Join")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                        HStack(alignment: .top, spacing: Tokens.Spacing.s) {
                            Text("1.")
                                .fontWeight(.medium)
                                .frame(width: 20, alignment: .leading)
                            Text("Tap a share link sent by the overlap creator")
                        }
                        
                        HStack(alignment: .top, spacing: Tokens.Spacing.s) {
                            Text("2.")
                                .fontWeight(.medium)
                                .frame(width: 20, alignment: .leading)
                            Text("The overlap will automatically open in the app")
                        }
                        
                        HStack(alignment: .top, spacing: Tokens.Spacing.s) {
                            Text("3.")
                                .fontWeight(.medium)
                                .frame(width: 20, alignment: .leading)
                            Text("Answer questions and sync your responses")
                        }
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding()
                .standardGlassCard()
                
                Spacer()
            }
            .padding(Tokens.Spacing.xl)
        }
        .navigationTitle("Join")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Join Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(joinError?.localizedDescription ?? "Failed to join overlap")
        }
        .onChange(of: joinedOverlap) { _, overlap in
            if let overlap = overlap {
                // Add the joined overlap to SwiftData
                modelContext.insert(overlap)
                try? modelContext.save()
                
                // Navigate to the overlap
                navigate(to: overlap, using: navigationPath)
            }
        }
        .onOpenURL { url in
            Task {
                await handleIncomingURL(url)
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) async {
        guard url.scheme == "https" && url.host?.hasSuffix("icloud.com") == true else {
            return
        }
        
        isJoining = true
        
        do {
            // Parse CloudKit share metadata from URL
            let metadata = try await CKContainer.default().shareMetadata(for: url)
            
            // Accept the share
            let overlap = try await cloudKitService.acceptShare(with: metadata)
            
            await MainActor.run {
                joinedOverlap = overlap
                isJoining = false
            }
        } catch {
            await MainActor.run {
                joinError = error
                showingError = true
                isJoining = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        JoinOverlapView()
    }
    .modelContainer(previewModelContainer)
}