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
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 10) {
                Text("No Active Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start a questionnaire to see it here")
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
    EmptyInProgressState {
        print("Browse action")
    }
}
