//
//  OverlapApp.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftData
import SwiftUI
import CloudKit

@main
struct OverlapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var cloudKitService = CloudKitService()
    @State private var pendingShareURL: URL?
    @State private var pendingShareMetadata: CKShare.Metadata?

    let overlapModelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration("OverlapContainer", cloudKitDatabase: .private("iCloud.com.pauljoda.Overlap"))
            
            return try ModelContainer(
                for: Questionnaire.self,
                Overlap.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    // Set up the app delegate callback for CloudKit shares
                    AppDelegate.shared.onCloudKitShareAccepted = { metadata in
                        pendingShareMetadata = metadata
                    }
                }
                .onOpenURL { url in
                    handleURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        handleURL(url)
                    }
                }
                .sheet(item: Binding<ShareURLItem?>(
                    get: { 
                        if let metadata = pendingShareMetadata {
                            return ShareURLItem(url: nil, metadata: metadata)
                        } else if let url = pendingShareURL {
                            return ShareURLItem(url: url, metadata: nil)
                        }
                        return nil
                    },
                    set: { _ in 
                        pendingShareURL = nil
                        pendingShareMetadata = nil
                    }
                )) { item in
                    NavigationView {
                        if let metadata = item.metadata {
                            JoinOverlapView(shareMetadata: metadata)
                        } else if let url = item.url {
                            JoinOverlapView(shareURL: url)
                        } else {
                            JoinOverlapView()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitShareAccepted"))) { notification in
                    if let overlap = notification.object as? Overlap {
                        handleAcceptedShare(overlap)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitShareAcceptError"))) { notification in
                    if let error = notification.object as? Error {
                        print("OverlapApp: CloudKit share accept error: \(error)")
                        // Could show an alert here if needed
                    }
                }
        }
        .modelContainer(overlapModelContainer)
    }
    
    private func handleURL(_ url: URL) {
        print("OverlapApp: Received URL: \(url)")
        
        // Check if this is a CloudKit share URL
        let urlString = url.absoluteString.lowercased()
        if isCloudKitShareURL(urlString) {
            print("OverlapApp: Detected CloudKit share URL, checking user ownership")
            
            // Check if current user is the owner of this share
            Task {
                await handleCloudKitShareURL(url)
            }
        } else {
            print("OverlapApp: URL is not a CloudKit share URL: \(urlString)")
        }
    }
    
    private func handleCloudKitShareURL(_ url: URL) async {
        do {
            // First check CloudKit availability
            await cloudKitService.checkAccountStatus()
            
            guard cloudKitService.isAvailable else {
                print("OverlapApp: CloudKit not available, showing join view for setup")
                await MainActor.run {
                    pendingShareURL = url
                }
                return
            }
            
            // Try to get the share metadata to extract the overlap ID
            let metadata = try await cloudKitService.container.shareMetadata(for: url)
            let overlapId = metadata.rootRecordID.recordName
            
            // Check if we already have this overlap locally
            let context = overlapModelContainer.mainContext
            let descriptor = FetchDescriptor<Overlap>(
                predicate: #Predicate<Overlap> { overlap in
                    overlap.id.uuidString == overlapId
                }
            )
            
            if let existingOverlap = try context.fetch(descriptor).first {
                // We already have this overlap - navigate to it directly
                print("OverlapApp: Found existing overlap locally, navigating to it")
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToOverlap"),
                        object: existingOverlap
                    )
                }
            } else {
                // We don't have this overlap - treat as new user joining
                print("OverlapApp: Overlap not found locally, treating as new join")
                await handleNewUserJoining(url)
            }
            
        } catch {
            print("OverlapApp: Error processing CloudKit share URL: \(error)")
            // Fall back to showing join view
            await MainActor.run {
                pendingShareURL = url
            }
        }
    }
    
    private func handleNewUserJoining(_ url: URL) async {
        // Check if user needs display name setup
        if cloudKitService.needsDisplayNameSetup {
            print("OverlapApp: User needs display name setup before joining")
        } else {
            print("OverlapApp: User ready to join overlap")
        }
        
        // Always show join view for new users - it will handle display name setup if needed
        await MainActor.run {
            pendingShareURL = url
        }
    }
    
    private func isCloudKitShareURL(_ urlString: String) -> Bool {
        return urlString.contains("icloud.com/share") || 
               urlString.contains("www.icloud.com") ||
               urlString.contains("share.icloud.com") ||
               urlString.hasPrefix("overlap://")
    }
    
    private func handleAcceptedShare(_ overlap: Overlap) {
        // Add the overlap to SwiftData
        let context = overlapModelContainer.mainContext
        context.insert(overlap)
        try? context.save()
        print("OverlapApp: Added accepted share to SwiftData: \(overlap.title)")
    }
}

// Helper struct for sheet presentation
struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL?
    let metadata: CKShare.Metadata?
    
    init(url: URL?, metadata: CKShare.Metadata? = nil) {
        self.url = url
        self.metadata = metadata
    }
}
