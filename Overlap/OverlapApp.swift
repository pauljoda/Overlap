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
    @StateObject private var cloudKitService = CloudKitService()
    @State private var pendingShareURL: URL?
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL { url in
                    handleCloudKitShareURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        handleCloudKitShareURL(url)
                    }
                }
                .sheet(item: Binding<ShareURLItem?>(
                    get: { pendingShareURL.map(ShareURLItem.init) },
                    set: { _ in pendingShareURL = nil }
                )) { item in
                    NavigationView {
                        JoinOverlapView(shareURL: item.url)
                    }
                }
        }
        .modelContainer(for: [
            Questionnaire.self,
            Overlap.self,
        ])
    }
    
    private func handleCloudKitShareURL(_ url: URL) {
        print("Received URL: \(url)")
        
        // Check if this is a CloudKit share URL (handles both www.icloud.com and share.icloud.com)
        let urlString = url.absoluteString.lowercased()
        if urlString.contains("icloud.com/share") || 
           urlString.contains("www.icloud.com") ||
           urlString.contains("share.icloud.com") {
            print("Detected CloudKit share URL, presenting join view")
            pendingShareURL = url
        } else {
            print("URL is not a CloudKit share URL: \(urlString)")
        }
    }
}

// Helper struct for sheet presentation
struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}
