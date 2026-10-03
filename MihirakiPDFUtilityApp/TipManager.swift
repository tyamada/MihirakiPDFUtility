import Observation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class TipManager {
    enum PurchaseOutcome: Equatable {
        case success
        case pending
        case cancelled
        case failed(String)
    }

    enum RestoreOutcome: Equatable {
        case restored
        case noPurchases
        case failed(String)
    }

    static let productIDs = [
        "supporter_icon_bronze_ut",
        "supporter_icon_silver_ut",
        "supporter_icon_gold_ut"
    ]

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var isRestoring = false
    private(set) var hasLoadedProducts = false
    private(set) var errorMessage: String?

    private var transactionUpdates: Task<Void, Never>?

    init(listenForTransactions: Bool = true) {
        guard listenForTransactions else { return }

        transactionUpdates = Task { [weak self] in
            for await verification in Transaction.updates {
                guard case let .verified(transaction) = verification else { continue }
                await self?.refreshPurchasedProducts()
                await transaction.finish()
                self?.errorMessage = nil
            }
        }
    }

    isolated deinit {
        transactionUpdates?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoadedProducts = true
        }

        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            await refreshPurchasedProducts()
            errorMessage = products.isEmpty
                ? String(localized: "Could not load support options. Please try again later.")
                : nil
        } catch {
            products = []
            errorMessage = String(
                localized: "Could not load support options. Please try again later."
            )
        }
    }

    func purchase(
        _ product: Product,
        using purchaseAction: PurchaseAction
    ) async -> PurchaseOutcome {
        do {
            switch try await purchaseAction(product) {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                    errorMessage = nil
                    return .success
                case .unverified:
                    let message = String(localized: "Could not verify the purchase.")
                    errorMessage = message
                    return .failed(message)
                }
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                let message = String(localized: "The purchase could not be completed.")
                errorMessage = message
                return .failed(message)
            }
        } catch {
            let message = String(localized: "The purchase could not be completed.")
            errorMessage = message
            return .failed(message)
        }
    }

    func restorePurchases() async -> RestoreOutcome {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
            return purchasedProductIDs.isEmpty ? .noPurchases : .restored
        } catch {
            let message = String(localized: "Purchases could not be restored.")
            return .failed(message)
        }
    }

    func isPurchased(_ product: Product) -> Bool {
        purchasedProductIDs.contains(product.id)
    }

    private func refreshPurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await verification in Transaction.currentEntitlements {
            guard case let .verified(transaction) = verification,
                  Self.productIDs.contains(transaction.productID) else {
                continue
            }

            purchasedIDs.insert(transaction.productID)
        }

        purchasedProductIDs = purchasedIDs
    }

    func clearError() {
        errorMessage = nil
    }
}
