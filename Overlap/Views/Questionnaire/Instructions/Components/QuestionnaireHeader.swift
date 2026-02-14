//
//  QuestionnaireHeader.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

/// A reusable header component for questionnaire views
/// 
/// Features:
/// - Title and instructions display from Overlap questionnaire
/// - Consistent typography and spacing
/// - Responsive design
struct QuestionnaireHeader: View {
    let overlap: Overlap
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @EnvironmentObject private var onlineHostAuthService: OnlineHostAuthService

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
        VStack(spacing: Tokens.Spacing.l) {
            if overlap.isOnline {
                HStack(spacing: Tokens.Spacing.s) {
                    Spacer()
                    OnlineIndicator(isOnline: true, style: .detailed)
                    if isCurrentDeviceHost {
                        Text("Host")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, Tokens.Spacing.s)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Text(overlap.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(overlap.information)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Tokens.Spacing.xl)
        }
        .padding(.top, Tokens.Spacing.xl)
    }
}

#Preview {
    QuestionnaireHeader(overlap: SampleData.sampleOverlap)
        .environmentObject(OnlineSessionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
        .padding()
}
