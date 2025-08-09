//
//  EmptyParticipantsState.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable empty state component for when no participants have been added
/// 
/// Features:
/// - Consistent empty state messaging
/// - Icon and text styling
/// - Requirement information display
struct EmptyParticipantsState: View {
    let minimumParticipants: Int
    
    var body: some View {
        EmptyStateView(
            icon: "person.2.badge.plus",
            title: "Add participants to get started",
            message: "At least \(minimumParticipants) participants are required",
            iconColor: .secondary,
            iconSize: Tokens.Size.iconMedium
        )
        .padding(.vertical, Tokens.Spacing.quadXL)
    }
}

#Preview {
    EmptyParticipantsState(minimumParticipants: 2)
        .padding()
}
