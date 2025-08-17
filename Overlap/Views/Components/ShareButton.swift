//
//  ShareButton.swift
//  Overlap
//
//  Button component for sharing overlap sessions via CloudKit
//

import SwiftUI
import CloudKit
import UIKit

struct ShareButton: View {
    let overlap: Overlap
    @StateObject private var cloudKitService = CloudKitService()
    @State private var showingShareSheet = false
    @State private var shareItem: Any?
    @State private var isSharing = false
    @State private var shareError: Error?
    @State private var showingError = false
    @State private var showingDisplayNameSetup = false
    
    var body: some View {
        Button(action: {
            Task {
                await shareOverlap()
            }
        }) {
            HStack(spacing: Tokens.Spacing.s) {
                if isSharing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text("Share")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, Tokens.Spacing.m)
            .padding(.vertical, Tokens.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.m)
                    .fill(.blue.gradient)
            )
        }
        .disabled(isSharing || !cloudKitService.isAvailable)
        .opacity(cloudKitService.isAvailable ? 1.0 : 0.6)
        .sheet(isPresented: $showingDisplayNameSetup) {
            NavigationView {
                DisplayNameSetupView(cloudKitService: cloudKitService)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let share = shareItem as? CKShare {
                if let shareURL = share.url {
                    // Use standard share sheet with URL if available
                    ShareSheet(items: [shareURL])
                        .presentationDetents([.medium, .large])
                } else {
                    // Fall back to CloudKit sharing controller
                    CloudKitShareSheet(share: share, container: CKContainer(identifier: "iCloud.com.pauljoda.Overlap"))
                        .presentationDetents([.medium, .large])
                }
            }
        }
        .alert("Sharing Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(shareError?.localizedDescription ?? "Failed to share overlap")
        }
    }
    
    private func shareOverlap() async {
        guard cloudKitService.isAvailable else { 
            print("ShareButton: CloudKit not available")
            return 
        }
        
        // Check if we need to setup display name first
        if cloudKitService.needsDisplayNameSetup {
            await MainActor.run {
                showingDisplayNameSetup = true
            }
            return
        }
        
        print("ShareButton: Starting share process for overlap: \(overlap.title)")
        isSharing = true
        
        do {
            // Update overlap to mark as online
            overlap.isOnline = true
            print("ShareButton: Marked overlap as online")
            
            // Create CloudKit share (this will handle zone creation and record saving)
            print("ShareButton: Creating CloudKit share...")
            let share = try await cloudKitService.shareOverlap(overlap)
            print("ShareButton: Share created successfully")
            
            // Wait a moment for CloudKit to process and generate the URL
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                shareItem = share
                showingShareSheet = true
                isSharing = false
            }
        } catch {
            print("ShareButton: Error during sharing: \(error)")
            await MainActor.run {
                shareError = error
                showingError = true
                isSharing = false
            }
        }
    }
}

// MARK: - UIKit ShareSheet Bridge

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - CloudKit ShareSheet Bridge

struct CloudKitShareSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.modalPresentationStyle = .formSheet
        
        // Wrap in a navigation controller for better presentation
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .formSheet
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("CloudKit sharing failed: \(error)")
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("CloudKit share saved successfully")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("CloudKit sharing stopped")
            // Dismiss the controller
            csc.dismiss(animated: true)
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return csc.share?[CKShare.SystemFieldKey.title] as? String ?? "Overlap Session"
        }
        
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            return nil
        }
        
        func itemType(for csc: UICloudSharingController) -> String? {
            return "com.pauljoda.Overlap.overlap"
        }
    }
}

// MARK: - Preview

#Preview {
    ShareButton(overlap: SampleData.sampleOverlap)
}