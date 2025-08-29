# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

Overlap is a SwiftUI iOS application that allows users to create questionnaires and discover where their opinions overlap with others. The app uses GRDB.swift for local database management and is designed to be synced with CloudKit. The project is built using Xcode and relies on Swift Package Manager for dependencies.

**Important Note:** This application targets iOS 26, which is a future version of iOS. This means that UI elements like "Liquid Glass" and "glass effect" are part of Apple's new native design language for that version of the OS. Any unknown references to UI components are likely attributable to this upcoming update.

## Building and Running

This is an Xcode project. Use standard Xcode commands:

- **Build**: ⌘+B or `xcodebuild build -project Overlap.xcodeproj -scheme Overlap`
- **Run**: ⌘+R or build and run from Xcode
- **Test**: ⌘+U or `xcodebuild test -project Overlap.xcodeproj -scheme Overlap`
- **Clean**: Shift+⌘+K or `xcodebuild clean -project Overlap.xcodeproj -scheme Overlap`

The project uses Swift Package Manager dependencies, which are managed through Xcode's integrated package manager.

## Development Conventions

### Architecture

- **UI:** The application is built with SwiftUI, using a `NavigationStack` for routing. The UI is styled using a token-based design system defined in `DesignTokens.swift`, which includes standardized spacing, colors, typography, and shadows. A "glass effect" styling is used throughout the UI, which is a native component of iOS 26.
- **Database:** The app uses GRDB.swift for the local database, with `DatabaseWriter.swift` as the core configuration. It uses a file-based SQLite database in the live app, and an in-memory database for previews and testing. The database has two main tables: `questionnaires` and `overlaps`.
- **Data Models:** The data models (`Questionnaire`, `Overlap`, `Answer`) use SharingGRDB's `@Table` and `@Column` decorators for database mapping.
- **Dependency Injection:** The project uses `@Dependency` from `swift-dependencies` for dependency injection.
- **View Hierarchy:** The main view hierarchy starts with `HomeView` and branches out to different sections of the app, such as creating, viewing, and managing questionnaires.

### Key Files

- `Overlap/OverlapApp.swift`: The main entry point of the application.
- `Overlap.xcodeproj/project.pbxproj`: The Xcode project file, which defines the project structure, build settings, and dependencies.
- `Overlap/Data/DatabaseWriter.swift`: The core database configuration using GRDB.swift.
- `Overlap/Design/DesignTokens.swift`: The design system with standardized spacing, colors, typography, and shadows.
- `Overlap/Views/HomeView.swift`: The entry point of the UI.

### Dependencies

Key Swift packages used:
- **SharingGRDB**: For database management and CloudKit sync.
- **GRDB.swift**: A SQLite wrapper and query interface.
- **Swift Dependencies**: A dependency injection framework.
- **Swift Collections, Concurrency Extras, Custom Dump**: Utility libraries from Point-Free.
