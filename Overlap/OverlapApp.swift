//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App with CloudKit share handling
//

import CloudKit
import Foundation
import SharingGRDB
import SwiftData
import SwiftUI

@main
struct OverlapApp: App {
    init() {
        // Setup db
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    let overlapModelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(
                "OverlapContainer",
                cloudKitDatabase: .private("iCloud.com.pauljoda.Overlap")
            )

            return try ModelContainer(
                for: Overlap.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(overlapModelContainer)
    }
}
