//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App
//

import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrap.configureIfAvailable()
        return true
    }
}
#endif

@main
struct OverlapApp: App {
    private let onlineSubscriptionService = OnlineSubscriptionService.shared
    private let onlineHostAuthService = OnlineHostAuthService.shared
    private let onlineSessionService = OnlineSessionService.shared

    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    let overlapModelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration("OverlapContainer")
            
            return try ModelContainer(
                for: Questionnaire.self,
                Overlap.self,
                FavoriteGroup.self,
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
                .environmentObject(onlineSubscriptionService)
                .environmentObject(onlineHostAuthService)
                .environmentObject(onlineSessionService)
        }
        .modelContainer(overlapModelContainer)
    }
}
