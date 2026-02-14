//
//  QuestionnaireTransferData.swift
//  Overlap
//
//  Lightweight Codable model for import/export of questionnaires as .overlap files.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Custom UTType

extension UTType {
    /// Custom file type for Overlap questionnaire files (.overlap)
    nonisolated static let overlapQuestionnaire = UTType(exportedAs: "com.pauljoda.Overlap.questionnaire")
}

// MARK: - Transfer Data

/// A value-type transfer model that is fully nonisolated so it can satisfy
/// `Sendable`, `Codable`, and `Transferable` requirements without actor conflicts.
nonisolated
struct QuestionnaireTransferData: Codable, Sendable {
    var title: String
    var information: String
    var instructions: String
    var author: String
    var questions: [String]
    var iconEmoji: String

    // Gradient colors stored as RGBA components
    var startColorRed: Double
    var startColorGreen: Double
    var startColorBlue: Double
    var endColorRed: Double
    var endColorGreen: Double
    var endColorBlue: Double

    // MARK: - Init from Questionnaire

    @MainActor
    init(from questionnaire: Questionnaire) {
        self.title = questionnaire.title
        self.information = questionnaire.information
        self.instructions = questionnaire.instructions
        self.author = questionnaire.author
        self.questions = questionnaire.questions
        self.iconEmoji = questionnaire.iconEmoji
        self.startColorRed = questionnaire.startColorRed
        self.startColorGreen = questionnaire.startColorGreen
        self.startColorBlue = questionnaire.startColorBlue
        self.endColorRed = questionnaire.endColorRed
        self.endColorGreen = questionnaire.endColorGreen
        self.endColorBlue = questionnaire.endColorBlue
    }

    // MARK: - Convert to Questionnaire

    @MainActor
    func toQuestionnaire() -> Questionnaire {
        let q = Questionnaire(
            title: title,
            information: information,
            instructions: instructions,
            author: author,
            questions: questions,
            iconEmoji: iconEmoji
        )
        q.startColorRed = startColorRed
        q.startColorGreen = startColorGreen
        q.startColorBlue = startColorBlue
        q.endColorRed = endColorRed
        q.endColorGreen = endColorGreen
        q.endColorBlue = endColorBlue
        return q
    }

    // MARK: - JSON Encoding/Decoding

    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func fromJSON(_ data: Data) throws -> QuestionnaireTransferData {
        let decoder = JSONDecoder()
        return try decoder.decode(QuestionnaireTransferData.self, from: data)
    }
}

// MARK: - Transferable

extension QuestionnaireTransferData: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .overlapQuestionnaire)
        DataRepresentation(exportedContentType: .overlapQuestionnaire) { transferData in
            try transferData.toJSON()
        }
    }
}
