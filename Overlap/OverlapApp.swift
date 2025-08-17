//
//  OverlapApp.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftData
import SwiftUI

@main
struct OverlapApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onOpenURL { url in
                    handleCloudKitShareURL(url)
                }
        }
        .modelContainer(for: [
            Questionnaire.self,
            Overlap.self,
        ])
    }
    
    private func handleCloudKitShareURL(_ url: URL) {
        // CloudKit share URLs will be handled by the JoinOverlapView
        // This is just a placeholder for global URL handling if needed
        print("Received URL: \(url)")
    }
}
