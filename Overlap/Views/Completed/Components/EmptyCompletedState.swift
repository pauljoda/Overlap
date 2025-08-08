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
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 10) {
                Text("No Completed Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Finish a questionnaire session to see results here")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Browse Saved Questionnaires") {
                onBrowseAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    EmptyCompletedState {
        print("Browse action")
    }
}
