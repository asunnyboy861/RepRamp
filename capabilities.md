# RepRamp — 配置文档

生成时间：2026-11-08

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下项目不配置时，App 的核心功能（训练日志、RampCoach 推荐、计划、统计、导出）仍可正常使用。配置后获得订阅购买、云端 AI、跨设备同步或真机归档能力。

### 🟡 1. Xcode 登录与真机签名（HealthKit + iCloud）

**增强功能**：真机运行、Archive 上传 App Store。
**不配置的影响**：模拟器仍可完整运行；真机构建会因通配描述文件缺少 HealthKit / iCloud 能力而失败。

**当前状态**：工程已写入 `DEVELOPMENT_TEAM = JP4TN5PTS3`，HealthKit 与 iCloud entitlement 已配置，模拟器构建通过。

**请手动完成**：
1. 打开 Xcode → Settings → Accounts，登录 Team `JP4TN5PTS3` 对应的 Apple ID。
2. 在项目根目录终端执行一次（Xcode 会自动注册能力并重生描述文件）：
```
xcodebuild -project RepRamp.xcodeproj -scheme RepRamp -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```
3. 若仍提示能力缺失：Xcode → RepRamp target → Signing & Capabilities，确认 HealthKit 与 iCloud 已勾选，Team 选择 `JP4TN5PTS3`。

---

### 🔵 2. App Store Connect 内购产品（3 个）

**影响功能**：不创建产品，付费墙可展示但不能完成购买（App 会显示 "Products are not available yet"）。

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 你的 App → **Features** → **In-App Purchases**。
2. 先创建订阅组 **RepRamp Pro**，再按下列信息创建 3 个产品：

| 类型 | Reference Name | Product ID | 价格 |
|---|---|---|---|
| 自动续订订阅 | RepRamp Pro Monthly | `com.zzoutuo.RepRamp.pro.monthly` | $6.99 / 月 |
| 自动续订订阅 | RepRamp Pro Annual | `com.zzoutuo.RepRamp.pro.yearly` | $39.99 / 年，含 7 天免费试用 |
| 非消耗型 | RepRamp Lifetime | `com.zzoutuo.RepRamp.pro.lifetime` | $79.99 一次性 |

3. Display Name / Description 直接从 `price.md` 复制（已校验 ≤35 / ≤55 字符）。
4. 年订阅在 **Introductory Offer** 中配置 7 天免费试用。
5. 产品状态变为 "Ready to Submit" 后，在 App 内付费墙点 **Restore purchases** 验证。

---

### 🟢 3. GLM 云 AI 白名单注册（可选）

**增强功能**：Pro 用户通过官方代理使用云端 AI（计划生成 / Body Scan / 截图导计划）。
**不配置的影响**：App 仍可用 Apple 端侧 AI（iOS 26+ 真机）或用户自带 API Key；仅官方云端通道返回 401。

**当前状态**：`GLMProxyEngine` 已按规范实现（appId=`repramp`、thinking、max_tokens、JSON 输出、429/401 处理），不包含任何 GLM 密钥。

**请手动完成**：
1. 从 GLM-Cloudflare 配置指南获取 `ADMIN_KEY`。
2. 执行注册（Bundle ID 必须与 Xcode 完全一致）：
```
curl -X POST "https://cramjam-api.calcs.top/admin/apps" \
  -H "Content-Type: application/json" \
  -d '{"adminKey":"<ADMIN_KEY>","appId":"repramp","bundleId":"com.zzoutuo.RepRamp","note":"RepRamp fitness tracker"}'
```
3. 若需测试期 devKey：把 devKey 写入 `RepRamp/GLMProxySecret.txt`（该文件已加入 `.gitignore`，不要提交）。生产环境不需要它，App 会优先使用 StoreKit 2 的 `appTransaction` JWS。

---

### 🟣 4. App Store Connect 审核信息

**影响功能**：审核员需要能测试 AI 与 HealthKit 功能，否则可能按 2.1(a) 拒审。

**配置步骤**：
1. App Store Connect → App → **App Review Information**。
2. **Demo Account** 填入 "无需账号，本地即用；AI 测试请使用用户自带 API Key 或 Apple Intelligence 真机"。
3. **Notes** 粘贴 `app_review_info.md` 中 Review Notes 全文（包含 HealthKit、BYO Key、中国区合规、订阅测试与政策链接）。
4. **Privacy Policy URL** 填 `https://asunnyboy861.github.io/RepRamp/privacy.html`。

---

### ⚪ 5. CloudKit 容器（本次未启用，可选）

**增强功能**：多设备自动同步。
**不配置的影响**：App 采用本地优先存储 + CSV/JSON 导出，功能完整。
**说明**：当前数据层显式使用 `cloudKitDatabase: .none`，以避免半配置状态导致 SwiftData 启动失败。若未来启用，需要在 Apple Developer 门户创建容器 `iCloud.com.zzoutuo.RepRamp` 并部署 Schema。

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|---|---|---|
| HealthKit | entitlements + `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` 已配置 | ✅ 已配置 |
| iCloud / CloudKit | 容器 `iCloud.com.zzoutuo.RepRamp` 与 CloudKit 服务已写入 entitlements | ✅ 已配置（数据层暂未启用同步） |
| Camera | `NSCameraUsageDescription` 已配置 | ✅ 已配置 |
| Photo Library | `NSPhotoLibraryUsageDescription` 已配置 | ✅ 已配置 |
| In-App Purchase | StoreKit 2 代码与三档产品 ID 已实现 | ✅ 已完成 |
| PrivacyInfo.xcprivacy | App target 已包含（UserDefaults CA92.1 / FileTimestamp C617.1） | ✅ 已配置 |
| 出口合规 | `ITSAppUsesNonExemptEncryption = NO` | ✅ 已配置 |
| 深色外观 | `UIUserInterfaceStyle = Dark` | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|---|---|---|
| 联系客服后端 | `https://msg.calcs.top/api/feedback` 已接入，7 个主题磁贴 + 必填校验 | ✅ 已接入 |
| 网络权限 | HTTPS 出站，无需 ATS 例外 | ✅ 已配置 |

### 代码与文档生成

| 模块 | 说明 | 状态 |
|---|---|---|
| 核心功能 | SwiftData 模型、仓库、RampCoach、RepRank、统计、导出 | ✅ 已完成 |
| AI 网关 | Apple 端侧 + GLM 代理 + BYO 六 Provider，Key 存 Keychain | ✅ 已完成 |
| Body Scan | 照片压缩、GLM vision、雷达图、优先级转计划 | ✅ 已完成 |
| 付费墙 | 三档、试用说明、恢复购买、法律链接、自动续费文案 | ✅ 已完成 |
| 单元测试 | 15 个测试覆盖引擎、段位、模板与 AI 校验 | ✅ 全部通过 |
| 政策页面 | landing / support / privacy / terms 已部署 GitHub Pages | ✅ 已完成 |
| App Store 元数据 | `keytext.md` 16 项校验通过 | ✅ 已完成 |
| GitHub 仓库 | https://github.com/asunnyboy861/RepRamp | ✅ 已完成 |

### 💡 使用提示（App 内用户操作，非开发者配置）

- AI 功能：支持 Apple Intelligence（端侧免费，iOS 26+ 真机）；其他设备可在 Settings → AI providers 填入自己的 API Key（GPT / Claude / Gemini / DeepSeek / GLM / 自定义）。
- 用户 API Key 只保存在 iOS Keychain，不会上传或记录日志。

---

## 三、能力检测详情

### Analysis

根据中文指南与 `us.md` 扫描到的关键词：健康 / HealthKit、iCloud / CloudKit、订阅 / Pro / Lifetime、拍照 / 照片（Body Scan），对应能力为 HealthKit、iCloud、StoreKit 2、Camera、Photo Library。未实现 Watch 与 Live Activity（`us.md` 已声明 1.0 不含）。

### No Configuration Needed

- Push Notifications — 本版本不使用远程推送
- Location Services — 未使用
- Background Modes — 仅前台记录
- App Groups / Widgets / Live Activity / Watch — 未实现
- Sign in with Apple — 设计上无账号体系

### Verification

- iOS 26.4 模拟器（iPhone 16）构建成功 ✅
- iPad Air 13-inch（iOS 27.0）构建并运行成功 ✅
- 15 个单元测试通过 ✅
- Bundle ID：`com.zzoutuo.RepRamp` ✅
- 最低版本：iOS 17.0 ✅
- 团队 ID：`JP4TN5PTS3` 已写入工程级设置 ✅
- 真机签名：⏳ 待用户登录 Xcode 后执行 `-allowProvisioningUpdates`（通配描述文件缺少 HealthKit / iCloud）
- 已清理本次使用的模拟器数据 ✅
