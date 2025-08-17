//
//  UserPreferences.swift
//  Overlap
//
//  Utility class for managing user preferences and settings via UserDefaults
//

import Foundation
import Combine

@MainActor
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let userDisplayName = "userDisplayName"
        static let isDisplayNameSetup = "isDisplayNameSetup"
    }
    
    // MARK: - Display Name Management
    
    /// Gets the user's display name from UserDefaults
    var userDisplayName: String? {
        get {
            UserDefaults.standard.string(forKey: Keys.userDisplayName)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.userDisplayName)
            objectWillChange.send()
        }
    }
    
    /// Checks if the user has completed display name setup
    var isDisplayNameSetup: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isDisplayNameSetup)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isDisplayNameSetup)
            objectWillChange.send()
        }
    }
    
    /// Sets the user's display name and marks setup as complete
    func setDisplayName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        userDisplayName = trimmedName
        isDisplayNameSetup = true
        
        print("UserPreferences: Set display name: \(trimmedName)")
    }
    
    /// Clears the display name and resets setup status
    func clearDisplayName() {
        userDisplayName = nil
        isDisplayNameSetup = false
        
        print("UserPreferences: Cleared display name")
    }
    
    /// Checks if display name setup is needed
    var needsDisplayNameSetup: Bool {
        return !isDisplayNameSetup || userDisplayName?.isEmpty == true
    }
}
