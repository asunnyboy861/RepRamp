# App Review Information

## App Overview

RepRamp is a strength-training log with a transparent weight-progression engine. Free features (unlimited logging, plans, statistics, export) work with no account and no network. Pro unlocks cloud AI features.

**No account is required.** There is no login, no demo account, and all data is stored locally on the device with SwiftData.

## AI Feature Testing

### Default Engine — Apple Intelligence (no setup)
On iPhone 15 Pro or newer running iOS 26, text-based AI plan drafting uses the on-device Foundation Models framework. No API key is required. Open the Coach tab → choose goal, experience, location and days → tap "Generate my plan".

### Fallback — Bring Your Own API Key
On older devices or simulators, Apple Intelligence is unavailable and the Coach tab shows "Add my own key". Reviewers can test the BYO path:
1. Obtain any OpenAI-compatible API key from a provider of their choice.
2. Open Settings (gear icon) → AI providers → Add your own API key.
3. Select a provider, paste the key, keep the prefilled model and base URL.
4. Tap "Test connection" then "Save configuration".
5. Return to Coach and generate a plan, or open Progress → AI Body Scan and analyze a photo.

The app does not sell API keys or AI usage. Any provider cost is paid by the user directly to their provider. No specific provider is promoted.

### Cloud AI and Subscription
Cloud AI requests use either the user's own key or a verified StoreKit 2 entitlement. When no engine is available, AI buttons are disabled and explanatory guidance is shown; they never lead to a dead error state.

Body Scan and screenshot import use a vision-capable engine. Photos are sent only after the user taps Analyze and are discarded from memory immediately after processing. No photo is stored or logged.

## Subscriptions

| Product ID | Type | Price | Trial |
|---|---|---|---|
| `com.zzoutuo.RepRamp.pro.monthly` | Auto-renewable | $6.99 / month | None |
| `com.zzoutuo.RepRamp.pro.yearly` | Auto-renewable | $39.99 / year | 7 days |
| `com.zzoutuo.RepRamp.pro.lifetime` | Non-consumable | $79.99 once | None |

The paywall lists title, length, price, trial terms, auto-renewal disclosure, Restore Purchases, Manage Subscription, Privacy Policy and Terms of Use. No data is locked when a subscription lapses.

## HealthKit

HealthKit use is clearly identified in the app:
- Settings → "Apple Health (HealthKit)" section with the HealthKit icon
- "HealthKit Integration" row with a Learn More button opening a dedicated HealthKit information screen
- Toggle labeled "Sync workouts to HealthKit"
- Section footer explaining read and write behavior

RepRamp reads sleep analysis, HRV, resting heart rate and body weight through HealthKit to adjust training intensity, and writes completed strength workouts. Nothing is read without explicit user authorization, and permission is never required to log workouts. Revoked access is handled gracefully.

## Required Links

- Privacy Policy: https://asunnyboy861.github.io/RepRamp/privacy.html
- Terms of Use: https://asunnyboy861.github.io/RepRamp/terms.html
- Support: https://asunnyboy861.github.io/RepRamp/support.html

Links appear in Settings → Legal and in the paywall.

## Review Notes

### HealthKit Functionality
- Settings shows "Apple Health (HealthKit)" with brand icon and a Learn More page.
- Toggle: "Sync workouts to HealthKit".
- Read types: sleep analysis, HRV (SDNN), resting heart rate, body mass.
- Write type: strength training workouts.
- No health data is accessed without user permission, and the app works fully without it.

### AI Features (BYO Key Model)
- AI features use a bring-your-own-key model; the app does not sell keys or usage.
- No specific provider is promoted in user-facing UI.
- Users can configure any OpenAI-compatible endpoint, including custom servers.
- AI output is decoded into strict JSON and validated before it can be saved; invalid output is rejected and never silently inserted.
- AI-generated plans are always presented as an editable draft requiring explicit user confirmation.

### China App Store Compliance
This app does not include ChatGPT functionality and does not reference ChatGPT or OpenAI in user-facing UI or metadata. The AI feature uses a generic bring-your-own-key model where the user configures an endpoint and key. No provider is bundled or promoted.

### Data and Privacy
- All training data is local-first and exportable as CSV or JSON.
- API keys are stored in the iOS Keychain and never logged.
- No analytics SDKs, no third-party tracking, no advertising.
- Cloud AI photos are processed in memory and never persisted.

### Disclaimer
All AI and coaching output is labeled "General fitness guidance, not medical advice."
