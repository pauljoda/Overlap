//
//  EmptyStateView.swift
//  Overlap
//
//  A reusable empty state component that can be configured for different contexts
//

import SwiftUI

/// A reusable empty state view that displays an icon, title, message, and optional action button
///
/// Use this view to display empty states consistently throughout the app.
/// Customize the appearance with icon, colors, text, and action button.
///
/// Example usage:
/// ```swift
/// EmptyStateView(
///     icon: "doc.text.below.ecg",
///     title: "No Saved Overlaps",
///     message: "Create your first overlap to get started!",
///     buttonTitle: "Create Overlap",
///     iconColor: .purple
/// ) {
///     // Handle button tap
/// }
/// ```
struct EmptyStateView: View {
    // Required properties
    let icon: String
    let title: String
    let message: String
    
    // Optional properties
    var buttonTitle: String? = nil
    var iconColor: Color = .accentColor
    var iconSize: CGFloat = Tokens.Size.iconLarge
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.tripleXL) {
            VStack(spacing: Tokens.Spacing.l) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(iconColor.gradient)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(buttonTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, Tokens.Spacing.quadXL)
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Creates an empty state view without an action button
    init(icon: String, title: String, message: String, iconColor: Color = .accentColor) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
        self.buttonTitle = nil
        self.action = nil
    }
}

// MARK: - Previews

#Preview("With Action Button") {
    EmptyStateView(
        icon: "doc.text.below.ecg",
        title: "No Saved Overlaps",
        message: "Create your first overlap to get started!",
        buttonTitle: "Create Overlap",
        iconColor: .purple
    ) {
        print("Create tapped")
    }
}

#Preview("Without Action Button") {
    EmptyStateView(
        icon: "clock.fill",
        title: "No Active Sessions",
        message: "Start a questionnaire to see it here",
        iconColor: .orange
    )
}

#Preview("Custom Icon Size") {
    EmptyStateView(
        icon: "questionmark.circle",
        title: "No Results",
        message: "Complete the questionnaire to see results",
        iconColor: .blue,
        iconSize: Tokens.Size.iconHuge
    )
}