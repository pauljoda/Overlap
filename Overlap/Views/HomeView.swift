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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.onlineSessionService) private var onlineSessionService
    @State private var syncManager: OverlapSyncManager?
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var showingDisplayNameSetup = false
    
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
                    ComingSoonView(title: "Browse")
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
        .environment(\.overlapSyncManager, syncManager)
        .sheet(isPresented: $showingDisplayNameSetup) {
            NavigationView {
                DisplayNameSetupView()
            }
        }
        .onAppear {
            // Initialize sync manager when we have model context
            if syncManager == nil {
                syncManager = OverlapSyncManager(modelContext: modelContext)
            }
            
            if userPreferences.needsDisplayNameSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingDisplayNameSetup = true
                }
            }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToOverlap"))) { notification in
            if let overlap = notification.object as? Overlap {
                // Navigate to the overlap when opened from a share link
                navigate(to: overlap, using: $path)
            }
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
}

#Preview {
    HomeView()
}

#Preview("With Model Data") {
    HomeView()
        .modelContainer(previewModelContainer)
}
