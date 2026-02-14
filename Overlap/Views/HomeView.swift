//
//  HomeView.swift
//  Overlap
//
//  Created by Paul Davis on 7/24/25.
//

import SwiftUI
import SwiftData

// Environment key for NavigationPath
struct NavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath> = .constant(NavigationPath())
}

extension EnvironmentValues {
    var navigationPath: Binding<NavigationPath> {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }
}

struct HomeView: View {
    @State private var path = NavigationPath()
    @State private var observedOnlineSessionIDs: Set<String> = []
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onlineSessionService: OnlineSessionService
    @Query(
        filter: #Predicate<Overlap> { overlap in
            overlap.isOnline == true
        }
    ) private var onlineOverlaps: [Overlap]

    private var trackedOnlineSessionIDs: Set<String> {
        Set(
            onlineOverlaps.compactMap { overlap in
                guard let sessionID = overlap.onlineSessionID?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                      !sessionID.isEmpty
                else { return nil }
                return sessionID
            }
        )
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Setup Background
                BlobBackgroundView()
                
                VStack(spacing: Tokens.Spacing.quadXL) {
                    Spacer()
                    
                    //App Title
                    VStack(spacing: Tokens.Spacing.s) {
                        Text("Overlap")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("See where your opinions overlap")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        HomeMenuOptions()
                            .padding()
                            .frame(maxWidth: Tokens.Size.maxContentWidth)
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(Tokens.Spacing.xl)
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "create":
                    CreateQuestionnaireView()
                case "saved":
                    SavedView()
                case "in-progress":
                    InProgressView()
                case "completed":
                    CompletedView()
                case "browse":
                    BrowseView()
                case "settings":
                    SettingsView()
                case let editPath where editPath.hasPrefix("edit-"):
                    // Extract questionnaire ID for editing
                    let questionnaireId = String(editPath.dropFirst(5)) // Remove "edit-" prefix
                    if let uuid = UUID(uuidString: questionnaireId) {
                        EditQuestionnaireView(questionnaireId: uuid)
                    } else {
                        Text("Invalid questionnaire ID")
                    }
                default:
                    Text("Unknown destination")
                }
            }
            .navigationDestination(for: Questionnaire.self) { questionnaire in
                QuestionnaireDetailView(questionnaire: questionnaire)
            }
            .navigationDestination(for: BrowseQuestionnaire.self) { template in
                BrowseDetailView(template: template)
            }
            .navigationDestination(for: Overlap.self) { overlap in
                QuestionnaireView(overlap: overlap)
            }
            .navigationDestination(for: OnlineNavigationDestination.self) {
                destination in
                switch destination {
                case .hostSetup(let questionnaireID):
                    if let questionnaire = loadQuestionnaire(id: questionnaireID) {
                        OnlineSessionSetupView(questionnaire: questionnaire)
                    } else {
                        ContentUnavailableView(
                            "Questionnaire Not Found",
                            systemImage: "exclamationmark.triangle.fill",
                            description: Text(
                                "The selected questionnaire could not be loaded."
                            )
                        )
                    }
                case .joinSession(let prefilledInvite):
                    JoinOnlineSessionView(prefilledInvite: prefilledInvite)
                }
            }
        }
        .environment(\.navigationPath, $path)
        .task {
            syncSessionObservers()
            applyHostedSnapshotsToLocalOverlaps()
        }
        .onChange(of: trackedOnlineSessionIDs) { _, _ in
            syncSessionObservers()
            applyHostedSnapshotsToLocalOverlaps()
        }
        .onReceive(onlineSessionService.$sessionsByID) { _ in
            applyHostedSnapshotsToLocalOverlaps()
        }
        .onOpenURL { url in
            guard let invite = onlineSessionService.parseInvite(from: url) else {
                return
            }

            navigate(
                to: .joinSession(prefilledInvite: invite),
                using: $path
            )
        }
    }

    private func loadQuestionnaire(id: UUID) -> Questionnaire? {
        let descriptor = FetchDescriptor<Questionnaire>(
            predicate: #Predicate<Questionnaire> { questionnaire in
                questionnaire.id == id
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func syncSessionObservers() {
        let desired = trackedOnlineSessionIDs
        let toStart = desired.subtracting(observedOnlineSessionIDs)
        let toStop = observedOnlineSessionIDs.subtracting(desired)

        for sessionID in toStart {
            onlineSessionService.startSessionObservation(sessionID: sessionID)
        }
        for sessionID in toStop {
            onlineSessionService.stopSessionObservation(sessionID: sessionID)
        }

        observedOnlineSessionIDs = desired
    }

    private func applyHostedSnapshotsToLocalOverlaps() {
        guard !onlineOverlaps.isEmpty else { return }

        var didApply = false
        for overlap in onlineOverlaps {
            guard let sessionID = overlap.onlineSessionID,
                  let hostedSession = onlineSessionService.hostedSession(id: sessionID)
            else { continue }
            _ = OnlineSessionSnapshotApplier.apply(session: hostedSession, to: overlap)
            didApply = true
        }

        guard didApply else { return }
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .environmentObject(OnlineSubscriptionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
        .environmentObject(OnlineSessionService.shared)
}

#Preview("With Model Data") {
    HomeView()
        .environmentObject(OnlineSubscriptionService.shared)
        .environmentObject(OnlineHostAuthService.shared)
        .environmentObject(OnlineSessionService.shared)
        .modelContainer(previewModelContainer)
}
