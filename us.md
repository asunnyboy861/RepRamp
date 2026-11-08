# RepRamp — iOS Development Guide

## Executive Summary

RepRamp is a strength-training companion for the US English market built around one promise: **your next weight, already decided.** Every time the lifter opens the app, the Today screen shows the exact exercise, set count, rep target and load for the session, plus a plain-language reason for that recommendation ("Last set RPE 8/10 → +2.5 lb"). No black box, no guessing.

The product competes directly with Symmetry (Spanish-market leader, ~$160K/month, 3M downloads), Fitbod (black-box AI, no free tier), Hevy and Strong (pure logs with template walls). RepRamp wins on four axes:

1. **White-box RampCoach™ engine** — double progression + RPE rules, every recommendation ships with an explanation and a one-tap "too heavy / too light" calibration.
2. **Genuinely free tier** — unlimited logging, unlimited plans and unlimited statistics; only cloud AI is paid.
3. **Never lose data** — local-first SwiftData + CloudKit per-record timestamp merge + CSV/JSON export.
4. **Two AI engines** — Apple on-device Foundation Models (free, offline) and GLM-5.3-Flash through a Cloudflare Worker proxy (vision for Body Scan and screenshot plan import), plus a BYO API-key path with six providers.

- **App name**: RepRamp
- **Subtitle**: Never Guess Your Next Weight
- **Category**: Health & Fitness
- **Target market**: United States (English), dark-mode-first
- **Bundle ID**: `com.zzoutuo.RepRamp` (skill preset from `.env` `BUNDLE_PREFIX`; the guide's `com.repramp.*` product IDs apply to IAP products only)
- **Minimum iOS**: 17.0 (iOS 26 features are gated at runtime)
- **Monetization**: Free tier + Pro subscription (monthly / yearly with 7-day trial) + Lifetime one-time purchase
- **AI**: Apple on-device (free) + GLM cloud proxy (paid) + BYO key (unlimited)

**Health disclaimer**: RepRamp provides general fitness guidance, not medical advice. The disclaimer is shown on the Today screen and on every AI recommendation detail sheet.

---

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| **Symmetry** | AI body scan, 300+ ranked exercises, ±$160K/mo, strong UGC growth | Weak US localization, random sign-outs, only 4 equipment options, no abs/conditioning goals | Native US English, no login wall, 8 goal options, full equipment list, white-box explanations |
| **Fitbod** | Polished AI plans, huge exercise library | No free tier, black-box weights ("recommends way below my potential"), history locked on cancel, 2026 price hike | Free unlimited logging, RampCoach shows the math, history is local and never locked |
| **Hevy** | 4.9 rating, great social features, cheap Pro | Template wall (4 free templates), no recovery data, no guidance | Unlimited plans/templates free, HealthKit recovery-aware deloads, RampCoach recommends |
| **Strong** | Simple, fast logging, lifetime option | Watch sync overwrites/deletes data, no AI, no volume analytics | Per-set timestamp merge CloudKit sync, soft-delete, volume analytics, AI |
| **JuggernautAI** | Elite powerlifting programming | $34.99/mo, three-lift focus | $39.99/year with 7-day trial, full-body gym/bodybuilding support |

**Pricing anchor**: Pro yearly $39.99 sits between Hevy ($23.99) and Fitbod ($95.99); Lifetime $79.99 undercuts Strong's $99.99 while including AI — the only "AI included, buy once" offer in the category.

---

## ⚠️ Feature Inventory

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | **Onboarding quiz (4 questions)** | Launch → 4 cards (goal, experience, location, days/week) → Generate plan | Goal, experience, location, frequency | `OnboardingViewModel` builds a `Plan` using built-in templates (AI optional) | Editable plan preview | SwiftData `Plan`, `OnboardingProfile` flag | Fresh install reaches Today screen with a plan in under 60s; plan is fully editable |
| 2 | **Today dashboard** | Open app → see next session, today's top lift, big target weight, reason line | Current plan + recent `SetEntry` history + optional HealthKit recovery | `TodayViewModel` → `RampCoach.nextSuggestion` per exercise | Hero card: "Bench Press 3×8 @ 135 lb ↑2.5 lb" + "Show me why" | Derived from SwiftData read | Target weight shown with explanation; survives relaunch; matches last logged data |
| 3 | **Live workout logging** | Today → Start Workout → per set: weight ✓ reps ✓ Done ✓ → auto rest timer → Finish | Weight (lb), reps, RPE (optional), warmup flag | `WorkoutSessionViewModel` writes `SetEntry`, starts `RestTimer`, runs PR detection | Fullscreen focus UI with previous-performance ghost text, rest countdown, next-set target | SwiftData `Workout` + `SetEntry` (soft-delete) | 3 taps complete a set; timer auto-starts; previous values always visible; finish persists everything |
| 4 | **RampCoach™ white-box engine** | Tap "Show me why" on any suggestion → factor breakdown → tap too heavy/too light | History of exercise, equipment, recovery factor, user feedback | Pure local double progression + Epley 1RM + safety caps (≤5% or ≤10 lb per jump) | Weight/sets/reps + reason string + caution string | Feedback stored as `RampFeedback` on `SetEntry` | No recommendation exceeds safety cap; unit tests cover increment, plate rounding, deload |
| 5 | **RepRank gamification** | Finish workout → XP awarded → rank badge + upgrade animation | Completed sets, PRs, weekly volume, streak | `RankEngine`: 10 XP/set, +50 weekly match, +100 PR, +200 7-day streak | Rank badge, XP bar, full-screen upgrade animation | `UserProgress` in SwiftData/AppStorage | XP never awarded twice for the same set; rank thresholds match spec; animation plays on promotion |
| 6 | **Exercise library** | Search/browse → filter by muscle/equipment → add to plan or custom exercise | Search text, muscle, equipment | Embedded JSON seed + SwiftData `Exercise`, fuzzy search | List + detail with instructions, primary/secondary muscles, equipment | SwiftData `Exercise` (seeded once) | 800+ bundled exercises available offline; custom exercises persist |
| 7 | **Progress & statistics** | Progress tab → volume chart, muscle balance, PR list, weekly comparison | SetEntry history (90 days) | `ProgressViewModel` aggregates volume by week/muscle, estimates 1RM | Charts (Swift Charts), PR badges, "this week vs last" delta | Derived; exportable | Charts render real data; empty state guides first workout; 1RM estimates correct |
| 8 | **Plans & templates** | Plan tab → view split days → edit/add exercises, sets, reps, rest | Plan edits | `PlanRepository` CRUD on `Plan`/`PlanSession`/`PlanItem` | Day cards with exercise targets | SwiftData `Plan` | Unlimited plans, fully editable, no paywall |
| 9 | **Body Scan (AI vision)** | Progress → Body Scan → 1-3 photos → analyze → muscle balance radar + 3 priorities → "turn into plan" | JPEG photos, goal context | `AIGateway` → GLM proxy vision → strict JSON decode → validate ranges | Radar chart, priorities, plan adjustment proposal | Only derived metrics stored; original photos discarded | Photos never persisted; invalid AI JSON rejected and retried once; error states informative |
| 10 | **AI plan generation / screenshot import** | Coach tab → answer prompts or attach a plan screenshot → generate → preview → accept | Text answers or screenshot | `AIGateway` → Apple on-device (text) or GLM vision (screenshot) → schema validation | Editable plan draft | SwiftData `Plan` on accept | AI output never inserted silently; user must confirm; invalid exercises rejected |
| 11 | **Paywall & StoreKit 2** | Natural trigger (2nd AI plan, first Body Scan) → paywall → purchase/restore → manage | Product selection | `StoreKitManager` loads 3 products, verifies transactions, mirrors entitlement | Entitlement badge, feature unlock | StoreKit + local entitlement cache | Prices, trial, auto-renew disclosure, Privacy & Terms links visible; restore works |
| 12 | **BYO AI settings** | Settings → AI → choose provider → paste key → model/base URL → Test Connection | Provider, API key, model, base URL | `BYOEngine` OpenAI-compatible call or Anthropic native adapter; key in Keychain | Green check + latency, or specific error | Keychain only (never UserDefaults/logs) | Six providers supported; key survives relaunch; 401/404/timeout distinctions shown |
| 13 | **Local-first data + export** | Automatic local save; Settings → Export CSV/JSON | Local records | Per-set records with timestamps and soft-delete tombstones | Restored data, share-sheet files | SwiftData local store + local file | No record loss on relaunch; deleted sets stay tombstoned; export opens share sheet. CloudKit sync is deferred until the container is registered (see capabilities.md) |
| 14 | **HealthKit integration** | Onboarding/settings permission → recovery card today; workouts written back | HRV, sleep, resting HR, body weight | `HealthKitService` reads last-night recovery → `recoveryFactor`; writes workouts | Recovery caution text, deload suggestion | HealthKit store (read) + workout samples (write) | Degrades silently when permission denied; never blocks logging |
| 15 | **Contact support** | Settings → Contact Support → subject tiles + message → send | Topic, message, email | POST to `${FEEDBACK_BACKEND_URL}` | Success/error feedback | None | Subject tiles, required validation, network error handling, privacy microcopy |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail Description | Interaction Pattern |
|---|--------|-------------|-------------------|-------------------|
| 3.1 | Live logging | Previous-performance ghost text | Last set for the exercise shown in grey under the input | Static label |
| 3.2 | Live logging | Auto rest timer | Starts the moment a set is completed; shows next set target | Countdown ring, tap to skip ±15s |
| 3.3 | Live logging | PR detection | New best estimated 1RM or weight triggers edge-of-screen gold flash | One-time animation + haptic |
| 3.4 | Live logging | Warmup sets | Toggle marks a set as warmup; excluded from volume/PR | Swipe action / toggle |
| 3.5 | Live logging | Soft delete | Deleting a set tombstones it instead of removing the row | Swipe to delete |
| 4.1 | RampCoach | "Show me why" sheet | RPE, volume, detraining days broken out as factors | Sheet with rows |
| 4.2 | RampCoach | Feedback calibration | Too heavy / too light adjusts next recommendation | Segmented buttons |
| 5.1 | RepRank | Rank badge | Bronze → Legend with metallic treatment and texture for color-blind safety | Badge in header/progress |
| 5.2 | RepRank | Streak tracking | Consecutive training days; 7-day streak bonus | Flame counter |
| 5.3 | RepRank | Share card | Weekly volume + rank + PR shareable image | ShareLink |
| 6.1 | Exercise library | Custom exercise | Create name/muscles/equipment; flagged `isCustom` | Form sheet |
| 6.2 | Exercise library | Filter chips | Muscle group and equipment filters | Chips |
| 7.1 | Progress | Weekly delta | "This week vs last: +8% volume" | Stat card |
| 7.2 | Progress | Muscle balance | Sets per muscle group bar chart | Bar chart |
| 9.1 | Body Scan | Photo guidance | Front/side framing overlay | Camera overlay |
| 9.2 | Body Scan | Turn into plan | Applies suggested volume redistribution to next week | Confirmation dialog |
| 11.1 | Paywall | Trial disclosure | 7-day free trial for yearly, explicit renewal terms | Text block |
| 11.2 | Paywall | Restore / manage | Restore purchases + link to system subscription management | Buttons |
| 12.1 | BYO | Test connection | Minimal request, latency + model echo | Button with spinner |
| 12.2 | BYO | Vision capability notice | Providers without vision grey out Body Scan entries | Inline banner |
| 13.1 | Export | CSV + JSON | Human-readable CSV and lossless JSON | ShareLink |
| 14.1 | HealthKit | Recovery card | Sleep/HRV based caution on Today | Card |
| 15.1 | Support | Subject tiles | SF Symbol tiles: Bug, Feature, Billing, Other | 2×2 grid |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Logged set → next weight | Live logging | Today dashboard | `SetEntry` history | Session finish / each set |
| Logged set → XP/rank | Live logging | RepRank | Set count, PR flag, volume | On set completion |
| HealthKit recovery → RampCoach | HealthKit | RampCoach | `recoveryFactor` | Every suggestion computation |
| AI plan draft → Plan | AI generation | Plans | `Plan` JSON | User accepts |
| Body Scan priorities → Plan | Body Scan | Plans | Volume redistribution | User confirms |
| Entitlement → AI access | StoreKit | AIGateway | `isPro` flag + JWS | Every cloud AI call |
| BYO config → AIGateway | BYO settings | AI features | `BYOConfig` | When configured |
| Exercise library → logging | Library | Live logging | `Exercise` reference | Adding to workout |

**Feature count verification**: 15 primary features, 22 sub-features, 8 cross-feature dependencies — matches the Chinese guide's MVP phases 1–3 and checklist (Watch app and Live Activity are explicitly out of scope for this build; see Capabilities).

---

## Apple Design Guidelines Compliance

- **HIG — Dark-first, high-contrast**: default dark palette (`#0E0E10`), light mode supported through semantic colors.
- **HIG — Touch targets ≥44pt**: primary actions are 56pt+, thumb-reachable at the bottom of the screen.
- **HIG — Dynamic Type**: all text uses semantic/`.dynamicTypeSize`-aware styles; hero numbers scale with limits.
- **HIG — Haptics**: confirmation haptic on every set completion and rank-up.
- **HIG — Privacy**: HealthKit read/write usage strings, photos processed in memory only, Keychain for API keys.
- **App Review 3.1.2(c)**: Paywall shows product title, duration, price, trial length, auto-renew disclosure, Privacy Policy and Terms links.
- **App Review 5.1.1**: purpose strings for HealthKit and camera/photo library.
- **App Review 2.1(a)**: all AI entry points either work or are clearly disabled with an explanation — never a dead button.
- **Health apps 1.4.1**: persistent "General fitness guidance, not medical advice" disclaimer.

---

## Technical Architecture

- **Language**: Swift 5.10+
- **UI**: SwiftUI, dark-first design system
- **Data**: SwiftData (local-first), CloudKit private database (optional sync), AppStorage for lightweight flags
- **Health**: HealthKit (HRV, sleep, resting HR, body mass read; workouts written)
- **Purchases**: StoreKit 2 (`Product`, `Transaction.currentEntitlements`, `jwsRepresentation`)
- **AI**: `AIGateway` single entry point → Apple Foundation Models (iOS 26+, text) / GLM Worker proxy (vision + fallback) / BYO engine (6 providers)
- **Charts**: Swift Charts
- **Networking**: URLSession only, no third-party dependencies
- **Exercise data**: bundled `exercises.json` derived from free-exercise-db (Unlicense)

### Module Structure

```
RepRamp/
├── App/
│   ├── RepRampApp.swift
│   └── AppEnvironment.swift
├── Models/
│   ├── Exercise.swift
│   ├── Workout.swift
│   ├── SetEntry.swift
│   ├── Plan.swift
│   ├── UserProgress.swift
│   └── OnboardingProfile.swift
├── Repositories/
│   ├── WorkoutRepository.swift
│   ├── ExerciseRepository.swift
│   └── PlanRepository.swift
├── Services/
│   ├── RampCoach.swift
│   ├── RankEngine.swift
│   ├── ProgressAnalytics.swift
│   ├── HealthKitService.swift
│   ├── CloudSyncService.swift
│   ├── ExportService.swift
│   ├── StoreKitManager.swift
│   ├── ContactSupportService.swift
│   └── AI/
│       ├── AIGateway.swift
│       ├── AIEngine.swift
│       ├── AppleIntelligenceEngine.swift
│       ├── GLMProxyEngine.swift
│       ├── BYOEngine.swift
│       ├── BYOConfig.swift
│       └── AIResponseValidator.swift
├── Features/
│   ├── Onboarding/
│   ├── Today/
│   ├── Logging/
│   ├── Plans/
│   ├── Progress/
│   ├── Coach/
│   ├── Paywall/
│   └── Settings/
├── DesignSystem/
│   ├── Theme.swift
│   └── Components/
└── Resources/
    ├── Assets.xcassets
    └── exercises.json
```

---

## ⚠️ Data Flow Diagram

```
Feature: Live workout logging
User input: weight, reps, RPE, Done tap
  → WorkoutSessionViewModel (validate 0–1000 lb, 0–100 reps)
  → WorkoutRepository.insert SetEntry(workout, exercise, createdAt, updatedAt)
  → SwiftData save
  → RankEngine.awardXP(set) → UserProgress update
  → RestTimer.start(restSeconds)
  → View renders ghost previous values, next-set target, rest countdown
  → On finish: ProgressAnalytics recompute → TodayViewModel next suggestions

Feature: RampCoach suggestion
SetEntry history (per exercise, last 30 days)
  → RampCoach.nextSuggestion(history, equipment, recoveryFactor)
  → RampSuggestion(weight, sets, reps, reason, caution)
  → TodayViewModel / WorkoutSessionViewModel
  → UI hero number + "Show me why" sheet

Feature: Body Scan
Camera/photo JPEG → AIGateway.run(.bodyScan) → GLMProxyEngine (base64 data URI)
  → JSON object → AIResponseValidator (schema + range checks)
  → BodyScanResult(muscleBalance, priorities)
  → UI radar chart; photos discarded immediately
  → Optional: PlanRepository.apply(redistribution)

Feature: Purchase
Paywall tap → StoreKitManager.purchase(product)
  → Transaction verified → entitlement cached
  → AIGateway reads isPro → GLM JWS attached on cloud calls
```

---

## Implementation Flow

1. SwiftData models + repositories (soft-delete, timestamps).
2. Seed exercise library from bundled JSON on first launch.
3. RampCoach engine + RankEngine with unit-testable pure functions.
4. Design system (dark theme, hero typography, cards, buttons).
5. Onboarding quiz → built-in plan templates.
6. Today dashboard + live logging + rest timer + PR feedback.
7. Plans editor, exercise library browser, custom exercises.
8. Progress analytics with Swift Charts + PR list.
9. StoreKit 2 manager + paywall.
10. AI gateway (Apple + GLM proxy + BYO) + Body Scan + AI plan.
11. HealthKit read/write, CloudKit sync, CSV/JSON export.
12. Settings, contact support, disclaimer, accessibility pass.

## UI/UX Design Specifications

- **Colors**: Ramp Orange `#FF5A1F` primary; background `#0E0E10`; surface `#1A1A1E`; text primary/secondary/tertiary; rank colors Bronze `#B87333`, Silver `#C0C0C0`, Gold `#FFD700`, Platinum `#E5E4E2`, Diamond `#7FDBFF`, Master `#B26BFF`, Legend `#FFD36B`.
- **Typography**: SF Pro; hero numerals `.system(size: 56, weight: .heavy, design: .rounded)` with rounded monospaced digits.
- **Layout**: single-column card stream, 4 tabs (Today / Log / Progress / Coach), bottom-anchored primary CTA.
- **Motion**: rank-up full-screen confetti/particle burst; PR gold edge sweep; spring transitions on card entry.
- **Accessibility**: Dynamic Type, VoiceOver labels on numeric controls, rank badges include texture/shape differences.

## Code Generation Rules

- MVVM + Repository; views never touch `ModelContext` directly.
- One feature per folder; no third-party dependencies.
- All AI output decoded into `Codable` structs with business range validation before persistence.
- No hardcoded version strings — read from `Bundle.main.infoDictionary`.
- No hardcoded secrets in source; GLM dev key lives in gitignored `GLMProxySecret.txt` excluded from Release.

## Build & Deployment Checklist

1. `xcodegen generate` produces `RepRamp.xcodeproj`.
2. Build for iPhone simulator (iOS 17 deployment target).
3. Run smoke test: onboarding → first plan → first workout → progress.
4. StoreKit products created in App Store Connect (monthly, yearly with trial, lifetime).
5. Policy pages deployed (support / privacy / terms).
6. Metadata and screenshots uploaded.

## ⚠️ App Store Compliance — AI Features

- Apple Intelligence (Foundation Models) is the default free text engine on iOS 26+; **no free-generation counters anywhere** (`freeGenerationsUsed`, `maxFreeGenerations`, `incrementGenerationCount` must not exist).
- On iOS < 26 or simulator, AI entry points explain the fallback instead of failing: "Apple Intelligence requires iOS 26+. Configure your own API key in Settings → AI."
- `canUseCloudAI = isPro || hasBYOKey || devKeyPresent`; free tier users see the paywall, never an error button.
- Cloud AI photos are processed in memory and never persisted or logged.
- `app_review_info.md` documents how reviewers can exercise AI features.

## ⚠️ App Store Compliance — Subscriptions

- Paywall lists: Pro Monthly $6.99/month, Pro Yearly $39.99/year with 7-day free trial (highlighted), Lifetime $79.99 one-time.
- Required: product title, length, price, trial terms, auto-renewal disclosure, restore purchases, Privacy Policy link, Terms of Use (EULA) link, manage-subscription link.
- Subscription value is framed around app features (white-box coaching, Body Scan, cloud AI), never "unlimited AI generations" for BYO users.
- Data is never locked when a subscription lapses — logging, history and export remain available.
