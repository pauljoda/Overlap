//
//  HomeMenuView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//


//
//  HomeMenuView.swift
//  Overlap
//
//  Created by Paul Davis on 7/13/25.
//

import SwiftUI

struct HomeMenuOptions: View {
    @Environment(\.navigationPath) private var navigationPath
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                navigate(to: .create, using: navigationPath)
            }) {
                HomeOptionButton(
                    title: "Create",
                    icon: "plus.circle.fill",
                    color: .blue
                )
            }
            
            Button(action: {
                navigate(to: .saved, using: navigationPath)
            }) {
                HomeOptionButton(
                    title: "Saved",
                    icon: "bookmark.fill",
                    color: .purple
                )
            }
            
            Button(action: {
                navigate(to: .inProgress, using: navigationPath)
            }) {
                HomeOptionButton(
                    title: "In-Progress",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            Button(action: {
                navigate(to: .completed, using: navigationPath)
            }) {
                HomeOptionButton(
                    title: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            
            Button(action: {
                navigate(to: .join, using: navigationPath)
            }) {
                HomeOptionButton(
                    title: "Join",
                    icon: "person.2.fill",
                    color: .teal
                )
            }
            
            Button(action: {
                navigate(to: .browse, using: navigationPath)
            }) {
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
