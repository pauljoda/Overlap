# Overlap

## Project Overview

Overlap is an iOS SwiftUI app for running "overlap" questionnaires in local and online collaboration modes. Users create questionnaires, invite participants (locally via pass-the-phone or online via Firebase-backed invite links), and compare answers to see where opinions overlap.

## Tech Stack

- Language: Swift
- Framework: SwiftUI (iOS 26+, Liquid Glass design language)
- Runtime: iOS app target via Xcode
- Data: SwiftData (local persistence) and Firebase Firestore (hosted online sessions)
- Auth: Firebase Auth with Apple Sign In
- AI: Apple Foundation Models (on-device structured generation with `@Generable`)
- Payments: StoreKit 2 (subscription-gated online hosting)
- Tooling: Xcode, xcodebuild, Swift Package Manager
- Testing: XCTest (when tests are present)

## Core Features

- Questionnaire authoring, editing, and local session play — with optional AI-assisted creation via Apple Foundation Models.
- AI Assist: On-device structured generation of questionnaire titles, descriptions, instructions, and questions with streaming UI.
- Import/Export: Share questionnaires as `.overlap` files (JSON) via system share sheet; import from Files or other apps with automatic library integration.
- In-progress and completed overlap session tracking.
- Online hosting with Firebase Firestore: real-time session sync, invite links, host management.
- StoreKit 2 subscription gating for online hosting access.
- Settings with display name, favorite participant groups, subscription status, and app version.
- Browse directory of pre-built questionnaire templates (fetched from `browse-catalog.json`).
- Visual system with glass morphism components, design tokens, and blob background animations.

## Current Version

- **Marketing Version**: 1.3.0
- **Build Number**: 4
- Version is set in `Overlap.xcodeproj/project.pbxproj` (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`).
- Version is displayed to users in Settings → About section (reads from `CFBundleShortVersionString` and `CFBundleVersion`).

## Development Commands

```bash
# List targets/schemes
xcodebuild -list -project /Users/pauldavis/Dev/Overlap/Overlap.xcodeproj

# Build iOS target (generic destination)
xcodebuild -project /Users/pauldavis/Dev/Overlap/Overlap.xcodeproj -scheme Overlap -configuration Debug -destination "generic/platform=iOS" build

# Build simulator target (if simulator services are available)
xcodebuild -project /Users/pauldavis/Dev/Overlap/Overlap.xcodeproj -scheme Overlap -configuration Debug -destination "generic/platform=iOS Simulator" build
```

## Project Structure

```text
/Users/pauldavis/Dev/Overlap
|- Overlap/                    # App source
|  |- Design/                  # DesignTokens.swift (Tokens namespace)
|  |- Models/                  # BrowseQuestionnaire, Data/ (Questionnaire, Overlap, FavoriteGroup, QuestionnaireTransferData)
|  |- Services/                # AIGenerationService, BrowseCatalogService, Online/ (Session, Auth, Subscription, Snapshot, Identity, Firebase)
|  |- Utils/                   # NavigationUtils, ColorHex
|  |- Views/                   # All UI views organized by feature
|     |- Browse/               # BrowseView, Components/BrowseQuestionnaireCard
|     |- Completed/            # CompletedView, Components/
|     |- Components/           # Shared: GlassScreen, GlassActionButton, BlobBackground, HomeMenuOptions, etc.
|     |- Create/               # CreateQuestionnaireView (design gold standard), Components/ (AIAssistFlyout, AIGeneratingView, QuestionEditor, etc.)
|     |- InProgress/           # InProgressView, Components/
|     |- Online/               # OnlineSessionSetupView, JoinOnlineSessionView, Components/ (SubscriptionFlyout, InviteCodeCard, OnlineHostManagementSheet)
|     |- Questionnaire/        # QuestionnaireView (state router), Answering/, AwaitingResponses/, Complete/, Instructions/, Participant/
|     |- Saved/                # SavedView
|     |- Settings/             # SettingsView, Components/ (FavoriteGroupEditor, DisplayNameSection)
|  |- browse-catalog.json      # Pre-built questionnaire template catalog
|- Overlap.xcodeproj/          # Xcode project and scheme metadata
|- .github/instructions/       # Workspace guidance/instructions
|- AGENTS.md                   # This workflow file
|- CHANGELOG.md                # Versioned release notes
|- .gitignore                  # Secrets, keys, build artifacts
```

## Development Guidelines

### Code Quality

- Keep feature changes scoped and avoid broad refactors unless requested.
- Preserve existing SwiftUI patterns and tokenized design style.
- Prefer deterministic data migrations and explicit state transitions.
- Use the Create Questionnaire view (`CreateQuestionnaireView.swift`) as the design gold standard for new screens.

### Design System

- Glass morphism via `standardGlassCard()`, `largeGlassCard()`, `heroGlassCard()` modifiers in `DesignTokens.swift`.
- All screens use `GlassScreen` container with blob background.
- Tokens: `Tokens.Spacing`, `Tokens.Radius`, `Tokens.Size`, `Tokens.Shadow`, `Tokens.Duration`, `Tokens.Spring`.
- Headers: centered icon (system size `Tokens.Size.iconLarge`) + `.title2.bold` title + `.subheadline.secondary` subtitle.
- Form sections: `SectionHeader(title:icon:)` + fields wrapped in `standardGlassCard()`.
- Primary actions: `GlassActionButton` floating at bottom via ZStack overlay.
- Sheets: `.presentationBackground(.ultraThinMaterial)` for Liquid Glass consistency.

### Testing Requirements

- Add/update tests for behavior changes where test targets exist.
- For UI/state-heavy changes, include at least one reproducible manual test path in change notes.
- Run build checks before finalizing changes when environment permissions allow.

### Security and Compliance

- Do not commit secrets, tokens, or provisioning artifacts.
- Keep invite/auth/subscription logic behind explicit service boundaries.
- Validate input at view/service boundaries (invite codes, deep links, profile fields).

## Semantic Versioning + Changelog

- Use semantic versioning (`MAJOR.MINOR.PATCH`) for release tagging.
- Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj` (both Debug and Release configurations).
- Record meaningful changes in `CHANGELOG.md` organized by version with Added/Changed/Removed sections.
- Tag releases with `git tag v{VERSION}` after merging to main.

## Agent Workflow Rules

This is a living file and must stay current.

Required steps before finishing implementation work:
1. Add/update changelog notes for meaningful behavior changes.
2. Update this `AGENTS.md` when architecture, workflows, or commands change.
3. Follow semantic versioning, update the versioning for the app itself, and the changelog entries to updated based on the work done.
4. Create a detailed git commit message and commit all changes to the tree when done.

## Branch Strategy

- `main`: Stable release branch.
- `codex/<feature-name>`: Feature development branches (merged to main when complete).
