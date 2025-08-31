//
//  QuestionnaireAwaitingResponsesView.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//

import SwiftUI
import SharingGRDB
import CloudKit

struct QuestionnaireAwaitingResponsesView: View {
    @Binding var overlap: Overlap
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.defaultSyncEngine) var syncEngine
    @State private var isAnimated = false
    @State private var isRefreshing = false
    @State private var sharedRecord: SharedRecord?
    @State private var currentParticipant: String = "Loading"
    
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
                    Button {
                        Task {
                            await shareOverlap()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

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
                currentParticipant = await overlap.getCurrentUserDisplayName(database: database)
            }
        }
        .refreshable {
            await checkForUpdates()
        }
        .sheet(item: $sharedRecord) { sharedRecord in
            CloudSharingView(sharedRecord: sharedRecord)
        }
    }
    
    private func checkForUpdates() async {
        await withErrorReporting {
            try await refreshParticipantsFromShare()
        }
    }

    private func shareOverlap() async {
        await withErrorReporting {
            sharedRecord = try await syncEngine.share(record: overlap) { share in
                share[CKShare.SystemFieldKey.title] = ("Join '\(overlap.title)'!" as NSString)
            }
        }
    }

    private func refreshParticipantsFromShare() async throws {
        print("[Overlap] AwaitingResponses: refreshParticipantsFromShare begin id=\(overlap.id)")
        // Fetch share metadata for this overlap (retry briefly)
        var shareRef: CKShare??
        for attempt in 0..<5 {
            shareRef = try await database.read { db in
                try Overlap
                    .metadata(for: overlap.id)
                    .select(\.share)
                    .fetchOne(db)
            }
            if shareRef != nil { break }
            print("[Overlap] AwaitingResponses: no CKShare metadata (attempt \(attempt+1)), retrying...")
            try await Task.sleep(nanoseconds: 300_000_000)
        }
        guard let shareRef else {
            print("[Overlap] AwaitingResponses: CKShare metadata not found")
            return
        }

        // Always use the shared DB for CKShare details
        let container = CKContainer(identifier: "iCloud.com.pauljoda.Overlap")
        let record = try await container.sharedCloudDatabase.record(for: shareRef!.recordID)
        guard let ckShare = record as? CKShare else {
            print("[Overlap] AwaitingResponses: fetched record is not CKShare")
            return
        }
        let formatter = PersonNameComponentsFormatter()
        let names: [String] = ckShare.participants.compactMap { participant in
            if let components = participant.userIdentity.nameComponents {
                let name = formatter.string(from: components)
                return name.isEmpty ? nil : name
            }
            if let email = participant.userIdentity.lookupInfo?.emailAddress {
                return email
            }
            if let phone = participant.userIdentity.lookupInfo?.phoneNumber {
                return phone
            }
            return nil
        }
        let unique = Array(Set(names)).sorted()
        print("[Overlap] AwaitingResponses: extracted names \(unique)")

        // Update overlap participants if changed
        if Set(unique) != Set(overlap.participants) {
            print("[Overlap] AwaitingResponses: updating participants")
            overlap.participants = unique
            
        }
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
    QuestionnaireAwaitingResponsesView(overlap: .constant(SampleData.awaitingResponsesOverlap))
}

#Preview("Some Completed") {
    QuestionnaireAwaitingResponsesView(overlap: .constant(SampleData.awaitingResponsesPartialOverlap))
}
