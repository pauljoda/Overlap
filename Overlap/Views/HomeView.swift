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
    @State private var syncManager: OverlapSyncManager?
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var cloudKitService = CloudKitService()
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
                case "join":
                    JoinOverlapView()
                case "browse":
                    ComingSoonView(title: "Browse")
                case "cloudkit-demo":
                    CloudKitDemoView()
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
        }
        .environment(\.navigationPath, $path)
        .environment(\.overlapSyncManager, syncManager)
        .sheet(isPresented: $showingDisplayNameSetup) {
            NavigationView {
                DisplayNameSetupView(cloudKitService: cloudKitService)
            }
        }
        .onAppear {
            // Initialize sync manager when we have model context
            if syncManager == nil {
                syncManager = OverlapSyncManager(modelContext: modelContext)
            }
            
            // Check if we need to prompt for display name setup
            // Only prompt if CloudKit is available and user hasn't set up their name
            Task {
                await cloudKitService.checkAccountStatus()
                
                if cloudKitService.isAvailable && userPreferences.needsDisplayNameSetup {
                    // Delay showing the sheet to avoid SwiftUI conflicts with onAppear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingDisplayNameSetup = true
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

#Preview("With Model Data") {
    HomeView()
        .modelContainer(previewModelContainer)
}
