//
//  QuestionnaireView.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftUI
import SwiftData

struct QuestionnaireView: View {
    let overlap: Overlap
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @EnvironmentObject private var onlineHostAuthService: OnlineHostAuthService
    @State private var showingHostManagement = false
    @State private var showCompletionTransition = false
    @State private var lastKnownState: OverlapState?

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
        ZStack {
            // Show Different Views based on current state
            switch overlap.currentState {
            case .instructions:
                QuestionnaireInstructionsView(overlap: overlap)
            case .nextParticipant:
                QuestionnaireNextParticipantView(overlap: overlap)
            case .answering:
                QuestionnaireAnsweringView(overlap: overlap)
            case .awaitingResponses:
                QuestionnaireAwaitingResponsesView(overlap: overlap)
            case .complete:
                QuestionnaireCompleteView(overlap: overlap)
            }

        }
        .navigationTitle(
            overlap.currentState == .answering
            ? overlap.title : ""
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCurrentDeviceHost, overlap.onlineSessionID != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingHostManagement = true
                    } label: {
                        Label("Manage", systemImage: "person.3.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingHostManagement) {
            if let sessionID = overlap.onlineSessionID {
                OnlineHostManagementSheet(
                    overlap: overlap,
                    sessionID: sessionID
                )
                .presentationBackground(.ultraThinMaterial)
            }
        }
        .alert("All Responses In!", isPresented: $showCompletionTransition) {
            Button("View Results") {
                // State is already .complete so the view will render QuestionnaireCompleteView
            }
        } message: {
            Text("Everyone has finished answering. Tap to see your results.")
        }
        .onChange(of: overlap.currentState) { oldState, newState in
            if lastKnownState == .awaitingResponses, newState == .complete {
                showCompletionTransition = true
            }
            lastKnownState = newState
        }
        .onAppear {
            lastKnownState = overlap.currentState
        }
        .task {
            guard overlap.isOnline, let sessionID = overlap.onlineSessionID else { return }
            onlineSessionService.startSessionObservation(sessionID: sessionID)
        }
        .onReceive(onlineSessionService.$sessionsByID) { _ in
            guard overlap.isOnline,
                  let sessionID = overlap.onlineSessionID,
                  let session = onlineSessionService.hostedSession(id: sessionID)
            else { return }
            _ = OnlineSessionSnapshotApplier.apply(session: session, to: overlap)
            try? modelContext.save()
        }
    }
}

#Preview {
    QuestionnaireView(overlap: SampleData.sampleRandomizedOverlap)
        .environmentObject(OnlineSessionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
}
