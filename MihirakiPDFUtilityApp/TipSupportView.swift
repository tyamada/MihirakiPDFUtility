import StoreKit
import SwiftUI

struct TipSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.purchase) private var purchaseAction
    @Bindable var tipManager: TipManager

    @State private var purchasingProductID: String?
    @State private var isShowingThankYou = false
    @State private var isShowingPendingMessage = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    productContent
                } header: {
                    Text("Supporter Icons")
                } footer: {
                    Text("Supporter icons are optional, one-time purchases. All PDF editing features remain available without a purchase.")
                }

                Section {
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .disabled(tipManager.isRestoring || purchasingProductID != nil)
                } footer: {
                    if tipManager.isRestoring {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Restoring purchases…")
                        }
                    }
                }
            }
            .navigationTitle("Supporter Icons")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if tipManager.products.isEmpty {
                    await tipManager.loadProducts()
                }
            }
            .alert("Thank You!", isPresented: $isShowingThankYou) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your supporter icon is now available.")
            }
            .alert("Purchase Pending", isPresented: $isShowingPendingMessage) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The purchase is waiting for approval.")
            }
            .alert(
                "Restore Purchases",
                isPresented: Binding(
                    get: { restoreMessage != nil },
                    set: { if !$0 { restoreMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var productContent: some View {
        if let errorMessage = tipManager.errorMessage {
            ContentUnavailableView {
                Label("Unable to Load Support Options", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try Again") {
                    tipManager.clearError()
                    Task { await tipManager.loadProducts() }
                }
            }
        } else if tipManager.isLoading || !tipManager.hasLoadedProducts {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else {
            ForEach(tipManager.products) { product in
                Button {
                    purchase(product)
                } label: {
                    HStack(spacing: 12) {
                        Image(supporterIcon(for: product.id)?.assetName ?? "TipBronze")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(.rect(cornerRadius: 10))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if tipManager.isPurchased(product) {
                            Label("Purchased", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                        } else if purchasingProductID == product.id {
                            ProgressView()
                        } else {
                            Text(product.displayPrice)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .disabled(purchasingProductID != nil || tipManager.isPurchased(product))
                .accessibilityIdentifier("tipProductButton_\(product.id)")
            }
        }
    }

    private func supporterIcon(for productID: String) -> TipManager.SupporterIcon? {
        TipManager.SupporterIcon(rawValue: productID)
    }

    private func purchase(_ product: Product) {
        purchasingProductID = product.id

        Task {
            let outcome = await tipManager.purchase(product, using: purchaseAction)
            purchasingProductID = nil

            switch outcome {
            case .success:
                isShowingThankYou = true
            case .pending:
                isShowingPendingMessage = true
            case .cancelled, .failed:
                break
            }
        }
    }

    private func restorePurchases() {
        Task {
            switch await tipManager.restorePurchases() {
            case .restored:
                restoreMessage = String(localized: "Your supporter icons have been restored.")
            case .noPurchases:
                restoreMessage = String(localized: "No purchases were found to restore.")
            case let .failed(message):
                restoreMessage = message
            }
        }
    }
}
