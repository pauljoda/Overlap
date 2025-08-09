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
                    ComingSoonView(title: "Join")
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
        }
        .environment(\.navigationPath, $path)
    }
}

#Preview {
    HomeView()
}

#Preview("With Model Data") {
    HomeView()
        .modelContainer(previewModelContainer)
}
