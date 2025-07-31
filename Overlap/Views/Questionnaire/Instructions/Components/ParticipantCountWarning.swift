//
//  ParticipantCountWarning.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable warning component for insufficient participant count
/// 
/// Features:
/// - Dynamic participant count messaging
/// - Consistent warning styling
/// - Automatic pluralization
struct ParticipantCountWarning: View {
    let currentCount: Int
    let requiredCount: Int
    
    private var remainingCount: Int {
        requiredCount - currentCount
    }
    
    private var isPlural: Bool {
        remainingCount != 1
    }
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            
            Text("Add at least \(remainingCount) more participant\(isPlural ? "s" : "") to begin")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.top, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        ParticipantCountWarning(currentCount: 1, requiredCount: 2)
        ParticipantCountWarning(currentCount: 0, requiredCount: 3)
    }
    .padding()
}
