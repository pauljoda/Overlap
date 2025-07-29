//
//  HomeMenuView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//


//
//  HomeMenuView.swift
//  Overlay
//
//  Created by Paul Davis on 7/13/25.
//

import SwiftUI

struct HomeMenuOptions: View {
    var body: some View {
        VStack(spacing: 20) {
            NavigationLink(destination: CreateView()) {
                HomeOptionButton(
                    title: "Create",
                    icon: "plus.circle.fill",
                    color: .blue
                )
            }
            
            NavigationLink(destination: ComingSoonView(title: "Saved")) {
                HomeOptionButton(
                    title: "Saved",
                    icon: "bookmark.fill",
                    color: .purple
                )
            }
            
            NavigationLink(destination: ComingSoonView(title: "In-Progress")) {
                HomeOptionButton(
                    title: "In-Progress",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            NavigationLink(destination: ComingSoonView(title: "Completed")) {
                HomeOptionButton(
                    title: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        
            
            NavigationLink(destination: ComingSoonView(title: "Join")) {
                HomeOptionButton(
                    title: "Join",
                    icon: "person.2.fill",
                    color: .teal
                )
            }
            
            NavigationLink(destination: ComingSoonView(title: "Browse")) {
                HomeOptionButton(
                    title: "Browse",
                    icon: "list.bullet.rectangle.fill",
                    color: .red
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeMenuOptions()
            .padding()
    }
}
