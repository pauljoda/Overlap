//
//  HomeMenuView.swift
//  Overlay
//
//  Created by Paul Davis on 7/13/25.
//

import SwiftUI

struct HomeMenuView: View {
    var body: some View {
        VStack(spacing: 20) {
            NavigationLink(destination: CreateOverlayView()) {
                HomeOptionButton(
                    title: "Create an Overlay",
                    icon: "plus.circle.fill",
                    color: .blue
                )
            }
            
            NavigationLink(destination: SavedOverlaysView()) {
                HomeOptionButton(
                    title: "Saved Overlays",
                    icon: "bookmark.fill",
                    color: .purple
                )
            }
            
            NavigationLink(destination: ComingSoonView(title: "In-Progress Overlays")) {
                HomeOptionButton(
                    title: "In-Progress Overlays",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            NavigationLink(destination: CompletedOverlaysView()) {
                HomeOptionButton(
                    title: "Completed Overlays",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        
            
            NavigationLink(destination: ComingSoonView(title: "Join an Overlay")) {
                HomeOptionButton(
                    title: "Join an Overlay",
                    icon: "person.2.fill",
                    color: .teal
                )
            }
            
            NavigationLink(destination: OverlayListView()) {
                HomeOptionButton(
                    title: "Browse Overlays",
                    icon: "list.bullet.rectangle.fill",
                    color: .red
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeMenuView()
            .padding()
    }
}