//
//  QuestionnaireAwaitingResponsesView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI

struct QuestionnaireAwaitingResponsesView: View {
    let overlap: Overlap
    @State private var isAnimated = false
    @State private var isRefreshing = false
    
    private var completedParticipants: [String] {
        overlap.participants.filter { overlap.isParticipantComplete($0) }
    }
    
    private var pendingParticipants: [String] {
        overlap.participants.filter { !overlap.isParticipantComplete($0) }
    }
    
    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.tripleXL) {
                // Header
                VStack(spacing: Tokens.Spacing.xl) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: Tokens.Size.iconHuge))
                        .foregroundColor(.orange)
                        .scaleEffect(isAnimated ? 1.0 : 0.8)
                        .animation(.spring(response: Tokens.Spring.response, dampingFraction: Tokens.Spring.damping), value: isAnimated)
                    
                    Text(Tokens.Strings.awaitingResponses)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(isAnimated ? 1 : 0)
                        .animation(.easeIn(duration: Tokens.Duration.medium).delay(0.2), value: isAnimated)
                    
                    Text("Some participants have finished, waiting for others to complete their responses.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Tokens.Spacing.xl)
                        .opacity(isAnimated ? 1 : 0)
                        .animation(.easeIn(duration: Tokens.Duration.medium).delay(0.4), value: isAnimated)
                }
                
                // Participants Status
                VStack(spacing: Tokens.Spacing.l) {
                    if !completedParticipants.isEmpty {
                        ParticipantStatusSection(
                            title: Tokens.Strings.completedResponses,
                            icon: "checkmark.circle.fill",
                            participants: completedParticipants,
                            color: .green,
                            isAnimated: isAnimated,
                            delay: Tokens.Delay.long
                        )
                    }
                    
                    if !pendingParticipants.isEmpty {
                        ParticipantStatusSection(
                            title: Tokens.Strings.pendingResponses,
                            icon: "clock.circle.fill", 
                            participants: pendingParticipants,
                            color: .orange,
                            isAnimated: isAnimated,
                            delay: Tokens.Delay.extraLong
                        )
                    }
                }
                
                // Share button to invite more participants
                VStack(spacing: Tokens.Spacing.m) {
                 
                    
                    Text("Invite more participants to get their responses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimated ? 1 : 0)
                        .animation(.easeIn(duration: Tokens.Duration.medium).delay(Tokens.Delay.extraLong + 0.4), value: isAnimated)
                }
                .padding(.top, Tokens.Spacing.l)
                
                Spacer()
            }
            .padding(Tokens.Spacing.xl)
        }
        .onAppear {
            isAnimated = true
            
            // Check for updates when view appears
            Task {
                await checkForUpdates()
            }
        }
        .refreshable {
            await checkForUpdates()
        }
    }
    
    private func checkForUpdates() async {
       
    }
}

struct ParticipantStatusSection: View {
    let title: String
    let icon: String
    let participants: [String]
    let color: Color
    let isAnimated: Bool
    let delay: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            HStack(spacing: Tokens.Spacing.s) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: Tokens.Spacing.xs) {
                ForEach(participants, id: \.self) { participant in
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(color)
                            .frame(width: 16)
                        
                        Text(participant)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, Tokens.Spacing.m)
                    .padding(.vertical, Tokens.Spacing.s)
                    .standardGlassCard()
                }
            }
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.easeIn(duration: Tokens.Duration.medium).delay(delay), value: isAnimated)
    }
}

#Preview("All Pending") {
    QuestionnaireAwaitingResponsesView(overlap: SampleData.awaitingResponsesOverlap)
}

#Preview("Some Completed") {
    QuestionnaireAwaitingResponsesView(overlap: SampleData.awaitingResponsesPartialOverlap)
}
