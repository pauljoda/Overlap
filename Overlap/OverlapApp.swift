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
