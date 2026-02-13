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

- Host flow: gate -> Apple sign-in -> create session -> native share sheet link + fallback invite code.
- Guest flow: paste/open invite -> enter display name -> join session.
- Session constraints: 25 participant cap and 30-day expiration with host extension button.

## Remaining work (next milestones)

1. Replace local session store stubs with Firebase Auth + Firestore + Cloud Functions.
2. Replace debug subscription gate with StoreKit 2 entitlements.
3. Enforce host entitlement checks in backend callable functions.
4. Attach online session participation to questionnaire answering flow and realtime updates.
5. Add analytics/cost telemetry and anti-abuse controls.
