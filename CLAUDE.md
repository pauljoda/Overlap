# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Overlap is a SwiftUI iOS application that allows users to create questionnaires and discover where their opinions overlap with others. The app uses GRDB.swift with the SharingGRDB framework for local database management and CloudKit syncing capabilities.

## Build Commands

This is an Xcode project. Use standard Xcode commands:

- **Build**: ⌘+B or `xcodebuild build -project Overlap.xcodeproj -scheme Overlap`
- **Run**: ⌘+R or build and run from Xcode
- **Test**: ⌘+U or `xcodebuild test -project Overlap.xcodeproj -scheme Overlap`
- **Clean**: Shift+⌘+K or `xcodebuild clean -project Overlap.xcodeproj -scheme Overlap`

The project uses Swift Package Manager dependencies, managed through Xcode's integrated package manager.

## Architecture

### Database Layer (GRDB + SharingGRDB)
- **DatabaseWriter.swift**: Core database configuration using GRDB.swift and SharingGRDB
- Uses file-based SQLite database in live mode, in-memory for previews, temp files for testing
- Two main tables: `questionnaires` and `overlaps` 
- Database migrations handled via `DatabaseMigrator`
- Context-aware setup (live, test, preview environments)

### Data Models
- **Questionnaire**: Core model for questionnaire templates using `@Table` decorator
- **Overlap**: Represents active questionnaire sessions with participant responses
- **Answer**: Response data structure
- Models use SharingGRDB's `@Table` and `@Column` decorators for database mapping

### UI Architecture
- **SwiftUI-based** with NavigationStack for routing
- **Token-based design system** in `DesignTokens.swift` with standardized spacing, colors, typography, shadows
- **Glass effect styling** throughout the UI using iOS glass effects
- **Modular component structure** with reusable components in `Views/Components/`

### Navigation
- Uses NavigationStack with string-based routing for main flows
- Environment-injected navigation path binding for deep linking
- Type-safe navigation for model objects (Questionnaire, Overlap)

### Key Architectural Patterns
- **Dependency injection** using `@Dependency` from swift-dependencies
- **Preview data setup** with `prepareDependencies` helper
- **Environment-based configuration** (live, test, preview contexts)
- **Design token system** for consistent styling across components

### Main View Hierarchy
```
HomeView (entry point)
├── Create/CreateQuestionnaireView
├── Saved/SavedView 
├── InProgress/InProgressView
├── Completed/CompletedView
└── Questionnaire/QuestionnaireView (main questionnaire flow)
    ├── QuestionnaireDetailView
    ├── QuestionnaireInstructionsView
    ├── QuestionnaireNextParticipantView
    ├── QuestionnaireAnsweringView
    ├── QuestionnaireAwaitingResponsesView
    └── QuestionnaireCompleteView
```

### Dependencies
Key Swift packages used:
- **SharingGRDB**: Database management with CloudKit sync (currently on cloudkit branch)
- **GRDB.swift**: SQLite wrapper and query interface
- **Swift Dependencies**: Dependency injection framework
- **Swift Collections, Concurrency Extras, Custom Dump**: Point-Free utility libraries

### Design System
- Centralized design tokens in `DesignTokens.swift`
- Glass effect styling with `.standardGlassCard()`, `.heroGlassCard()`, etc.
- Consistent spacing, typography, and shadow system
- Blob background animations for visual interest

### Current Development Context
- Recently migrated from SwiftData to GRDB/SharingGRDB
- On branch `sharing-grdb` (main branch is `main`)
- Database schema established for questionnaires and overlaps tables
- Active development of questionnaire creation and response collection flows