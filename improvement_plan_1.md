# Improvement Plan 1

## Phase A — Audit Findings

| ID | Description | Severity | Fix |
|----|-------------|----------|-----|
| ISSUE-001 | App crashed on every launch: SwiftData inferred CloudKit from the iCloud entitlement, which rejects unique constraints, non-optional attributes and the non-optional `Workout.sets` relationship | Critical | Configure the store explicitly with `cloudKitDatabase: .none`; verified launch on simulator |
| ISSUE-002 | Apple Intelligence reported as available on every iOS 26 simulator, leaving a clickable Generate button that failed at runtime | Critical | Availability now reads `SystemLanguageModel.default.availability` and returns false on simulator; disabled buttons dim to 45% opacity |
| ISSUE-003 | Paywall promised "Cloud AI weekly summaries" and `price.md` listed it, but no such feature exists | Major | Copy corrected to "Cloud AI plans and screenshot-to-plan import"; `price.md` row removed |
| ISSUE-004 | `us.md` advertised CloudKit per-record merge sync while the shipped store is local-only | Major | `us.md` feature 13 rewritten as local-first + export with CloudKit explicitly deferred; `capabilities.md` records the container prerequisite |
| ISSUE-005 | Closing a workout before logging any set left an orphan unfinished workout row | Major | Close now discards the empty workout |
| ISSUE-006 | Disabled primary/secondary buttons looked fully enabled | Major | Dimmed disabled states across Coach, Body Scan, Paywall and Contact Support |
| ISSUE-007 | Empty Progress export section offered nothing and no explanation | Minor | Shows "Log your first workout to unlock export." |
| ISSUE-008 | Exercise library footer hardcoded "876 total" | Minor | Uses the live exercise count |
| ISSUE-009 | Unused `appeared` state in the workout summary | Minor | Removed |
| ISSUE-010 | No automated tests for the core RampCoach/RankEngine logic | Major | Added a unit-test target with 15 tests covering 1RM, increments, double progression, safety cap, RPE consolidation, feedback, recovery trim, rank thresholds, streaks, templates and AI validation |
| ISSUE-011 | HealthKit read permission cannot be revoked in-app | Minor | Toggle-off shows an explanatory alert pointing to the Health app (iOS limitation) |
| ISSUE-012 | Seeding runs on the main thread on first launch | Minor | Guarded by a one-time flag and a single store write; acceptable for an 876-row catalog |

## Phase B — Implementation

All items above were implemented and verified:

- Expo build for simulator: BUILD SUCCEEDED
- Unit tests: 15 passed, 0 failed
- Runtime smoke test with seeded data: onboarding, Today, Progress, Coach and Settings all render correctly

## Phase C — Final Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| Usability | 4/5 | Today screen answers "what do I lift now" in one glance; 3-tap set logging |
| UI Consistency | 4/5 | Single dark design system, shared cards/buttons, no one-off styles |
| Feature Completeness | 4/5 | All 15 primary features present; CloudKit sync and Watch intentionally out of scope and documented |
| Download-to-Use | 4/5 | Onboarding generates a plan with no account; core loop needs zero configuration |
| Competitive Level | 4/5 | White-box explanations, per-set logging, radar Body Scan and lifetime buyout differentiate from Hevy/Strong/Fitbod |
| Contact Support | 4/5 | Seven preset subject tiles, required fields, backend POST, success/error banners, privacy microcopy |
| Accessibility | 3/5 | VoiceOver labels on primary controls, Dynamic Type mostly semantic; custom charts summarized via accessibility labels; needs a full VoiceOver pass on the logging screen |

## Residual Items (not code issues)

- StoreKit products must be created in App Store Connect
- GLM worker whitelist registration requires the worker admin key
- HealthKit/iCloud provisioning requires an Xcode account login
- VoiceOver sweep on the workout logging screen recommended before release
