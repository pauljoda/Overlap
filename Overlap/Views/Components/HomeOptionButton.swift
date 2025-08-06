//
//  HomeOptionButton.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//


//
//  HomeOptionButton.swift
//  Overlay
//
//  Created by Paul Davis on 7/13/25.
//

import SwiftUI

/// A customizable button for the home screen options
struct HomeOptionButton: View {

    // Paramaters
    /// The title of the button
    let title: String
    /// The system icon name to display
    let icon: String
    /// The color of the icon and border
    let color: Color

    var body: some View {
        // Horizontal stack to arrange icon, title, and chevron
        HStack(spacing: 15) {

            // Icon with specified system name and color
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)

            // Title text with styling
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()

            // Chevron icon to indicate navigation
            Image(systemName: "chevron.right")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .glassEffect(.clear.interactive())
    }
}

#Preview {
    VStack(spacing: 20) {
        HomeOptionButton(
            title: "Create an Overlay",
            icon: "plus.circle.fill",
            color: .blue
        )

        HomeOptionButton(
            title: "Browse Overlays",
            icon: "list.bullet.rectangle.fill",
            color: .red
        )
    }
    .padding()
}
