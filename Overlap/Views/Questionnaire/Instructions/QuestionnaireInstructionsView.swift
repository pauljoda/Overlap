//
//  QuestionnaireInstructionsView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SharingGRDB
import CloudKit

struct QuestionnaireInstructionsView: View {
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.defaultSyncEngine) var syncEngine

    @Binding var overlap: Overlap
    @State private var newParticipantName = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var animatingParticipants: Set<Int> = []
    @State private var sharedRecord: SharedRecord?

    private var canBegin: Bool {
        if overlap.isOnline {
            // For online overlaps, allow beginning as long as there are participants
            // (participants are set by the original creator)
            return !overlap.participants.isEmpty
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
                            ParticipantsSection(
                                overlap: overlap,
                                newParticipantName: $newParticipantName,
                                isTextFieldFocused: $isTextFieldFocused,
                                animatingParticipants: $animatingParticipants,
                                onAddParticipant: addParticipant,
                                onRemoveParticipant: removeParticipant
                            )
                        } else {
                            // For online overlaps, show existing participants (read-only)
                            OnlineParticipantsSection(overlap: overlap)
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
                
                // Share button for online overlaps
                if overlap.isOnline && canBegin {
                    HStack {
                        Spacer()
                    }
                    .padding(.horizontal, Tokens.Spacing.xl)
                }
                
                GlassActionButton(
                    title: overlap.isOnline ? Tokens.Strings.beginOnlineOverlap : Tokens.Strings.beginOverlap,
                    icon: overlap.isOnline ? "icloud.fill" : "play.fill",
                    isEnabled: canBegin,
                    tintColor: overlap.isOnline ? .blue : .green,
                    action: beginQuestionnaire
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
        // Present CloudKit sharing sheet when set
        .sheet(item: $sharedRecord, onDismiss: {
            // After the share sheet closes, move to next state for online sessions
            guard overlap.isOnline else { return }
            Task { await refreshParticipantsFromShareAndAdvance() }
        }) { sharedRecord in
            CloudSharingView(sharedRecord: sharedRecord)
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

    private func beginQuestionnaire() {
        guard canBegin else { return }
        
        // Initialize responses for all current participants
        overlap.initializeResponses()

        if overlap.isOnline {
            // For online: insert first (still in instructions), then present share sheet.
            withErrorReporting {
                try database.write { db in
                    try Overlap.insert { overlap }.execute(db)
                }
            }

            Task {
                await withErrorReporting {
                    // Configure the share title to invite others
                    sharedRecord = try await syncEngine.share(record: overlap) { share in
                        share[CKShare.SystemFieldKey.title] = ("Join '\(overlap.title)'!" as NSString)
                    }
                }
            }
        } else {
            // Offline: go straight to next participant
            overlap.currentState = .nextParticipant
            withErrorReporting {
                try database.write { db in
                    try Overlap.insert { overlap }.execute(db)
                }
            }
        }
    }

    private func refreshParticipantsFromShareAndAdvance() async {
        await withErrorReporting {
            print("[Overlap] refreshParticipantsFromShareAndAdvance: begin for id=\(overlap.id)")
            // Try to refresh participants from the CKShare metadata (with brief retry)
            var shareRef: CKShare??
            for attempt in 0..<5 {
                shareRef = try await database.read { db in
                    try Overlap
                        .metadata(for: overlap.id)
                        .select(\.share)
                        .fetchOne(db)
                }
                if shareRef != nil { break }
                print("[Overlap] No CKShare metadata yet (attempt \(attempt+1)), retrying...")
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            if let shareRef {
                print("[Overlap] Found CKShare metadata. recordID=\(shareRef!.recordID)")
                let container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
                if let record = try? await container.sharedCloudDatabase.record(for: shareRef!.recordID),
                   let ckShare = record as? CKShare {
                    print("[Overlap] Loaded CKShare. participants=\(ckShare.participants.count)")
                    let formatter = PersonNameComponentsFormatter()
                    let names: [String] = ckShare.participants.compactMap { participant in
                        if let components = participant.userIdentity.nameComponents {
                            let name = formatter.string(from: components)
                            return name.isEmpty ? nil : name
                        }
                        if let email = participant.userIdentity.lookupInfo?.emailAddress { return email }
                        if let phone = participant.userIdentity.lookupInfo?.phoneNumber { return phone }
                        return nil
                    }
                    let unique = Array(Set(names)).sorted()
                    print("[Overlap] Extracted participant names: \(unique)")
                    if !unique.isEmpty { overlap.participants = unique }
                } else {
                    print("[Overlap] Failed to load CKShare from shared database")
                }
            } else {
                print("[Overlap] CKShare metadata not found after retries; continuing")
            }

            // Move to answering and persist the change
            overlap.currentState = .answering
            try await database.write { db in
                try Overlap.update(overlap).execute(db)
            }
        }
    }
}

// MARK: - Online Participants Section

struct OnlineParticipantsSection: View {
    let overlap: Overlap
    
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
            SectionHeader(
                title: "Participants",
                icon: "person.2.fill"
            )
            
            VStack(spacing: Tokens.Spacing.s) {
                ForEach(Array(overlap.participants.enumerated()), id: \.offset) { index, participant in
                    HStack {
                        HStack(spacing: Tokens.Spacing.s) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(participant)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    .padding(.horizontal, Tokens.Spacing.m)
                    .padding(.vertical, Tokens.Spacing.s)
                    .standardGlassCard()
                }
            }
            
            // Info about online collaboration
            HStack(spacing: Tokens.Spacing.s) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Everyone answers questions independently, then results are shared")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Tokens.Spacing.s)
        }
        .padding(.horizontal, Tokens.Spacing.xl)
    }
}

#Preview("Offline") {
    let _ = setupGRDBPreview()
    QuestionnaireInstructionsView(overlap: .constant(SampleData.sampleOverlap))
}

#Preview("Online") {
    let _ = setupGRDBPreview()
    QuestionnaireInstructionsView(overlap: .constant(Overlap(
        participants: SampleData.teamMembers,
        isOnline: true,
        questionnaire: SampleData.foodPreferencesQuestionnaire,
        currentState: .instructions
    )))
}
