# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.3.0] - 2026-02-14

Questionnaire import/export via `.overlap` files, UI polish, and bug fixes.

### Added

- **Questionnaire export**: Share button on questionnaire detail view exports as `.overlap` file (JSON) via system share sheet using `ShareLink` + `Transferable`.
- **Questionnaire import**: Import button on create/edit view reads `.overlap` or `.json` files via system file picker, with confirmation dialog before overwriting current fields.
- **Custom file type**: Registered `com.pauljoda.Overlap.questionnaire` UTType with `.overlap` extension; app opens `.overlap` files from Files or other apps.
- **File open handling**: Tapping a `.overlap` file outside the app imports the questionnaire into the library and navigates to its detail view.
- **`QuestionnaireTransferData`**: Lightweight `Codable` + `Transferable` value type decoupled from SwiftData for safe cross-boundary file serialization.
- **App icon in Settings**: About section now displays the real app icon instead of a generic SF Symbol.
- **`LSSupportsOpeningDocumentsInPlace`**: Info.plist declares in-place document support for proper file handling.

### Changed

- **AI Assist length picker**: Removed card background from segmented picker for cleaner appearance.
- **Version**: Bumped to 1.3.0 (MARKETING_VERSION) / build 4 (CURRENT_PROJECT_VERSION).

### Fixed

- **Online session participant removal**: Removing the second participant from a completed session now correctly transitions back to the awaiting phase instead of showing "No more questions" to the host.

---

## [1.2.0] - 2026-02-14

AI-assisted questionnaire creation using Apple's on-device Foundation Models.

### Added

- **AI Assist in Create flow**: Toolbar button (Apple Intelligence icon) on the Create/Edit Questionnaire screen opens an AI-powered generation sheet.
- **On-device AI generation**: Uses Apple Foundation Models framework with `@Generable` structured output for reliable, typed questionnaire generation — all processing stays on-device.
- **AI Assist flyout sheet**: Three-phase UI (input → generating → results) with prompt field, length picker (Short/Medium/Long), and toggles for title, description, instructions, and replace/append behavior.
- **Streaming generation with animations**: Pulsing Apple Intelligence icon, rotating gradient ring, cycling status messages, and live partial result previews (title and question count) during generation.
- **`AIGenerationService`**: Isolated service wrapping `LanguageModelSession` with structured streaming, error handling (guardrail violations, context limits), and state management.
- **`AIGeneratingView`**: Animated loading component with accessibility support (`reduceMotion` respected).
- **Device availability gating**: AI Assist button only appears on devices that support Foundation Models (`SystemLanguageModel.default.availability`).
- **Flexible result application**: Users choose to generate title/description and instructions independently, and can replace or append to existing questions.

### Changed

- **Version**: Bumped to 1.2.0 (MARKETING_VERSION) / build 3 (CURRENT_PROJECT_VERSION).

---

## [1.1.0] - 2026-02-14

Online overhaul, new features (Settings, Browse, Favorite Groups), and Liquid Glass design polish.

### Added

- **Online hosting with Firebase Firestore**: Full host/join session flow with real-time sync across devices, replacing the previous CloudKit-based approach.
- **Firebase Auth + Apple Sign In**: Nonce-based Apple Sign In flow bridged through Firebase Auth for host identity.
- **StoreKit 2 subscription gating**: Monthly/yearly subscription plans gate online hosting access with load/purchase/restore support.
- **Online session snapshot applier**: Centralized mapper (`OnlineSessionSnapshotApplier`) that keeps local SwiftData overlaps in sync with Firestore session state for participants, responses, phase transitions, and completion.
- **In-flow host management**: Host share/edit/remove participant controls available directly inside questionnaire flow at any state (`OnlineHostManagementSheet`).
- **Reusable invite code card**: `InviteCodeCard` component with monospaced code display, share, and copy actions used in Awaiting and Complete views.
- **Stable online participant identity**: Persisted participant IDs for online sessions so membership/answers no longer depend on display-name matching.
- **App-level Firestore observation**: `HomeView` continuously observes all locally linked online sessions and reconciles snapshots to SwiftData, so list membership/state updates even outside questionnaire detail screens.
- **Deep link join flow**: `overlap://join?token=...` custom scheme for invite links that route directly into the app.
- **Session preview card**: Validates invite code before joining; shows gradient icon, title, host, and participant count in `JoinOnlineSessionView`.
- **Settings page**: Display name (`@AppStorage`), favorite groups CRUD, subscription status, app version display, and `#if DEBUG` developer tools.
- **Favorite Groups**: `FavoriteGroup` SwiftData model for reusable participant name groups; quick-fill picker in `QuestionnaireInstructionsView` with "Last Used" support.
- **Browse directory**: `BrowseView` with `BrowseCatalogService` fetching `browse-catalog.json` — 8 pre-built questionnaire templates across Social, Travel, Entertainment, Food, Work, Family, and Health categories that users can save to their library.
- **Shared subscription flyout**: Extracted `SubscriptionFlyout` component used by both `OnlineSessionSetupView` and `SettingsView`.
- **Color↔hex utility**: `ColorHex.swift` for Firestore visual data storage (icon emoji, gradient colors on sessions).
- **Online participant identity service**: `OnlineParticipantIdentityService` for stable ID-based membership.
- **Firebase bootstrap**: `FirebaseBootstrap.swift` with `UIApplicationDelegate` adapter for clean SwiftUI lifecycle initialization.
- **`.gitignore`**: Covers secrets, keys, and build artifacts.
- **`AGENTS.md`**: Codified workflow, commands, and development guidelines.

### Changed

- **Online flow routing**: Both host and guest online sessions use the same `nextParticipant → answering → awaiting → complete` path instead of separate branches.
- **Answering view**: Uses backend-authoritative online answer submission; surfaces removal errors and prevents local-only advancement drift.
- **Next participant view**: Shows "Your Turn" subtitle for online overlaps instead of "Next Participant".
- **Questionnaire view**: Added awaiting→complete transition alert ("All Responses In!") with navigation to results.
- **Invite normalization**: Trims punctuation and spacing from pasted invite codes for more reliable acceptance.
- **Session phase rules**: One-participant online sessions stay in `awaiting` instead of auto-completing; host cannot be removed.
- **Snapshot priority**: Participant-local answering state takes precedence over aggregate session awaiting when participant has unanswered questions.
- **Firebase fail-fast**: Online service errors explicitly instead of silently falling back to local-only state.
- **Begin Questions**: Writes participant status to Firestore before local navigation to prevent snapshot sync bounce-back.
- **Subscription flyout**: Non-dismissible sheet with feature list, `GlassActionButton` subscribe/restore buttons, and Liquid Glass presentation.
- **Auth section**: Person icon + name card layout with Sign In with Apple wrapped in glass card.
- **Join view**: Centered header icon, `largeGlassCard()` joined summary, display name auto-fill from `@AppStorage`.
- **Host management sheet**: Colored status pills, context menu actions, `GlassActionButton` for rename.
- **List items**: Removed local/offline pills; added online + host indicators on In Progress and Completed overlap list items.
- **Complete/Awaiting views**: Floating `GlassActionButton` anchored at bottom (ZStack overlay pattern) for Manage Session.
- **Browse view**: `GlassScreen` with blob background, centered header, full-width glass template cards.
- **All sheets**: `.presentationBackground(.ultraThinMaterial)` for Liquid Glass consistency.
- **QuestionnaireHeader**: Fixed hardcoded `spacing: 16` → `Tokens.Spacing.l`.
- **Version**: Bumped to 1.1.0 (MARKETING_VERSION) / build 2 (CURRENT_PROJECT_VERSION).

### Removed

- Legacy CloudKit sharing stack and stale sync flows.
- `DisplayNameSetupView` (replaced by Settings display name field).
- `UserPreferences` utility (replaced by `@AppStorage`).
- Inline subscription flyout from `OnlineSessionSetupView` (extracted to shared `SubscriptionFlyout`).
- Orphaned StoreKit purchase/restore/currency helpers from `OnlineSessionSetupView`.

---

## [1.0.0] - 2025-08-17

Initial feature-complete local overlap app with CloudKit sharing experiments.

### Added

- **Core questionnaire engine**: Create, edit, save, and play local overlap questionnaires with multi-participant support.
- **Questionnaire authoring**: Full create/edit flow with title, instructions, author, emoji icons, gradient colors, and question list management.
- **Local overlap sessions**: Instructions → participant handoff → answering → awaiting → complete flow with SwiftData persistence.
- **Saved/In Progress/Completed views**: List views with overlap state tracking and navigation.
- **Design token system**: `Tokens.Spacing`, `Tokens.Radius`, `Tokens.Size`, `Tokens.Shadow`, `Tokens.Duration`, `Tokens.Spring` for consistent styling.
- **Glass morphism UI**: `GlassScreen`, `GlassActionButton`, `.standardGlassCard()`, `.largeGlassCard()`, `.heroGlassCard()` with blob background animations.
- **Reusable components**: `SectionHeader`, `QuestionnaireIcon`, `EmptyStateView`, `BlobBackgroundView`, `QuestionEditorCarousel`.
- **Navigation utilities**: Custom `@Environment(\.navigationPath)` binding for programmatic navigation.
- **Home menu**: Radial menu options for Create, Saved, In Progress, Completed, Browse, Join, and online hosting.
- **SwiftData models**: `Questionnaire`, `Overlap` with full CRUD and relationship support.
- **CloudKit sharing (experimental)**: Service layer, sync manager, and UI components for CloudKit-based collaboration (later replaced by Firebase in 1.1.0).

### Changed

- Refactored questions from custom answer types to simple string lists.
- Refactored session model from sub-models to flat `Overlap` structure for SwiftData compatibility.
- Refactored emoji-based questionnaire icons replacing system image icons.
- Centralized design tokens across all UI components (replaced hardcoded values).
- Enhanced touch targets and spacing for accessibility.
- Simplified question editor from complex carousel to scrollable paginated view.

---

## [0.1.0] - 2025-07-24

Project bootstrap and initial scaffolding.

### Added

- Initial Xcode project setup with SwiftUI lifecycle.
- Basic home menu with Liquid Glass styling.
- Questionnaire and overlap data model foundations.
- Core view hierarchy scaffolding.
