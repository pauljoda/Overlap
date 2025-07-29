//
//  Overlap.swift
//  Overlap
//
//  Created by Paul Davis on 7/29/25.
//

import SwiftData
import Foundation

@Model
class Overlap {
    var id = UUID()
    var beginData: Date = Date.now
    var completeDate: Date?
    var questionnaire: Questionnaire
    var answers: [Answer] = []
    var participants: [String] = []
    var isOnline: Bool = false

    init(id: UUID = UUID(), beginData: Date = Date.now, completeDate: Date? = nil, questionnaire: Questionnaire = Questionnaire(), answers: [Answer] = [], participants: [String] = [], isOnline: Bool = false) {
        self.id = id
        self.beginData = beginData
        self.completeDate = completeDate
        self.questionnaire = questionnaire
        self.answers = answers
        self.participants = participants
        self.isOnline = isOnline
    }
}
