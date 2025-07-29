//
//  Answer.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftData

enum AnswerType: String, Codable, CaseIterable, Hashable {
    case yes = "Yes"
    case no = "No"
    case maybe = "Maybe"
}

struct Answer: Codable {
    var type: AnswerType = AnswerType.no
    var text: String = "No"
    
    init(type: AnswerType, text: String) {
        self.type = type
        self.text = text
    }
}
