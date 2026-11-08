# Capabilities Configuration

## Analysis

Detected capability keywords from the Chinese guide and `us.md`:

| Keyword | Capability |
|---------|------------|
| 健康 / HealthKit / HRV / sleep | HealthKit |
| iCloud / CloudKit / cloud backup / sync | iCloud + CloudKit |
| 购买 / 订阅 / Pro / Lifetime | In-App Purchase (StoreKit 2) |
| 拍照 / 照片 / Body Scan | Camera + Photo Library |
| 手表 / Watch / Live Activity | Watch app + Live Activity — **not implemented in this build** (out of scope) |

## Auto-Configured Capabilities

| Capability | Status | Method |
|------------|--------|--------|
| HealthKit | ✅ Configured | `RepRamp.entitlements` (`com.apple.developer.healthkit`, empty `healthkit.access`), `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` in project.yml |
| iCloud / CloudKit | ✅ Configured (entitlement) | `com.apple.developer.icloud-container-identifiers` = `iCloud.com.zzoutuo.RepRamp`, `com.apple.developer.icloud-services` = CloudKit |
| Camera | ✅ Configured | `NSCameraUsageDescription` |
| Photo Library | ✅ Configured | `NSPhotoLibraryUsageDescription` |
| In-App Purchase | ✅ Configured | StoreKit 2, no entitlement required |
| Dark-only appearance | ✅ Configured | `INFOPLIST_KEY_UIUserInterfaceStyle = Dark` |
| Privacy manifest | ✅ Configured | `RepRamp/PrivacyInfo.xcprivacy` (UserDefaults CA92.1, FileTimestamp C617.1, no tracking) |
| Outgoing network (AI proxy, feedback) | ✅ Configured | ATS default HTTPS only, no exceptions needed |

## Manual Configuration Required

| Capability | Status | Steps |
|------------|--------|-------|
| Device/Archive signing for HealthKit + iCloud | ⏳ Deferred | Sign into Xcode with the Apple ID for Team `JP4TN5PTS3`, then run once: `xcodebuild -project RepRamp.xcodeproj -scheme RepRamp -destination 'generic/platform=iOS' -allowProvisioningUpdates build`. Xcode auto-creates the profile with HealthKit and iCloud entitlements. |
| CloudKit container registration | ⏳ Pending (optional enhancement) | Container `iCloud.com.zzoutuo.RepRamp` must exist in the Apple Developer portal and its schema deployed before CloudKit sync can be enabled. The app ships local-first and works fully without it; CloudKit sync is not activated in this build to avoid a half-configured data layer. |
| StoreKit products | ⏳ Pending | Create the three products in App Store Connect (IDs below). The paywall renders fallback prices and a clear "store unavailable" state until products exist. |
| GLM Worker whitelist | ⏳ Pending | Register `appId=repramp` with `bundleId=com.zzoutuo.RepRamp` on the GLM-Cloudflare worker using its `/admin/apps` endpoint (`ADMIN_KEY` comes from the GLM-Cloudflare configuration guide). Cloud AI works through the StoreKit entitlement JWS once the bundle ID is whitelisted; no GLM key ever ships in the app. |

StoreKit product IDs:

- `com.zzoutuo.RepRamp.pro.monthly` — $6.99 / month
- `com.zzoutuo.RepRamp.pro.yearly` — $39.99 / year with 7-day free trial
- `com.zzoutuo.RepRamp.pro.lifetime` — $79.99 one-time

## No Configuration Needed

- Push Notifications — no remote notifications in this build
- Location Services — not used
- Background Modes — not required (foreground logging only)
- App Groups / Widgets / Live Activity / Watch — not implemented in this build
- Sign in with Apple — no account system by design

## Verification

- Build succeeded after configuration (iOS 26.4 simulator, iPhone 16): ✅
- Bundle ID: `com.zzoutuo.RepRamp` ✅
- Deployment target: iOS 17.0 ✅
- DEVELOPMENT_TEAM: `JP4TN5PTS3` baked at project level ✅
- Entitlements file wired to the app target ✅
- Signing verification (`generic/platform=iOS`): ⏳ DEFERRED — wildcard profile lacks HealthKit/iCloud; run the `-allowProvisioningUpdates` command above after Xcode login
- PrivacyInfo.xcprivacy: ✅ App target
- Simulator used: iPhone 16 (iOS 26.4) — UDID `C77A1FB3-01CA-4997-A077-95CFB85AEDBB` (cleaned after verification)
