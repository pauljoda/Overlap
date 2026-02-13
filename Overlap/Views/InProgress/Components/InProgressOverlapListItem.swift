//
//  InProgressOverlapListItem.swift
//  Overlap
//
//  List item component for in-progress overlaps
//

import SwiftUI

struct InProgressOverlapListItem: View {
    let overlap: Overlap
    
    private var stateInfo: (String, Color, String) {
        switch overlap.currentState {
        case .instructions:
            return ("Setting up", .blue, "person.2.fill")
        case .nextParticipant:
            return ("Ready to start", .green, "play.fill")
        case .answering:
            return ("In progress", .orange, "clock.fill")
        case .awaitingResponses:
            return ("Awaiting responses", .orange, "clock.badge.checkmark")
        case .complete:
            return ("Complete", .green, "checkmark.circle.fill")
        }
    }
    
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
                
                // Progress info
                Text("\(overlap.participants.count) participants")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Status and metadata
                HStack(spacing: 12) {
                    // Status
                    HStack(spacing: 4) {
                        Image(systemName: stateInfo.2)
                            .font(.caption2)
                            .foregroundColor(stateInfo.1)
                        Text(stateInfo.0)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(stateInfo.1)
                    }
                    
                    // Online indicator
                    OnlineIndicator(isOnline: overlap.isOnline, style: .compact)
                    
                    if overlap.currentState != .instructions {
                        // Separator
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 2, height: 2)
                        
                        // Progress indicator
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(overlap.completionPercentage * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Trailing chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Tokens.Spacing.s)
        .padding(.horizontal, Tokens.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width touch target
        .contentShape(Rectangle()) // Make entire area tappable
        .standardGlassCard()
    }
}

#Preview {
    InProgressOverlapListItem(overlap: SampleData.sampleInProgressOverlap)
        .padding()
}
