//
//  BrowseView.swift
//  Overlap
//
//  Browse directory of pre-built questionnaire templates.
//

import SwiftUI
import SwiftData

struct BrowseView: View {
    @StateObject private var catalogService = BrowseCatalogService.shared

    private var categories: [String] {
        var seen = Set<String>()
        return catalogService.questionnaires.compactMap { q in
            guard !seen.contains(q.category) else { return nil }
            seen.insert(q.category)
            return q.category
        }
    }

    var body: some View {
        GlassScreen {
            VStack(spacing: Tokens.Spacing.xxl) {
                header

                if catalogService.isLoading {
                    ProgressView()
                        .padding(.vertical, Tokens.Spacing.quadXL)
                } else if let error = catalogService.errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load Templates",
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(error)
                    )
                } else {
                    ForEach(categories, id: \.self) { category in
                        VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                            SectionHeader(
                                title: category,
                                icon: iconForCategory(category)
                            )

                            ForEach(catalogService.questionnaires.filter { $0.category == category }) { template in
                                NavigationLink(value: template) {
                                    BrowseQuestionnaireRow(template: template)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(Tokens.Spacing.l)
                                        .standardGlassCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer().frame(height: Tokens.Spacing.quadXL)
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.top, Tokens.Spacing.xl)
            .frame(maxWidth: Tokens.Size.maxContentWidth)
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await catalogService.fetchCatalog()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Tokens.Spacing.l) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: Tokens.Size.iconLarge))
                .foregroundColor(.red)

            VStack(spacing: Tokens.Spacing.s) {
                Text("Browse")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Discover pre-built questionnaire templates.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "social": return "person.2.fill"
        case "travel": return "airplane"
        case "entertainment": return "film.fill"
        case "food": return "fork.knife"
        case "work": return "briefcase.fill"
        case "family": return "house.fill"
        case "health": return "heart.fill"
        default: return "folder.fill"
        }
    }
}

#Preview {
    NavigationStack {
        BrowseView()
            .modelContainer(for: Questionnaire.self, inMemory: true)
    }
}
