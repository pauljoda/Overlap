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
    let shareURL: URL?
    let shareMetadata: CKShare.Metadata?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath
    @StateObject private var cloudKitService = CloudKitService()
    @StateObject private var userPreferences = UserPreferences.shared
    
    @State private var isJoining = false
    @State private var joinError: Error?
    @State private var showingError = false
    @State private var joinedOverlap: Overlap?
    @State private var showingDisplayNameSetup = false
    
    init(shareURL: URL? = nil, shareMetadata: CKShare.Metadata? = nil) {
        self.shareURL = shareURL
        self.shareMetadata = shareMetadata
    }
    
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
        .sheet(isPresented: $showingDisplayNameSetup) {
            NavigationView {
                DisplayNameSetupView(cloudKitService: cloudKitService)
            }
        }
        .onChange(of: joinedOverlap) { _, overlap in
            if let overlap = overlap {
                // Validate overlap before adding to SwiftData
                guard !overlap.participants.isEmpty && !overlap.questions.isEmpty else {
                    print("⚠️ JoinOverlapView: Skipping empty joined overlap - participants: \(overlap.participants.count), questions: \(overlap.questions.count)")
                    return
                }
                
                // Add the joined overlap to SwiftData
                print("📥 JoinOverlapView: Adding joined overlap - \(overlap.title)")
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
        .onAppear {
            Task {
                await cloudKitService.checkAccountStatus()
                
                // Check if user needs display name setup before proceeding
                if cloudKitService.isAvailable && userPreferences.needsDisplayNameSetup {
                    showingDisplayNameSetup = true
                    return
                }
                
                // If we have share metadata, process it directly
                if let shareMetadata = shareMetadata {
                    await handleIncomingMetadata(shareMetadata)
                }
                // If we have a share URL, automatically try to join
                else if let shareURL = shareURL {
                    await handleIncomingURL(shareURL)
                }
            }
        }
        .onChange(of: userPreferences.isDisplayNameSetup) { _, isSetup in
            // When display name setup is completed, try to process the share
            if isSetup {
                Task {
                    if let shareMetadata = shareMetadata {
                        await handleIncomingMetadata(shareMetadata)
                    } else if let shareURL = shareURL {
                        await handleIncomingURL(shareURL)
                    }
                }
            }
        }
    }
    
    private func handleIncomingMetadata(_ metadata: CKShare.Metadata) async {
        print("JoinOverlapView: Processing share metadata: \(metadata.rootRecordID.recordName)")
        
        await MainActor.run {
            isJoining = true
        }
        
        do {
            // Accept the share using the metadata
            print("JoinOverlapView: Accepting share from metadata...")
            let overlap = try await cloudKitService.acceptShare(with: metadata)
            print("JoinOverlapView: Successfully accepted share: \(overlap.title)")
            
            await MainActor.run {
                joinedOverlap = overlap
                isJoining = false
            }
        } catch {
            print("JoinOverlapView: Error processing share metadata: \(error)")
            
            // Provide more detailed error information
            if let ckError = error as? CKError {
                print("JoinOverlapView: CloudKit error code: \(ckError.code.rawValue)")
                print("JoinOverlapView: CloudKit error description: \(ckError.localizedDescription)")
            }
            
            await MainActor.run {
                joinError = error
                showingError = true
                isJoining = false
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) async {
        print("JoinOverlapView: Processing URL: \(url)")
        
        // Check if this is a CloudKit share URL
        let urlString = url.absoluteString.lowercased()
        guard urlString.contains("icloud.com/share") || 
              urlString.contains("www.icloud.com") ||
              urlString.contains("share.icloud.com") else {
            print("JoinOverlapView: URL is not a CloudKit share URL: \(url)")
            await MainActor.run {
                joinError = CloudKitError.shareNotFound
                showingError = true
            }
            return
        }
        
        print("JoinOverlapView: Processing CloudKit share URL: \(url)")
        
        await MainActor.run {
            isJoining = true
        }
        
        do {
            // Use the correct CloudKit container
            let container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
            
            // First, test if we can get the share metadata (this will show us the exact error)
            print("JoinOverlapView: Testing share URL first...")
            try await cloudKitService.testShareURL(url)
            
            // Parse CloudKit share metadata from URL
            print("JoinOverlapView: Fetching share metadata from container: \(container.containerIdentifier ?? "unknown")")
            let metadata = try await container.shareMetadata(for: url)
            print("JoinOverlapView: Got share metadata for record: \(metadata.rootRecordID.recordName)")
            
            // Accept the share
            print("JoinOverlapView: Accepting share...")
            let overlap = try await cloudKitService.acceptShare(with: metadata)
            print("JoinOverlapView: Successfully accepted share: \(overlap.title)")
            
            await MainActor.run {
                joinedOverlap = overlap
                isJoining = false
            }
        } catch {
            print("JoinOverlapView: Error processing share URL: \(error)")
            
            // Provide more detailed error information
            if let ckError = error as? CKError {
                print("JoinOverlapView: CloudKit error code: \(ckError.code.rawValue)")
                print("JoinOverlapView: CloudKit error description: \(ckError.localizedDescription)")
            }
            
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