//
//  SectionHeader.swift
//  Overlap
//
//  Created by Paul Davis on 8/6/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader(title: "Basic Information", icon: "info.circle.fill")
        SectionHeader(title: "Visual Style", icon: "paintbrush.fill")
        SectionHeader(title: "Questions", icon: "questionmark.bubble.fill")
    }
    .padding()
}
