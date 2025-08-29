//
//  GRDBPreviewData.swift
//  Overlap
//
//  SharingGRDB preview setup
//
//  Provides preview data setup for SharingGRDB-based views.
//

import Foundation
import SwiftUI
import SharingGRDB

/// Preview setup for SharingGRDB
struct GRDBPreviewData {
    
    /// Sets up SharingGRDB for previews with comprehensive sample data
    @MainActor
    static func setup() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try SampleData.setupComprehensivePreviewDatabase()
        } catch {
            print("Failed to setup GRDB preview: \(error)")
        }
    }
    
    /// Sets up minimal preview data for simple test cases
    @MainActor
    static func setupMinimal() {
        do {
            let _ = try prepareDependencies {
                $0.defaultDatabase = try appDatabase()
            }
            try SampleData.setupMinimalPreviewDatabase()
        } catch {
            print("Failed to setup minimal GRDB preview: \(error)")
        }
    }
}

/// Convenience function for use in previews - sets up comprehensive data
@MainActor
func setupGRDBPreview() {
    GRDBPreviewData.setup()
}

/// Convenience function for use in previews - sets up minimal data for simple cases
@MainActor
func setupMinimalGRDBPreview() {
    GRDBPreviewData.setupMinimal()
}
