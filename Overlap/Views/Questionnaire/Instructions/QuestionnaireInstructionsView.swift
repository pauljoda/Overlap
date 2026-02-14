//
//  QuestionnaireInstructionsView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireInstructionsView: View {
    let overlap: Overlap

    init(overlap: Overlap) {
        self.overlap = overlap
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @EnvironmentObject private var onlineHostAuthService: OnlineHostAuthService
    @Query(sort: \FavoriteGroup.name) private var favoriteGroups: [FavoriteGroup]
    @State private var newParticipantName = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var animatingParticipants: Set<Int> = []

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

    private var canBegin: Bool {
        if overlap.isOnline {
            if let session = hostedSession,
               let participantID = overlap.onlineParticipantID?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !participantID.isEmpty {
                return session.participantIDsByDisplayName.values.contains {
                    $0.caseInsensitiveCompare(participantID) == .orderedSame
                }
            }

            guard let onlineParticipantDisplayName = overlap.onlineParticipantDisplayName else {
                return false
            }

            return overlap.participants.contains { participant in
                participant.caseInsensitiveCompare(onlineParticipantDisplayName) == .orderedSame
            }
        } else {
            // For local overlaps, require at least 2 participants
            return overlap.participants.count >= 2
        }
    }

    var body: some View {
        ZStack {
            GlassScreen {
                ScrollView {
                    VStack(spacing: Tokens.Spacing.xxl) {
                        // Header Section
                        QuestionnaireHeader(overlap: overlap)

                        // Participants Section
                        if !overlap.isOnline {
                            if !favoriteGroups.isEmpty {
                                favoriteGroupPicker
                            }

                            ParticipantsSection(
                                overlap: overlap,
                                newParticipantName: $newParticipantName,
                                isTextFieldFocused: $isTextFieldFocused,
                                animatingParticipants: $animatingParticipants,
                                onAddParticipant: addParticipant,
                                onRemoveParticipant: removeParticipant
                            )
                        } else {
                            OnlineInstructionsSection(
                                overlap: overlap,
                                isCurrentDeviceParticipant: canBegin
                            )
                        }

                        // Bottom spacing to account for floating button and safe area
                        Spacer()
                            .frame(height: Tokens.Size.buttonLarge + Tokens.Spacing.xl * 2)
                    }
                    .padding(.top, Tokens.Spacing.xl)
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }

            // Floating action buttons - overlayed at bottom
            VStack(spacing: Tokens.Spacing.m) {
                Spacer()

                GlassActionButton(
                    title: overlap.isOnline ? "Begin" : Tokens.Strings.beginOverlap,
                    icon: overlap.isOnline ? "icloud.fill" : "play.fill",
                    isEnabled: canBegin,
                    tintColor: overlap.isOnline ? .blue : .green,
                    action: {
                        Task { await beginQuestionnaire() }
                    }
                )
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.bottom, Tokens.Spacing.xl)
                .offset(y: canBegin ? 0 : 150)
                .animation(.easeInOut(duration: 0.5), value: canBegin)
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    private var favoriteGroupPicker: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(title: "Quick Fill", icon: "person.3.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Tokens.Spacing.s) {
                    if let lastUsed = lastUsedParticipants, !lastUsed.isEmpty {
                        Button {
                            applyParticipants(lastUsed)
                        } label: {
                            Label("Last Used", systemImage: "clock.arrow.circlepath")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }

                    ForEach(favoriteGroups) { group in
                        Button {
                            applyParticipants(group.participants)
                        } label: {
                            Label(group.name, systemImage: "star.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                    }
                }
            }
        }
        .padding(.horizontal, Tokens.Spacing.xl)
    }

    private var lastUsedParticipants: [String]? {
        let descriptor = FetchDescriptor<Overlap>(
            predicate: #Predicate<Overlap> { o in
                o.isOnline == false
            },
            sortBy: [SortDescriptor(\Overlap.beginDate, order: .reverse)]
        )
        guard let recent = try? modelContext.fetch(descriptor).first,
              recent.id != overlap.id
        else { return nil }
        return recent.participants.isEmpty ? nil : recent.participants
    }

    private func applyParticipants(_ names: [String]) {
        withAnimation {
            overlap.participants = names
            animatingParticipants = []
        }
    }

    private func addParticipant() {
        let trimmedName = newParticipantName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty,
            !overlap.participants.contains(trimmedName)
        else {
            return
        }

        let newIndex = overlap.participants.count
        overlap.participants.append(trimmedName)
        newParticipantName = ""
        isTextFieldFocused = false

        // Start animation for the new participant
        animatingParticipants.insert(newIndex)

        // After a brief delay, expand the participant row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: Tokens.Duration.fast)) {
                _ = animatingParticipants.remove(newIndex)
            }
        }
    }

    private func removeParticipant(at index: Int) {
        guard index < overlap.participants.count else { return }

        // Start removal animation - shrink to circle first
        animatingParticipants.insert(index)

        // After animation completes, remove the participant
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Clean up animation state for the removed participant
            animatingParticipants.remove(index)

            // Clear any animation states for participants with indices greater than the removed one
            // This prevents the shifting participants from being animated
            let participantsToCleanup = animatingParticipants.filter {
                $0 > index
            }
            for participantIndex in participantsToCleanup {
                animatingParticipants.remove(participantIndex)
            }

            withAnimation(.easeInOut(duration: Tokens.Duration.fast)) {
                overlap.participants.remove(at: index)
            }
        }
    }

    @MainActor
    private func beginQuestionnaire() async {
        guard canBegin else { return }

        if overlap.isOnline {
            // Online sessions are backend-authoritative and should not be reset locally.
            if isCurrentDeviceHost,
               let sessionID = overlap.onlineSessionID,
               hostedSession?.phase == .lobby {
                _ = try? await onlineSessionService.beginSessionOnline(sessionID: sessionID)
            }
            // Online uses the same participant-start screen before answering.
            overlap.currentState = .nextParticipant
        } else {
            // Initialize responses for all current participants.
            overlap.initializeResponses()
            // For local overlaps, use the participant selection flow
            overlap.currentState = .nextParticipant
        }

        try? modelContext.save()        
    }
}

// MARK: - Online Participants Section

struct OnlineInstructionsSection: View {
    let overlap: Overlap
    let isCurrentDeviceParticipant: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(
                title: "Instructions",
                icon: "list.bullet.clipboard.fill"
            )

            Text(overlap.instructions)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.Spacing.l)
                .standardGlassCard()

            HStack(spacing: Tokens.Spacing.s) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Answers sync live across participants.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Tokens.Spacing.s)

            if !isCurrentDeviceParticipant {
                HStack(spacing: Tokens.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("You are no longer in this session. Ask the host to add you again.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Tokens.Spacing.s)
            }
        }
        .padding(.horizontal, Tokens.Spacing.xl)
    }
}

#Preview {
    QuestionnaireInstructionsView(overlap: SampleData.sampleOverlap)
        .environmentObject(OnlineSessionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
        .modelContainer(for: [Overlap.self, FavoriteGroup.self], inMemory: true)
}
