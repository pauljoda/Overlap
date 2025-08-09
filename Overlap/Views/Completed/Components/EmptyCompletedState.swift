//
//  EmptyCompletedState.swift
//  Overlap
//
//  Empty state view for when there are no completed overlaps
//

import SwiftUI

struct EmptyCompletedState: View {
    let onBrowseAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            EmptyStateView(
                icon: "checkmark.circle.fill",
                title: "No Completed Sessions",
                message: "Finish a questionnaire session to see results here",
                buttonTitle: "Browse Saved Questionnaires",
                iconColor: .green,
                action: onBrowseAction
            )
            
            Spacer()
        }
    }
}

#Preview {
    EmptyCompletedState {
        print("Browse action")
    }
}
