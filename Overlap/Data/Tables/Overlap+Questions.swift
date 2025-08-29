//
//  Overlap+Questions.swift
//  Overlap
//
//  Question lookup helpers
//

import Foundation

extension Overlap {
    /// Gets a question by its index in the original questionnaire
    func getQuestion(at index: Int) -> String? {
        guard index < questions.count else { return nil }
        return questions[index]
    }

    /// Gets the index of a question by its text
    func getQuestionIndex(for question: String) -> Int? {
        return questions.firstIndex(of: question)
    }
}

