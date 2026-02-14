//
//  FavoriteGroup.swift
//  Overlap
//
//  Reusable participant name group for quick local overlap setup.
//

import Foundation
import SwiftData

@Model
class FavoriteGroup {
    var id = UUID()
    var name: String = ""
    var participants: [String] = []
    var createdAt: Date = Date.now

    init(name: String, participants: [String] = []) {
        self.name = name
        self.participants = participants
    }
}
