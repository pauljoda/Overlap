//
//  AppDelegate.swift
//  Overlap
//
//  UIApplicationDelegate for handling CloudKit share invitations
//

import UIKit
import CloudKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    /// Shared instance to coordinate with SwiftUI app
    static let shared = AppDelegate()
    
    /// Callback for when a CloudKit share is accepted
    var onCloudKitShareAccepted: ((CKShare.Metadata) -> Void)?
    
    /// Called when the user accepts a CloudKit share invitation from the system
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        print("AppDelegate: User accepted CloudKit share with metadata: \(cloudKitShareMetadata.rootRecordID.recordName)")
        
        // Handle the share acceptance
        Task { @MainActor in
            await handleCloudKitShareAcceptance(cloudKitShareMetadata)
        }
    }
    
    /// Handles the CloudKit share acceptance
    @MainActor
    private func handleCloudKitShareAcceptance(_ metadata: CKShare.Metadata) async {
        print("AppDelegate: Processing CloudKit share acceptance...")
        
        // Call the callback if set (for coordination with SwiftUI)
        onCloudKitShareAccepted?(metadata)
        
        // Also try to handle directly if no callback is set
        if onCloudKitShareAccepted == nil {
            await processShareDirectly(metadata)
        }
    }
    
    /// Processes the share directly using CloudKit service
    private func processShareDirectly(_ metadata: CKShare.Metadata) async {
        do {
            let cloudKitService = CloudKitService()
            let overlap = try await cloudKitService.acceptShare(with: metadata)
            print("AppDelegate: Successfully accepted share for overlap: \(overlap.title)")
            
            // Post a notification to inform the app about the new overlap
            NotificationCenter.default.post(
                name: NSNotification.Name("CloudKitShareAccepted"),
                object: overlap
            )
        } catch {
            print("AppDelegate: Failed to accept CloudKit share: \(error)")
            
            // Post error notification
            NotificationCenter.default.post(
                name: NSNotification.Name("CloudKitShareAcceptError"),
                object: error
            )
        }
    }
}
