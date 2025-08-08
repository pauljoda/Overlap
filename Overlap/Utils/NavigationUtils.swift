//
//  NavigationUtils.swift
//  Overlap
//
//  Centralized navigation utilities and destination types
//

import SwiftUI
import Foundation

enum NavigationDestination {
    case create
    case saved
    case inProgress
    case completed
    case join
    case browse
    case edit(questionnaireId: UUID)
}

func navigate(to destination: NavigationDestination, using navigationPath: Binding<NavigationPath>) {
    switch destination {
    case .create:
        navigationPath.wrappedValue.append("create")
    case .saved:
        navigationPath.wrappedValue.append("saved")
    case .inProgress:
        navigationPath.wrappedValue.append("in-progress")
    case .completed:
        navigationPath.wrappedValue.append("completed")
    case .join:
        navigationPath.wrappedValue.append("join")
    case .browse:
        navigationPath.wrappedValue.append("browse")
    case .edit(let questionnaireId):
        navigationPath.wrappedValue.append("edit-\(questionnaireId.uuidString)")
    }
}

func navigate(to questionnaire: Questionnaire, using navigationPath: Binding<NavigationPath>) {
    navigationPath.wrappedValue.append(questionnaire)
}

func navigate(to overlap: Overlap, using navigationPath: Binding<NavigationPath>) {
    navigationPath.wrappedValue.append(overlap)
}
