import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.startedAt, order: .reverse) private var workouts: [Workout]
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var store = StoreKitManager.shared
    @ObservedObject private var gateway = AIGateway.shared
    @ObservedObject private var healthKit = HealthKitService.shared
    @State private var showPaywall = false
    @State private var showHealthInfo = false
    @State private var healthToggle = false
    @State private var showRevokeAlert = false
    @State private var csvURL: URL?
    @State private var jsonURL: URL?

    private let privacyURL = URL(string: "https://asunnyboy861.github.io/RepRamp/privacy.html")!
    private let termsURL = URL(string: "https://asunnyboy861.github.io/RepRamp/terms.html")!
    private let supportPageURL = URL(string: "https://asunnyboy861.github.io/RepRamp/support.html")!
    private let manageURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    proCard
                    aiSection
                    healthSection
                    dataSection
                    supportSection
                    legalSection
                    aboutSection
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .rampBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.orange)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showHealthInfo) {
                NavigationStack { HealthKitInfoView() }
            }
            .alert("Manage HealthKit access in the Health app", isPresented: $showRevokeAlert) {
                Button("OK", role: .cancel) {
                    healthToggle = true
                }
            } message: {
                Text("iOS does not let apps revoke HealthKit permissions. Open the Health app → profile → Privacy → Apps to change it.")
            }
            .task {
                csvURL = ExportService.makeCSV(workouts: workouts)
                jsonURL = ExportService.makeJSON(workouts: workouts)
                if healthKit.canRequest { await healthKit.refresh() }
                healthToggle = healthKit.isAuthorized
            }
            .onChange(of: healthToggle) { _, newValue in
                if newValue && !healthKit.isAuthorized {
                    Task {
                        await healthKit.requestAuthorization()
                        healthToggle = healthKit.isAuthorized
                    }
                } else if !newValue && healthKit.isAuthorized {
                    showRevokeAlert = true
                }
            }
            .onChange(of: healthKit.isAuthorized) { _, newValue in
                healthToggle = newValue
            }
        }
    }

    private var proCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isPro ? "crown.fill" : "crown")
                    .foregroundStyle(Theme.orange)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.isPro ? "RepRamp Pro" : "Free plan")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(viewModel.isPro ? "All Pro features are unlocked." : "Unlimited logging, plans and stats are included.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            if !viewModel.isPro {
                Button("Upgrade to Pro") { showPaywall = true }
                    .buttonStyle(PrimaryButtonStyle())
            }
            Button("Restore purchases") {
                Task { await store.restorePurchases() }
            }
            .buttonStyle(SecondaryButtonStyle())
            Link("Manage subscription", destination: manageURL)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            if let message = store.purchaseMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardStyle(padding: 20)
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "AI providers", subtitle: gateway.statusBadge)
            NavigationLink(destination: AISettingsView()) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(Theme.orange)
                    Text("Add your own API key")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(14)
                .background(Theme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            Text("Apple Intelligence runs on-device and is free. Cloud AI uses a verified subscription or your own key. Keys are stored in the iOS Keychain and never logged.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle(padding: 20)
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apple Health (HealthKit)")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(Theme.redHealth)
            }
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(Theme.redHealth)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Read sleep and HRV in HealthKit, write workouts via HealthKit")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button("Learn More") { showHealthInfo = true }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.orange)
            }
            .padding(12)
            .background(Theme.surfaceHigh)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Toggle("Sync workouts to HealthKit", isOn: $healthToggle)
                .tint(Theme.orange)
                .foregroundStyle(Theme.textPrimary)

            Text("RepRamp reads sleep, HRV, resting heart rate and body weight through HealthKit to adjust today's intensity, and it writes completed workouts back. This requires your explicit permission and never blocks logging. Revoke access anytime in the Health app.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle(padding: 20)
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your data", subtitle: "Local-first. Export anytime.")
            if let csvURL {
                ShareLink(item: csvURL) {
                    dataRow(icon: "square.and.arrow.up", title: "Export CSV", subtitle: "Spreadsheet-friendly log")
                }
            } else {
                Text("Log your first workout to unlock export.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            if let jsonURL {
                ShareLink(item: jsonURL) {
                    dataRow(icon: "doc.text", title: "Export JSON", subtitle: "Complete lossless backup")
                }
            }
            Text("Export includes deleted sets and warmups so nothing is lost.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle(padding: 20)
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Support", subtitle: "We read every message.")
            NavigationLink(destination: ContactSupportView()) {
                dataRow(icon: "envelope.fill", title: "Contact Support", subtitle: "Send feedback or report a bug")
            }
            .buttonStyle(.plain)
        }
        .cardStyle(padding: 20)
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Legal")
            Link("Privacy Policy", destination: privacyURL)
            Link("Terms of Use (EULA)", destination: termsURL)
            Link("Support Page", destination: supportPageURL)
        }
        .font(.subheadline)
        .foregroundStyle(Theme.orange)
        .cardStyle(padding: 20)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.versionText)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Text("RepRamp provides general fitness guidance, not medical advice. Always train within your limits and consult a professional when in doubt.")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 20)
    }

    private func dataRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(Theme.surfaceHigh)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
