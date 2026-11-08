# Pricing Configuration

## Monetization Model: Freemium with IAP

Free-to-download with a permanent free tier (unlimited logging, plans and statistics), a Pro auto-renewable subscription (monthly or yearly with a 7-day trial), and a one-time Lifetime purchase. Data is never locked when payment stops.

## Subscription Group
- **Group Name**: RepRamp Pro
- **Reference Name**: RepRamp Pro
- **Products in group**: RepRamp Pro Monthly, RepRamp Pro Annual

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: RepRamp Pro Monthly
- **Product ID**: `com.zzoutuo.RepRamp.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $6.99 USD per month
- **Display Name**: `RepRamp Pro Monthly` (18 chars, ≤35 ✅)
- **Description**: `Unlimited cloud AI coaching and full stats.` (47 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: RepRamp Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription
- **Reference Name**: RepRamp Pro Annual
- **Product ID**: `com.zzoutuo.RepRamp.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $39.99 USD per year (52% savings vs monthly)
- **Display Name**: `RepRamp Pro Annual` (17 chars, ≤35 ✅)
- **Description**: `Yearly access with a 7-day free trial. Save 52%.` (47 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: RepRamp Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Lifetime
- **Reference Name**: RepRamp Lifetime
- **Product ID**: `com.zzoutuo.RepRamp.pro.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $79.99 USD (one-time)
- **Display Name**: `RepRamp Lifetime` (15 chars, ≤35 ✅)
- **Description**: `One-time unlock. All Pro features forever.` (42 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Lifetime includes the same Pro feature set as the subscription plus unlimited use of the user's own AI key (BYO), so heavy AI users never pay again.
- **⚠️ DIFFERENTIATION NOTE**: Lifetime and Pro subscription unlock the SAME feature set; Lifetime exists for users who prefer paying once. It does not include any exclusive feature the subscription lacks, and the subscription remains cheaper for short-term use.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - Unlimited workout logging with unlimited plans and templates
  - RampCoach™ white-box weight recommendations with "Show me why"
  - Full exercise library (800+ movements) and custom exercises
  - RepRank levels, streaks and PR detection
  - Unlimited volume/statistics charts and 1RM estimates
  - Rest timer, CSV/JSON export, HealthKit recovery reading
  - Apple on-device AI plan generation (iOS 26+, when available)
- **Conversion hooks**:
  - Cloud Body Scan (muscle-balance radar and priorities) — first scan opens the paywall
  - Cloud AI plan generation beyond the first free on-device draft
  - "Your next weight is already computed. Cloud AI makes the plan adaptive."

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (Monthly / Yearly / Lifetime) |
|---------|:----:|:--------------------------------:|
| Unlimited logging, plans, statistics | ✅ | ✅ |
| RampCoach recommendations + explanations | ✅ | ✅ |
| Exercise library and custom exercises | ✅ | ✅ |
| RepRank, streaks, PRs | ✅ | ✅ |
| CSV / JSON export | ✅ | ✅ |
| Apple on-device AI plan drafting (iOS 26+) | ✅ | ✅ |
| Cloud AI plan generation (GLM proxy) | ❌ | ✅ Unlimited |
| AI Body Scan with muscle-balance radar | ❌ | ✅ Unlimited |
| Screenshot → structured plan import | ❌ | ✅ Unlimited |
| BYO API key unlimited cloud AI (any of six providers) | ✅ (own key) | ✅ (own key) |
| Advanced analytics (muscle balance, weekly delta) | ✅ | ✅ |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: Yearly subscription only

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView
- [x] Free trial terms included (7 days, yearly only)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
