//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App
//

import SwiftData
import SwiftUI
import Foundation

@main
struct OverlapApp: App {
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
    
    // CloudKit sync bridge for accessing private database records
    @StateObject private var cloudKitBridge: SwiftDataCloudKitBridge
    
    init() {
        let container = {
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
        
        self.overlapModelContainer = container
        self._cloudKitBridge = StateObject(wrappedValue: SwiftDataCloudKitBridge(modelContainer: container))
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .swiftDataCloudKitBridge(cloudKitBridge)
        }
        .modelContainer(overlapModelContainer)
    }
}
