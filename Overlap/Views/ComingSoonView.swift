//
//  ComingSoonView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI

struct ComingSoonView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon to display
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                
            
            // Title and subtitle
            VStack(spacing: 10) {
                Text("Coming Soon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // Description text
            Text("This feature is currently under development. Check back soon!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ComingSoonView(title: "Create an Overlap")
    }
}
