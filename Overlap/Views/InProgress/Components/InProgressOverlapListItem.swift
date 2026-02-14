//
//  InProgressOverlapListItem.swift
//  Overlap
//
//  List item component for in-progress overlaps
//

import SwiftUI

struct InProgressOverlapListItem: View {
    let overlap: Overlap
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @EnvironmentObject private var onlineHostAuthService: OnlineHostAuthService
    
    private var stateInfo: (String, Color, String) {
        switch overlap.currentState {
        case .instructions:
            return ("Setup", .blue, "person.2.fill")
        case .nextParticipant:
            return ("Ready", .green, "play.fill")
        case .answering:
            return ("Answering", .orange, "clock.fill")
        case .awaitingResponses:
            return ("Awaiting", .orange, "clock.badge.checkmark")
        case .complete:
            return ("Complete", .green, "checkmark.circle.fill")
        }
    }

    private var hostedSession: HostedOnlineSession? {
        guard overlap.isOnline, let sessionID = overlap.onlineSessionID else { return nil }
        return onlineSessionService.hostedSession(id: sessionID)
    }

    private var isCurrentDeviceHost: Bool {
        guard let hostedSession,
              let account = onlineHostAuthService.account
        else { return false }
        return hostedSession.hostAppleUserID == account.appleUserID
    }
    
    var body: some View {
        HStack(spacing: Tokens.Spacing.m) {
            // Leading icon with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [overlap.startColor.opacity(0.8), overlap.endColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: Tokens.Size.buttonStandard, height: Tokens.Size.buttonStandard)
                .overlay(
                    Text(overlap.iconEmoji)
                        .font(.title2)
                )

            // Main content
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(overlap.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Participants
                HStack(spacing: Tokens.Spacing.xs) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(overlap.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Status row — compact icon pills to prevent overflow
                HStack(spacing: Tokens.Spacing.s) {
                    HStack(spacing: Tokens.Spacing.xs) {
                        Image(systemName: stateInfo.2)
                            .font(.caption2)
                        Text(stateInfo.0)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(stateInfo.1)

                    if overlap.isOnline {
                        iconPill(icon: "icloud.fill", tint: .blue)
                    }

                    if isCurrentDeviceHost {
                        iconPill(icon: "crown.fill", tint: .green)
                    }

                    if overlap.currentState != .instructions {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 2, height: 2)

                        Text("\(Int(overlap.completionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Tokens.Spacing.s)
        .padding(.horizontal, Tokens.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .standardGlassCard()
    }

    private func iconPill(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.caption2)
            .foregroundColor(tint)
            .padding(Tokens.Spacing.xs)
            .background(tint.opacity(0.15))
            .clipShape(Circle())
    }
}

#Preview {
    InProgressOverlapListItem(overlap: SampleData.sampleInProgressOverlap)
        .environmentObject(OnlineSessionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
        .padding()
}
