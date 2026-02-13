//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App
//

import SwiftData
import SwiftUI

@main
struct OverlapApp: App {
    // Keep the CloudKit service available for legacy screens while online
    // collaboration transitions to the new backend flow.
    private let cloudKitService = CloudKitService()
    private let onlineSubscriptionService = OnlineSubscriptionService.shared
    private let onlineHostAuthService = OnlineHostAuthService.shared
    private let onlineSessionService = OnlineSessionService.shared

    let overlapModelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration("OverlapContainer")
            
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
                .environment(
                    \.onlineSubscriptionService,
                    onlineSubscriptionService
                )
                .environment(
                    \.onlineHostAuthService,
                    onlineHostAuthService
                )
                .environment(\.onlineSessionService, onlineSessionService)
        }
        .modelContainer(overlapModelContainer)
    }
}
