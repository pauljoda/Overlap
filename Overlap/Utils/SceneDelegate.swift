//
//  SceneDelegate.swift
//  Overlap
//
//  Scene delegate for CloudKit share handling
//

import SwiftUI
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // For a scene-based iOS app in a running or suspended state, CloudKit calls the windowScene(_:userDidAcceptCloudKitShareWith:) method on your window scene delegate.
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        print("🎯 SceneDelegate: userDidAcceptCloudKitShareWith: \(cloudKitShareMetadata)")
        Task {
            await acceptShare(cloudKitShareMetadata)
        }
    }
    
    // For a scene-based iOS app that's not running, the system launches your app in response to the tap or click, and calls the scene(_:willConnectTo:options:) method on your scene delegate. The connectionOptions parameter contains the metadata. Use its cloudKitShareMetadata property to access it.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shareMetadata = connectionOptions.cloudKitShareMetadata {
            print("🎯 SceneDelegate: scene willConnectTo with share metadata: \(shareMetadata)")
            Task {
                await acceptShare(shareMetadata)
            }
        }
    }
    
    // MARK: - Share Acceptance Logic
    
    private func acceptShare(_ shareMetadata: CKShare.Metadata) async {
        print("🔄 SceneDelegate: Starting share acceptance process")
        
        do {
            // Get the CloudKit service instance
            let cloudKitService = CloudKitService()
            
            // Call the share acceptance method
            try await cloudKitService.shareAccepted(shareMetadata)
            
            // Post notification to navigate to the shared overlap
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CloudKitShareReceived"),
                    object: shareMetadata
                )
            }
            
        } catch {
            print("❌ SceneDelegate: Error accepting share: \(error)")
        }
    }
}