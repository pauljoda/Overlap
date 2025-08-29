//
//  Overlap+Debug.swift
//  Overlap
//
//  Debug utilities
//

import Foundation

extension Overlap {
    /// Debug helper: Print question orders for all participants (useful for testing randomization)
    func printQuestionOrders() {
        print("=== Question Orders ===")
        print("Randomization enabled: \(isRandomized)")
        for participant in participants {
            print("\n\(participant):")
            if let order = getQuestionOrder(for: participant) {
                for (index, question) in order.enumerated() {
                    let originalIndex = getOriginalQuestionIndex(for: participant, displayIndex: index) ?? -1
                    print("  \(index + 1). [Original #\(originalIndex + 1)] \(question)")
                }
            }
        }
        print("=====================")
    }
}

