//
//  OverlapApp.swift
//  Overlap
//
//  Main SwiftUI App
//

import Foundation
import SharingGRDB
import SwiftUI

@main
struct OverlapApp: App {
    init() {
        // Setup db
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
