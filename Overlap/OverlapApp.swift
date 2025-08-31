//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App
//

import Foundation
import SharingGRDB
import SwiftUI
import CloudKit
import Dependencies

#if canImport(UIKit)
import UIKit
#endif

@main
struct OverlapApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    init() {
        // Setup db
        withErrorReporting {
            try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
                
                // Setup CloudKit syncing
                $0.defaultSyncEngine = try SyncEngine(
                    for: $0.defaultDatabase,
                    tables: Questionnaire.self, Overlap.self
                )
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

#if canImport(UIKit)
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    @Dependency(\.defaultSyncEngine) var syncEngine

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task {
            do {
                try await syncEngine.acceptShare(metadata: cloudKitShareMetadata)
            } catch {
                // You may want to surface this via logging or UI as needed
                print("Failed to accept CloudKit share: \(error)")
            }
        }
    }
}
#endif
