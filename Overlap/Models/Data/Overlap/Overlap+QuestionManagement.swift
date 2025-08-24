//
//  Overlap+QuestionManagement.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation

// MARK: - Question Management
extension Overlap {
    
    /// Gets a question by its index in the original questionnaire
    ///
    /// - Parameter index: Index of the question
    /// - Returns: Question text if found, nil otherwise
    func getQuestion(at index: Int) -> String? {
        guard index < questions.count else { return nil }
        return questions[index]
    }

    /// Gets the index of a question by its text
    ///
    /// - Parameter question: The question text to find
    /// - Returns: Index of the question if found, nil otherwise
    func getQuestionIndex(for question: String) -> Int? {
        return questions.firstIndex(of: question)
    }
}
