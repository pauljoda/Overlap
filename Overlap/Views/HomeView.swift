//
//  ContentView.swift
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
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    //App Title
                    VStack(spacing: 10) {
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
                            .frame(maxWidth: 400)
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(30)
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "create":
                    ComingSoonView(title: "Create")
                case "saved":
                    SavedView()
                case "in-progress":
                    ComingSoonView(title: "In-Progress")
                case "completed":
                    ComingSoonView(title: "Completed")
                case "join":
                    ComingSoonView(title: "Join")
                case "browse":
                    ComingSoonView(title: "Browse")
                default:
                    Text("Unknown destination")
                }
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
