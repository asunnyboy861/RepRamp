import SwiftUI
import UIKit

struct AISettingsView: View {
    @ObservedObject private var gateway = AIGateway.shared
    @State private var provider: BYOProvider = .openai
    @State private var apiKey = ""
    @State private var model = BYOProvider.openai.defaultModel
    @State private var baseURL = BYOProvider.openai.defaultBaseURL
    @State private var testResult: String?
    @State private var errorMessage: String?
    @State private var isTesting = false
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                engineStatusCard
                providerCard
                credentialsCard
                actionsCard
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .navigationTitle("AI Providers")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExisting)
    }

    private var engineStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Current engine", subtitle: gateway.statusBadge)
            statusRow(
                icon: "cpu",
                title: "Apple Intelligence",
                detail: AppleIntelligenceEngine.isAvailable ? "Available on this device (on-device, free)" : "Requires iOS 26 and iPhone 15 Pro or newer",
                isOn: AppleIntelligenceEngine.isAvailable
            )
            statusRow(
                icon: "cloud",
                title: "GLM (official proxy)",
                detail: GLMProxyEngine.isConfigured ? "Proxy credential present" : "Paired with a Pro subscription at runtime",
                isOn: GLMProxyEngine.isConfigured
            )
            statusRow(
                icon: "key",
                title: "Your own key",
                detail: gateway.hasBYO ? "Configured" : "Not configured",
                isOn: gateway.hasBYO
            )
        }
        .cardStyle(padding: 20)
    }

    private func statusRow(icon: String, title: String, detail: String, isOn: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(isOn ? Theme.success : Theme.textTertiary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Provider", subtitle: "Keys stay in the iOS Keychain.")
            ForEach(BYOProvider.allCases) { option in
                Button {
                    provider = option
                    model = option.defaultModel
                    baseURL = option.defaultBaseURL
                    testResult = nil
                } label: {
                    HStack {
                        Circle()
                            .fill(providerColor(option))
                            .frame(width: 10, height: 10)
                        Text(option.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if !option.supportsVision {
                            Text("TEXT ONLY")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.warning)
                        }
                        Spacer()
                        if provider == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.orange)
                        }
                    }
                    .padding(12)
                    .background(provider == option ? Theme.orange.opacity(0.12) : Theme.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(provider == option ? .isSelected : [])
            }
        }
        .cardStyle(padding: 20)
    }

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API key")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                SecureField("Paste your API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Theme.surfaceHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Paste") {
                    if let pasted = UIPasteboard.general.string {
                        apiKey = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.orange)
            }

            Text("Model")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextField("Model name", text: $model)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Base URL")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextField("https://...", text: $baseURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(12)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !provider.supportsVision {
                Text("This provider is text-only. Body Scan and screenshot import need a vision-capable provider.")
                    .font(.caption2)
                    .foregroundStyle(Theme.warning)
            }

            if let testResult {
                Text(testResult)
                    .font(.caption)
                    .foregroundStyle(Theme.success)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.warning)
            }
        }
        .cardStyle(padding: 20)
    }

    private var actionsCard: some View {
        VStack(spacing: 10) {
            Button {
                Task { await testConnection() }
            } label: {
                HStack {
                    if isTesting { ProgressView().tint(.white) }
                    Text(isTesting ? "Testing..." : "Test connection")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(apiKey.isEmpty || isTesting)

            Button("Save configuration") { save() }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(apiKey.isEmpty)

            if gateway.hasBYO {
                Button("Remove saved key") {
                    gateway.clearConfig()
                    apiKey = ""
                    testResult = nil
                    saved = false
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            }

            if saved {
                Text("Saved. Cloud AI now uses your key with no limits from RepRamp.")
                    .font(.caption)
                    .foregroundStyle(Theme.success)
            }
            Text("BYO keys bypass our proxy entirely. Your provider bill is between you and the provider.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle(padding: 20)
    }

    private func loadExisting() {
        guard let config = gateway.byoConfig else { return }
        provider = config.provider
        apiKey = config.apiKey
        model = config.model
        baseURL = config.baseURL
    }

    private func currentConfig() -> BYOConfig {
        BYOConfig(provider: provider, apiKey: apiKey, model: model.isEmpty ? provider.defaultModel : model, baseURL: baseURL)
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil
        errorMessage = nil
        do {
            testResult = try await gateway.testConnection(currentConfig())
        } catch {
            errorMessage = error.localizedDescription
        }
        isTesting = false
    }

    private func save() {
        let config = currentConfig()
        guard !config.apiKey.isEmpty else {
            errorMessage = "Enter an API key first."
            return
        }
        if config.provider == .custom && config.baseURL.isEmpty {
            errorMessage = "Custom providers need a full endpoint URL."
            return
        }
        gateway.saveConfig(config)
        saved = true
        errorMessage = nil
    }

    private func providerColor(_ provider: BYOProvider) -> Color {
        switch provider {
        case .openai: return Color(red: 0.35, green: 0.75, blue: 0.60)
        case .anthropic: return Color(red: 0.90, green: 0.55, blue: 0.30)
        case .gemini: return Color(red: 0.40, green: 0.65, blue: 1.0)
        case .deepseek: return Color(red: 0.45, green: 0.55, blue: 1.0)
        case .glm: return Color(red: 0.55, green: 0.85, blue: 0.35)
        case .custom: return Theme.textSecondary
        }
    }
}
