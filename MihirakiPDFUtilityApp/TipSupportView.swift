import StoreKit
import SwiftUI

struct TipSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.purchase) private var purchaseAction
    @Bindable var tipManager: TipManager

    @State private var purchasingProductID: String?
    @State private var isShowingThankYou = false
    @State private var isShowingPendingMessage = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    productContent
                } header: {
                    Text("Support the Developer")
                } footer: {
                    Text("Your support helps keep the app updated. You can use all features without making a purchase.")
                }
            }
            .navigationTitle("Support")
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
            .alert("Thank You for Your Support!", isPresented: $isShowingThankYou) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thank you for your support.")
            }
            .alert("Purchase Pending", isPresented: $isShowingPendingMessage) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The purchase is waiting for approval.")
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
                        Image(systemName: "heart.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.pink)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName(for: product.id))
                                .font(.headline)
                            Text("A one-time consumable purchase")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if purchasingProductID == product.id {
                            ProgressView()
                        } else {
                            Text(product.displayPrice)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .disabled(purchasingProductID != nil)
                .accessibilityIdentifier("tipProductButton_\(product.id)")
            }
        }
    }

    private func displayName(for productID: String) -> LocalizedStringResource {
        switch productID {
        case "tip_100": "Small Support"
        case "tip_500": "Medium Support"
        case "tip_1000": "Large Support"
        default: "Support"
        }
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
}
