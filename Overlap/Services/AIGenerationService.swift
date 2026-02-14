//
//  AIGenerationService.swift
//  Overlap
//
//  On-device AI questionnaire generation using Apple Foundation Models.
//

#if canImport(FoundationModels)
import FoundationModels
import Foundation
import Observation

// MARK: - Generable Output

@Generable
struct GeneratedQuestionnaire {
    @Guide(description: "A short, catchy title for the questionnaire (2-6 words)")
    var title: String

    @Guide(description: "A brief 1-2 sentence description of what this questionnaire is about and its purpose")
    var information: String

    @Guide(description: "Clear instructions for participants on how to answer the questions, including any rules or guidelines")
    var instructions: String

    @Guide(description: "The list of questions for participants to answer", .maximumCount(20))
    var questions: [String]
}

// MARK: - Length Configuration

enum QuestionnaireLength: String, CaseIterable, Identifiable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"

    var id: String { rawValue }

    var questionRange: String {
        switch self {
        case .short: return "3 to 5"
        case .medium: return "6 to 10"
        case .long: return "11 to 15"
        }
    }

    var targetCount: Int {
        switch self {
        case .short: return 4
        case .medium: return 8
        case .long: return 13
        }
    }
}

// MARK: - Generation State

enum AIGenerationState: Equatable {
    case idle
    case generating
    case completed
    case failed(String)

    static func == (lhs: AIGenerationState, rhs: AIGenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.generating, .generating), (.completed, .completed):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Service

@Observable
@MainActor
final class AIGenerationService {
    private(set) var state: AIGenerationState = .idle
    private(set) var partialResult: GeneratedQuestionnaire.PartiallyGenerated?
    private(set) var completedResult: GeneratedQuestionnaire?

    private var session: LanguageModelSession?

    /// Whether the device supports on-device Foundation Models.
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    var unavailabilityReason: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    func prewarm() {
        guard isAvailable else { return }
        if session == nil {
            session = makeSession()
        }
    }

    func generate(prompt: String, length: QuestionnaireLength) async {
        state = .generating
        partialResult = nil
        completedResult = nil

        // Create a fresh session per generation to avoid context buildup
        let generationSession = makeSession()

        let fullPrompt = """
        Create a questionnaire based on this description: \(prompt)

        Generate exactly \(length.targetCount) questions (between \(length.questionRange) questions).
        
        The questions should be questions that will be answered with "Yes, No, or Maybe".
        
        Prefer giving options for categories, and overall topics, not open ended questions. 
        
        The purpose of this list is to have a group answer yes, no, or maybe, then compare results.
        """

        do {
            let stream = generationSession.streamResponse(
                to: fullPrompt,
                generating: GeneratedQuestionnaire.self
            )

            for try await partial in stream {
                self.partialResult = partial.content
            }

            // Stream completed — extract the final result from the last partial
            if let final = partialResult,
               let title = final.title,
               let information = final.information,
               let instructions = final.instructions,
               let questions = final.questions {
                let result = GeneratedQuestionnaire(
                    title: title,
                    information: information,
                    instructions: instructions,
                    questions: questions.compactMap { $0 }
                )
                self.completedResult = result
                self.state = .completed
            } else {
                self.state = .failed("Generation completed but result was incomplete. Please try again.")
            }
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation:
                self.state = .failed("The request was flagged by content safety. Try rephrasing your description.")
            case .exceededContextWindowSize:
                self.state = .failed("The description was too long. Try a shorter prompt.")
            default:
                self.state = .failed("Generation failed: \(error.localizedDescription)")
            }
        } catch {
            self.state = .failed("Something went wrong: \(error.localizedDescription)")
        }
    }

    func reset() {
        state = .idle
        partialResult = nil
        completedResult = nil
    }

    // MARK: - Private

    private func makeSession() -> LanguageModelSession {
        LanguageModelSession(
            instructions: """
            You are a questionnaire design assistant for the Overlap app. \
            Overlap is an app where groups of people answer the same questions \
            and then compare their answers to find where opinions overlap.

            When creating questionnaires:
            - Write questions that are fun, thought-provoking, and encourage discussion
            - Questions should be open-ended or opinion-based (not factual trivia)
            - Each question should stand on its own
            - Vary question types: preferences, hypotheticals, rankings, and experiences
            - Keep questions concise but clear
            - The title should be catchy and descriptive
            - The description should explain the purpose of the questionnaire
            - Instructions should tell participants how to approach answering
            """
        )
    }
}
#endif
