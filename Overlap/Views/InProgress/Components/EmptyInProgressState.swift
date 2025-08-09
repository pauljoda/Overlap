//
//  EmptyInProgressState.swift
//  Overlap
//
//  Empty state view for when there are no in-progress overlaps
//

import SwiftUI

struct EmptyInProgressState: View {
    let onBrowseAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            EmptyStateView(
                icon: "clock.fill",
                title: "No Active Sessions",
                message: "Start a questionnaire to see it here",
                buttonTitle: "Browse Saved Questionnaires",
                iconColor: .orange,
                action: onBrowseAction
            )
            
            Spacer()
        }
    }
}

#Preview {
    EmptyInProgressState {
        print("Browse action")
    }
}
