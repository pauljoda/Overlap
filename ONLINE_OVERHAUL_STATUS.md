# Online Overhaul Status

## Implemented in `codex/online-overhaul-foundation`

- Added a separate online domain layer that is independent from the local Overlap model flow:
  - `Overlap/Services/Online/OnlineConfiguration.swift`
  - `Overlap/Services/Online/OnlineSubscriptionService.swift`
  - `Overlap/Services/Online/OnlineHostAuthService.swift`
  - `Overlap/Services/Online/OnlineSessionService.swift`
  - `Overlap/Services/Online/OnlineEnvironment.swift`
- Added dedicated online views:
  - `Overlap/Views/Online/OnlineSessionSetupView.swift`
  - `Overlap/Views/Online/JoinOnlineSessionView.swift`
- Added development-only host testing bypass:
  - Dev Host sign-in option in DEBUG builds (no Apple account required for local testing).
  - Existing DEBUG subscription entitlement overrides remain in place.
- Added Firebase bootstrap + auth wiring:
  - App bootstraps Firebase when `GoogleService-Info.plist` and SDK are present.
  - Apple sign-in host flow now includes nonce handling and Firebase Auth bridge support.
- Added Firestore-backed online session operations with local fallback:
  - Host create/latest/extend/close and guest join can use Firestore when configured.
  - Local in-memory/UserDefaults flow remains as fallback for development.
- Added StoreKit 2 subscription scaffolding:
  - Loads products by configured IDs.
  - Supports purchase + restore.
  - Refreshes entitlement from current StoreKit transactions.
- Rewired navigation:
  - `QuestionnaireDetailView` online button now routes to host setup.
  - Home menu now includes `Join Session` route.
  - Added typed online routes in `NavigationUtils`.
- Added deep-link invite parsing and routing in `HomeView`.
- Updated app root to inject online services and use local-only SwiftData configuration.
- Added deep-link placeholders:
  - URL scheme `overlap://...`
  - associated domain placeholder `applinks:join.overlapapp.link`
- Completed legacy cleanup pass (CloudKit removal):
  - Deleted obsolete CloudKit/share services and delegates.
  - Removed old share UI controls and sync manager dependencies from active views.
  - Simplified the `Overlap` model by removing CloudKit-only fields.
  - Removed stale iCloud share capabilities from `Info.plist` and entitlements.

## What this slice provides now

- Host flow: gate -> Apple sign-in (or DEBUG Dev Host) -> create session -> native share sheet link + fallback invite code.
- Guest flow: paste/open invite -> enter display name -> join session (Firestore-backed when configured).
- Session constraints: 25 participant cap and 30-day expiration with host extension button.

## Remaining work (next milestones)

1. Finish Apple provider setup in Firebase console and verify Firebase Auth host identity in device builds.
2. Add Cloud Functions + hardened Firestore rules for authoritative participant cap/session lifecycle enforcement.
3. Enforce host subscription entitlement in backend before create/extend operations.
4. Attach online session participation to questionnaire answering flow and realtime updates.
5. Add analytics/cost telemetry and anti-abuse controls.
