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
    @Environment(\.navigationPath) private var navigationPath
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                navigationPath.wrappedValue.append(SampleData.sampleOverlap)
            }) {
                HomeOptionButton(
                    title: "Create",
                    icon: "plus.circle.fill",
                    color: .blue
                )
            }
            
            Button(action: {
                navigationPath.wrappedValue.append("saved")
            }) {
                HomeOptionButton(
                    title: "Saved",
                    icon: "bookmark.fill",
                    color: .purple
                )
            }
            
            Button(action: {
                navigationPath.wrappedValue.append("in-progress")
            }) {
                HomeOptionButton(
                    title: "In-Progress",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            Button(action: {
                navigationPath.wrappedValue.append("completed")
            }) {
                HomeOptionButton(
                    title: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            
            Button(action: {
                navigationPath.wrappedValue.append("join")
            }) {
                HomeOptionButton(
                    title: "Join",
                    icon: "person.2.fill",
                    color: .teal
                )
            }
            
            Button(action: {
                navigationPath.wrappedValue.append("browse")
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
