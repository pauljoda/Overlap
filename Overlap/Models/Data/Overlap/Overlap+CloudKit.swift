//
//  Overlap+CloudKit.swift
//  Overlap
//
//  Simple CloudKit sync extensions for Overlap model
//  Based on: https://yingjiezhao.com/en/articles/Implementing-iCloud-Sync-by-Combining-SwiftData-with-CKSyncEngine/
//

import Foundation
import CloudKit
import SwiftData

extension Overlap: CloudKitSyncable {
    
    // MARK: - Record Conversion
    
    /// Populate a CloudKit record with data from this Overlap
    func populateRecord(_ record: CKRecord) {
        if let lastRecord = lastKnownRecord {
            // Preserve change tag from last known record
            // Note: recordChangeTag is read-only, so we work with the existing record structure
        }
        
        // Basic session information
        record["title"] = title
        record["information"] = information
        record["instructions"] = instructions
        record["questions"] = questions
        record["participants"] = participants
        record["beginDate"] = beginDate
        record["completeDate"] = completeDate
        record["isCompleted"] = isCompleted
        record["isOnline"] = isOnline
        record["iconEmoji"] = iconEmoji
        
        // Convert participant responses to JSON for CloudKit storage
        if let responseData = try? JSONEncoder().encode(participantResponses) {
            record["participantResponsesData"] = responseData
        }
        
        // Session state
        record["currentStateRaw"] = currentState.rawValue
        record["currentParticipantIndex"] = currentParticipantIndex
        record["currentQuestionIndex"] = currentQuestionIndex
        
        // Randomization
        record["isRandomized"] = isRandomized
        if let orderData = try? JSONEncoder().encode(participantQuestionOrders) {
            record["participantQuestionOrdersData"] = orderData
        }
        
        // Color components
        record["startColorRed"] = startColorRed
        record["startColorGreen"] = startColorGreen
        record["startColorBlue"] = startColorBlue
        record["startColorAlpha"] = startColorAlpha
        record["endColorRed"] = endColorRed
        record["endColorGreen"] = endColorGreen
        record["endColorBlue"] = endColorBlue
        record["endColorAlpha"] = endColorAlpha
    }
    
    /// Update this Overlap from a CloudKit record
    func mergeFromServerRecord(_ record: CKRecord) {
        // Update basic session information
        if let title = record["title"] as? String {
            self.title = title
        }
        
        if let information = record["information"] as? String {
            self.information = information
        }
        
        if let instructions = record["instructions"] as? String {
            self.instructions = instructions
        }
        
        if let questions = record["questions"] as? [String] {
            self.questions = questions
        }
        
        if let participants = record["participants"] as? [String] {
            self.participants = participants
        }
        
        if let beginDate = record["beginDate"] as? Date {
            self.beginDate = beginDate
        }
        
        if let completeDate = record["completeDate"] as? Date {
            self.completeDate = completeDate
        }
        
        if let isCompleted = record["isCompleted"] as? Bool {
            self.isCompleted = isCompleted
        }
        
        if let isOnline = record["isOnline"] as? Bool {
            self.isOnline = isOnline
        }
        
        if let iconEmoji = record["iconEmoji"] as? String {
            self.iconEmoji = iconEmoji
        }
        
        // Update participant responses from JSON data
        if let responseData = record["participantResponsesData"] as? Data,
           let responses = try? JSONDecoder().decode([String: [Answer?]].self, from: responseData) {
            self.participantResponses = responses
        }
        
        // Update session state
        if let currentStateRaw = record["currentStateRaw"] as? String,
           let state = OverlapState(rawValue: currentStateRaw) {
            self.currentState = state
        }
        
        if let currentParticipantIndex = record["currentParticipantIndex"] as? Int {
            self.currentParticipantIndex = currentParticipantIndex
        }
        
        if let currentQuestionIndex = record["currentQuestionIndex"] as? Int {
            self.currentQuestionIndex = currentQuestionIndex
        }
        
        // Update randomization
        if let isRandomized = record["isRandomized"] as? Bool {
            self.isRandomized = isRandomized
        }
        
        if let orderData = record["participantQuestionOrdersData"] as? Data,
           let orders = try? JSONDecoder().decode([String: [Int]].self, from: orderData) {
            self.participantQuestionOrders = orders
        }
        
        // Update color components
        if let startColorRed = record["startColorRed"] as? Double {
            self.startColorRed = startColorRed
        }
        if let startColorGreen = record["startColorGreen"] as? Double {
            self.startColorGreen = startColorGreen
        }
        if let startColorBlue = record["startColorBlue"] as? Double {
            self.startColorBlue = startColorBlue
        }
        if let startColorAlpha = record["startColorAlpha"] as? Double {
            self.startColorAlpha = startColorAlpha
        }
        if let endColorRed = record["endColorRed"] as? Double {
            self.endColorRed = endColorRed
        }
        if let endColorGreen = record["endColorGreen"] as? Double {
            self.endColorGreen = endColorGreen
        }
        if let endColorBlue = record["endColorBlue"] as? Double {
            self.endColorBlue = endColorBlue
        }
        if let endColorAlpha = record["endColorAlpha"] as? Double {
            self.endColorAlpha = endColorAlpha
        }
        
        // Store the record for future conflict resolution
        lastKnownRecord = record
    }
}