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
        VStack(spacing: 8) {
            Image(systemName: "person.2.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Add participants to get started")
                .font(.body)
                .foregroundColor(.secondary)

            Text("At least \(minimumParticipants) participants are required")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    EmptyParticipantsState(minimumParticipants: 2)
        .padding()
}
