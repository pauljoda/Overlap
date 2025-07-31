//
//  Response.swift
//  Overlap
//
//  Created by Paul Davis on 7/30/25.
//
import Foundation

struct Responses: Codable {
    // User that usbmitted responses
    var user: String
    // Answers with question ID mapped to the response
    var answers: [UUID: Answer]
    
    init(user: String, answers: [UUID: Answer]) {
        self.user = user
        self.answers = answers
    }
}
