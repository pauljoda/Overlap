//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App with CloudKit share handling
//

import SwiftData
import SwiftUI
import CloudKit
import Foundation

@main
struct OverlapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let cloudKitService = CloudKitService()

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
                .environment(\.cloudKitService, cloudKitService)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitShareReceived"))) { notification in
                    print("🎉 OverlapApp: Received CloudKit share notification") // BREAKPOINT HERE
                    if let metadata = notification.object as? CKShare.Metadata {
                        print("🎉 OverlapApp: Processing metadata for share: \(metadata.share.recordID)")
                        Task {
                            await handleShareAcceptance(metadata)
                        }
                    } else {
                        print("❌ OverlapApp: No metadata found in notification")
                    }
                }
        }
        .modelContainer(overlapModelContainer)
    }
    
    /// Automatically accepts a CloudKit share and navigates to the overlap
    private func handleShareAcceptance(_ metadata: CKShare.Metadata) async {
        print("🔄 OverlapApp: Processing CloudKit share acceptance...") // BREAKPOINT HERE
        print("🔄 OverlapApp: Share Record ID: \(metadata.share.recordID)")
        
        do {
            // Accept the share and create local tracking
            let modelContext = overlapModelContainer.mainContext
            try await cloudKitService.acceptShare(metadata, to: modelContext)
            print("✅ OverlapApp: Successfully accepted CloudKit share")
            
            // Give SwiftData a moment to sync
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Find the newly created overlap
            if let overlap = try findOverlapByShareRecord(metadata.share.recordID.recordName, in: modelContext) {
                print("OverlapApp: Found overlap: \(overlap.title)")
                await MainActor.run {
                    // Navigate to the overlap
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToOverlap"),
                        object: overlap
                    )
                }
                print("OverlapApp: Posted navigation notification")
            } else {
                print("OverlapApp: Could not find overlap after accepting share")
                // Try to find by zone ID as fallback
                if let overlap = try findOverlapByZoneID(metadata.share.recordID.zoneID.zoneName, in: modelContext) {
                    print("OverlapApp: Found overlap by zone ID: \(overlap.title)")
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NavigateToOverlap"),
                            object: overlap
                        )
                    }
                }
            }
            
        } catch {
            print("OverlapApp: Error accepting CloudKit share: \(error)")
            if let ckError = error as? CKError {
                print("OverlapApp: CKError code: \(ckError.code.rawValue)")
                print("OverlapApp: CKError description: \(ckError.localizedDescription)")
            }
        }
    }
    
    /// Helper to find an overlap by its share record name
    private func findOverlapByShareRecord(_ shareRecordName: String, in modelContext: ModelContext) throws -> Overlap? {
        let descriptor = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { overlap in
                overlap.shareRecordName == shareRecordName
            }
        )
        
        let overlaps = try modelContext.fetch(descriptor)
        return overlaps.first
    }
    
    private func findOverlapByZoneID(_ zoneID: String, in modelContext: ModelContext) throws -> Overlap? {
        // Zone format is typically "iCloud.com.pauljoda.Overlap.{UUID}"
        let uuidString = String(zoneID.suffix(36)) // Extract last 36 characters (UUID)
        let descriptor = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { overlap in
                overlap.id.uuidString == uuidString
            }
        )
        return try modelContext.fetch(descriptor).first
    }
}
