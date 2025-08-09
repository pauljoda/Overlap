//
//  EmptyQuestionnairesState.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct EmptyQuestionnairesState: View {
    let onCreateTapped: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: "doc.text.below.ecg",
            title: "No Saved Overlaps",
            message: "Create your first overlap to get started!",
            buttonTitle: "Create Overlap",
            iconColor: .purple,
            iconSize: Tokens.Size.iconXL,
            action: onCreateTapped
        )
    }
}

#Preview {
    EmptyQuestionnairesState {
        print("Create tapped")
    }
}
