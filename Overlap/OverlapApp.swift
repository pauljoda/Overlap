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
        }
        .modelContainer(for: [
            Questionnaire.self,
            Overlap.self,
        ])
    }
}
