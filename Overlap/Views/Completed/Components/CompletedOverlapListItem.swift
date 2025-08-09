//
//  CompletedOverlapListItem.swift
//  Overlap
//
//  List item component for completed overlaps
//

import SwiftUI

struct CompletedOverlapListItem: View {
    let overlap: Overlap
    
    var body: some View {
        HStack(spacing: 12) {
            // Leading icon with gradient from overlap's colors
            Circle()
                .fill(
                    LinearGradient(
                        colors: [overlap.startColor.opacity(0.8), overlap.endColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(overlap.iconEmoji)
                        .font(.title2)
                )
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(overlap.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Session info
                HStack(spacing: 12) {
                    // Participants count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(overlap.participants.count) participants")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Separator
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)
                    
                    // Questions count
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(overlap.questions.count) questions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Completion date
                if let completeDate = overlap.completeDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("Completed \(completeDate, style: .date)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Trailing chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .standardGlassCard()
    }
}

#Preview {
    CompletedOverlapListItem(overlap: SampleData.sampleCompletedOverlap)
        .padding()
}
