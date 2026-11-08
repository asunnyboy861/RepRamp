import Foundation
import StoreKit
import Combine

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    nonisolated static let monthlyID = "com.zzoutuo.RepRamp.pro.monthly"
    nonisolated static let yearlyID = "com.zzoutuo.RepRamp.pro.yearly"
    nonisolated static let lifetimeID = "com.zzoutuo.RepRamp.pro.lifetime"
    nonisolated static let productIDs = [monthlyID, yearlyID, lifetimeID]

    @Published var isPro = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var purchaseMessage: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlements() }
    }

    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var yearly: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetime: Product? { products.first { $0.id == Self.lifetimeID } }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs)
            if products.isEmpty {
                loadError = "Products are not available yet."
            } else {
                loadError = nil
            }
        } catch {
            loadError = "Unable to load purchase options right now."
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    purchaseMessage = "Purchase complete. Pro is unlocked."
                    return true
                case .unverified:
                    purchaseMessage = "Purchase could not be verified."
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                purchaseMessage = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseMessage = isPro ? "Purchases restored. Pro is unlocked." : "No previous purchase was found."
        } catch {
            purchaseMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var entitled = false
        for id in Self.productIDs {
            if let result = await Transaction.currentEntitlement(for: id) {
                if case .verified(let transaction) = result, transaction.revocationDate == nil {
                    entitled = true
                }
            }
        }
        isPro = entitled
    }

    func entitlementJWS() async -> String? {
        for id in Self.productIDs {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                return result.jwsRepresentation
            }
        }
        return nil
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
