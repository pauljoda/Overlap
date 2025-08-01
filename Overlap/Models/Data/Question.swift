//
//  Question.swift
//  Overlap
//
//  Created by Paul Davis on 7/26/25.
//

import Foundation
import SwiftData

struct Question: Codable {
    var id = UUID()
    var text: String
    var orderIndex: Int
    
    init(id: UUID = UUID(), text: String = "", orderIndex: Int = 0) {
        self.id = id
        self.text = text
        self.orderIndex = orderIndex
    }
}
