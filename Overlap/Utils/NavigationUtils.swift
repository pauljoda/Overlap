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
    case browse
    case settings
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
    case .browse:
        navigationPath.wrappedValue.append("browse")
    case .settings:
        navigationPath.wrappedValue.append("settings")
    case .edit(let questionnaireId):
        navigationPath.wrappedValue.append("edit-\(questionnaireId.uuidString)")
    }
}

func navigate(
    to questionnaire: Questionnaire,
    using navigationPath: Binding<NavigationPath>,
    replaceCurrent: Bool = false
) {
    // When replacing, remove the current top entry so the push effectively replaces it
    if replaceCurrent, navigationPath.wrappedValue.count > 0 {
        navigationPath.wrappedValue.removeLast()
    }
    navigationPath.wrappedValue.append(questionnaire)
}

func navigate(
    to overlap: Overlap,
    using navigationPath: Binding<NavigationPath>,
    replaceCurrent: Bool = false
) {
    if replaceCurrent, navigationPath.wrappedValue.count > 0 {
        navigationPath.wrappedValue.removeLast()
    }
    navigationPath.wrappedValue.append(overlap)
}
