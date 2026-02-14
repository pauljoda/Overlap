//
//  BrowseCatalogService.swift
//  Overlap
//
//  Fetches and decodes the browse questionnaire catalog.
//

import Foundation
import Combine

@MainActor
final class BrowseCatalogService: ObservableObject {
    static let shared = BrowseCatalogService()

    @Published private(set) var questionnaires: [BrowseQuestionnaire] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func fetchCatalog() async {
        guard questionnaires.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        if let bundled = loadBundledCatalog() {
            questionnaires = bundled.questionnaires
            return
        }

        errorMessage = "Could not load the browse catalog."
    }

    func refreshCatalog() async {
        questionnaires = []
        errorMessage = nil
        await fetchCatalog()
    }

    private func loadBundledCatalog() -> BrowseCatalog? {
        guard let url = Bundle.main.url(forResource: "browse-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(BrowseCatalog.self, from: data)
    }
}
