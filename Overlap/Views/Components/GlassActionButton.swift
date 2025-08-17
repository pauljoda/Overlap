//
//  GlassActionButton.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable glass-effect action button component
///
/// Features:
/// - Customizable glass effect styling
/// - Icon and text support
/// - Disabled state handling
/// - Consistent styling across the app
struct GlassActionButton: View {
    let title: String
    let icon: String?
    let isEnabled: Bool
    let tintColor: Color
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        isEnabled: Bool = true,
        tintColor: Color = .green,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.tintColor = tintColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isEnabled ? tintColor : .gray)
                }
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Tokens.Size.buttonLarge)
            .glassEffect(
                .regular.interactive(isEnabled)
            )
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: Tokens.Spacing.l) {
        Spacer()
        GlassActionButton(
            title: "Begin Overlap",
            icon: "play.fill",
            isEnabled: true,
            tintColor: .green
        ) {
            print("Begin action")
        }

        GlassActionButton(
            title: "Disabled Button",
            icon: "play.fill",
            isEnabled: false,
            tintColor: .green
        ) {
            print("This won't execute")
        }
    }
    .padding()
}
