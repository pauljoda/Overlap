//
//  BrowseQuestionnaire.swift
//  Overlap
//
//  Codable model for pre-built questionnaire templates in the browse catalog.
//

import Foundation

struct BrowseQuestionnaire: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var information: String
    var instructions: String
    var author: String
    var questions: [String]
    var iconEmoji: String
    var startColorHex: String
    var endColorHex: String
    var category: String
}

struct BrowseCatalog: Codable {
    var version: Int
    var questionnaires: [BrowseQuestionnaire]
}
