//
//  HomeMenuOptions.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI

struct HomeMenuOptions: View {
    @Environment(\.navigationPath) private var navigationPath
    @State private var showDeveloperOptions = false
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
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
            
            // Developer demo (hidden behind long press)
            Button(action: {
                navigationPath.wrappedValue.append("cloudkit-demo")
            }) {
                HomeOptionButton(
                    title: "CloudKit Demo",
                    icon: "cloud.fill",
                    color: .cyan
                )
            }
            .opacity(showDeveloperOptions ? 1.0 : 0.0)
            .animation(.easeInOut, value: showDeveloperOptions)
        }
        .onLongPressGesture {
            withAnimation {
                showDeveloperOptions.toggle()
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
