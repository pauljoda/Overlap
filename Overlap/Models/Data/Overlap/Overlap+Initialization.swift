//
//  Overlap+Initialization.swift
//  Overlap
//
//  Created by Paul Davis on 8/21/25.
//

import Foundation
import SwiftUI

// MARK: - Initialization
extension Overlap {
    
    /// Standard initializer using a Questionnaire object
    convenience init(
        id: UUID = UUID(),
        beginDate: Date = Date.now,
        completeDate: Date? = nil,
        participants: [String] = [],
        isOnline: Bool = false,
        questionnaire: Questionnaire,
        randomizeQuestions: Bool = false,
        currentState: OverlapState = .instructions
    ) {
        self.init(
            id: id,
            beginDate: beginDate,
            completeDate: completeDate,
            participants: participants,
            isOnline: isOnline,
            title: questionnaire.title,
            information: questionnaire.information,
            instructions: questionnaire.instructions,
            questions: questionnaire.questions,
            iconEmoji: questionnaire.iconEmoji,
            startColorRed: questionnaire.startColorRed,
            startColorGreen: questionnaire.startColorGreen,
            startColorBlue: questionnaire.startColorBlue,
            startColorAlpha: questionnaire.startColorAlpha,
            endColorRed: questionnaire.endColorRed,
            endColorGreen: questionnaire.endColorGreen,
            endColorBlue: questionnaire.endColorBlue,
            endColorAlpha: questionnaire.endColorAlpha,
            randomizeQuestions: randomizeQuestions,
            currentState: currentState,
            currentParticipantIndex: 0,
            currentQuestionIndex: 0,
            isCompleted: (currentState == .complete)
        )
    }
    
    /// Convenience initializer for creating an overlap with direct question data
    convenience init(
        id: UUID = UUID(),
        beginDate: Date = Date.now,
        completeDate: Date? = nil,
        participants: [String] = [],
        isOnline: Bool = false,
        title: String,
        information: String = "",
        instructions: String,
        questions: [String],
        iconEmoji: String = "📝",
        startColor: Color = .blue,
        endColor: Color = .purple,
        randomizeQuestions: Bool = false,
        currentState: OverlapState = .instructions
    ) {
        // Extract color components for storage
        var startRed: Double = 0, startGreen: Double = 0, startBlue: Double = 1, startAlpha: Double = 1
        var endRed: Double = 0.5, endGreen: Double = 0, endBlue: Double = 0.5, endAlpha: Double = 1
        
        #if os(iOS)
        let startUIColor = UIColor(startColor)
        var startRedCG: CGFloat = 0, startGreenCG: CGFloat = 0, startBlueCG: CGFloat = 0, startAlphaCG: CGFloat = 0
        startUIColor.getRed(&startRedCG, green: &startGreenCG, blue: &startBlueCG, alpha: &startAlphaCG)
        startRed = Double(startRedCG)
        startGreen = Double(startGreenCG)
        startBlue = Double(startBlueCG)
        startAlpha = Double(startAlphaCG)
        
        let endUIColor = UIColor(endColor)
        var endRedCG: CGFloat = 0, endGreenCG: CGFloat = 0, endBlueCG: CGFloat = 0, endAlphaCG: CGFloat = 0
        endUIColor.getRed(&endRedCG, green: &endGreenCG, blue: &endBlueCG, alpha: &endAlphaCG)
        endRed = Double(endRedCG)
        endGreen = Double(endGreenCG)
        endBlue = Double(endBlueCG)
        endAlpha = Double(endAlphaCG)
        #endif
        
        self.init(
            id: id,
            beginDate: beginDate,
            completeDate: completeDate,
            participants: participants,
            isOnline: isOnline,
            title: title,
            information: information,
            instructions: instructions,
            questions: questions,
            iconEmoji: iconEmoji,
            startColorRed: startRed,
            startColorGreen: startGreen,
            startColorBlue: startBlue,
            startColorAlpha: startAlpha,
            endColorRed: endRed,
            endColorGreen: endGreen,
            endColorBlue: endBlue,
            endColorAlpha: endAlpha,
            randomizeQuestions: randomizeQuestions,
            currentState: currentState,
            currentParticipantIndex: 0,
            currentQuestionIndex: 0,
            isCompleted: (currentState == .complete)
        )
    }
}
