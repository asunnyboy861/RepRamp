import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = StoreKitManager.shared
    @State private var selection: Tier = .yearly
    @State private var isPurchasing = false

    private let privacyURL = URL(string: "https://asunnyboy861.github.io/RepRamp/privacy.html")!
    private let termsURL = URL(string: "https://asunnyboy861.github.io/RepRamp/terms.html")!
    private let supportURL = URL(string: "https://asunnyboy861.github.io/RepRamp/support.html")!
    private let manageURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    enum Tier: String, CaseIterable, Identifiable {
        case monthly, yearly, lifetime
        var id: String { rawValue }

        var title: String {
            switch self {
            case .monthly: return "Pro Monthly"
            case .yearly: return "Pro Annual"
            case .lifetime: return "Lifetime"
            }
        }

        var length: String {
            switch self {
            case .monthly: return "1 month"
            case .yearly: return "1 year"
            case .lifetime: return "One-time purchase"
            }
        }

        var fallbackPrice: String {
            switch self {
            case .monthly: return "$6.99"
            case .yearly: return "$39.99"
            case .lifetime: return "$79.99"
            }
        }

        var productID: String {
            switch self {
            case .monthly: return StoreKitManager.monthlyID
            case .yearly: return StoreKitManager.yearlyID
            case .lifetime: return StoreKitManager.lifetimeID
            }
        }

        var footnote: String {
            switch self {
            case .monthly: return "Cancel anytime"
            case .yearly: return "7-day free trial · best value"
            case .lifetime: return "Pay once, own it forever"
            }
        }
    }

    private var selectedProduct: Product? {
        store.products.first { $0.id == selection.productID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                featureList
                tierCards
                purchaseSection
                legalSection
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .rampBackground()
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            .padding(16)
            .accessibilityLabel("Close paywall")
        }
        .task {
            if store.products.isEmpty { await store.loadProducts() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REPRAMP PRO")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(Theme.orange)
            Text("Show me the math. Then show me the muscles.")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Unlimited logging is always free. Pro adds cloud AI coaching, Body Scan and screenshot imports.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 20)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow(icon: "viewfinder", text: "AI Body Scan with muscle balance radar")
            featureRow(icon: "sparkles", text: "Cloud AI plans and screenshot-to-plan import")
            featureRow(icon: "infinity", text: "Unlimited cloud AI requests within fair-use limits")
            featureRow(icon: "lock.open", text: "Your data stays yours. Cancel and keep every set.")
            featureRow(icon: "key", text: "Have your own key? Use any provider with no subscription.")
        }
        .cardStyle()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.orange)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    private var tierCards: some View {
        VStack(spacing: 10) {
            ForEach(Tier.allCases) { tier in
                Button {
                    selection = tier
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selection == tier ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selection == tier ? Theme.orange : Theme.textTertiary)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(tier.title)
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                if tier == .yearly {
                                    Text("BEST VALUE")
                                        .font(.caption2.weight(.heavy))
                                        .foregroundStyle(Theme.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(tier.footnote)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(priceText(for: tier))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(16)
                    .background(selection == tier ? Theme.orange.opacity(0.10) : Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selection == tier ? Theme.orange : Theme.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tier ? .isSelected : [])
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await purchase() }
            } label: {
                HStack {
                    if isPurchasing { ProgressView().tint(.white) }
                    Text(purchaseTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isPurchasing || (selectedProduct == nil))
            .opacity((isPurchasing || selectedProduct == nil) ? 0.45 : 1.0)

            if store.products.isEmpty {
                Text("Purchase options are still being configured with the App Store. You can add your own AI key in Settings to use cloud AI in the meantime.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }

            HStack(spacing: 16) {
                Button("Restore purchases") {
                    Task { await store.restorePurchases() }
                }
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                Link("Manage subscription", destination: manageURL)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let message = store.purchaseMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text(autoRenewText)
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: privacyURL)
                Link("Terms of Use", destination: termsURL)
                Link("Support", destination: supportURL)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var purchaseTitle: String {
        if selection == .yearly, selectedProduct?.subscription?.introductoryOffer != nil {
            return "Start 7-day free trial"
        }
        return selection == .lifetime ? "Unlock lifetime" : "Continue"
    }

    private var autoRenewText: String {
        if selection == .lifetime {
            return "One-time purchase. Not a subscription. Lifetime unlocks the same features as Pro."
        }
        return "Payment is charged to your Apple ID at confirmation. The subscription renews automatically unless canceled at least 24 hours before the end of the current period. The yearly plan includes a 7-day free trial; unused trial time is forfeited after purchase."
    }

    private func priceText(for tier: Tier) -> String {
        if let product = store.products.first(where: { $0.id == tier.productID }) {
            return tier == .lifetime ? product.displayPrice : "\(product.displayPrice) / \(tier.length)"
        }
        return tier == .lifetime ? tier.fallbackPrice : "\(tier.fallbackPrice) / \(tier.length)"
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        let success = await store.purchase(product)
        isPurchasing = false
        if success { dismiss() }
    }
}
