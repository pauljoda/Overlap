//
//  ContentView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            BlobBackgroundView()
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    HomeView()
}
