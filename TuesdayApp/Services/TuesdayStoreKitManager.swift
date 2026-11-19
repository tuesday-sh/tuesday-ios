import Foundation
import StoreKit

public struct SubscriptionPlanOffer: Identifiable, Equatable {
    public var id: String { productId }
    public let productId: String
    public let title: String
    public let formattedPrice: String
    public let periodLabel: String
    public let badge: String?

    public init(
        productId: String,
        title: String,
        formattedPrice: String,
        periodLabel: String,
        badge: String? = nil
    ) {
        self.productId = productId
        self.title = title
        self.formattedPrice = formattedPrice
        self.periodLabel = periodLabel
        self.badge = badge
    }
}

/// Real Apple StoreKit 2 subscription manager handling product loading (`sh.tuesday.pro.tier1.*`),
/// interactive purchase flows, background `Transaction.updates` verification, Restore Purchases (`AppStore.sync`),
/// and backend entitlement verification (`POST /api/v1/billing/verify`).
@MainActor
public final class TuesdayStoreKitManager: ObservableObject {
    nonisolated public static let skuProTier1Annual = "sh.tuesday.pro.tier1.annual"
    nonisolated public static let skuProTier1Monthly = "sh.tuesday.pro.tier1.monthly"
    nonisolated public static let supportedSkus = [skuProTier1Annual, skuProTier1Monthly]

    nonisolated public static func defaultPlanOffers() -> [SubscriptionPlanOffer] {
        [
            SubscriptionPlanOffer(
                productId: skuProTier1Annual,
                title: "Annual",
                formattedPrice: "$49.00",
                periodLabel: "/ year",
                badge: "SAVE 18%"
            ),
            SubscriptionPlanOffer(
                productId: skuProTier1Monthly,
                title: "Monthly",
                formattedPrice: "$4.99",
                periodLabel: "/ month",
                badge: nil
            )
        ]
    }

    @Published public var plans: [SubscriptionPlanOffer] = TuesdayStoreKitManager.defaultPlanOffers()
    @Published public var selectedProductId: String = TuesdayStoreKitManager.skuProTier1Annual
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var isPurchasing: Bool = false
    @Published public private(set) var isRestoring: Bool = false
    @Published public var statusMessage: String?

    private weak var repository: MockHacsTuesdayService?
    private var productsById: [String: Product] = [:]
    private var transactionListenerTask: Task<Void, Never>?

    public init(repository: MockHacsTuesdayService) {
        self.repository = repository
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    public func selectPlan(_ productId: String) {
        if Self.supportedSkus.contains(productId) {
            selectedProductId = productId
            statusMessage = nil
        }
    }

    public func clearStatusMessage() {
        statusMessage = nil
    }

    public func start() async {
        startTransactionListenerIfNeeded()
        await loadProducts()
        await reconcileCurrentEntitlements(silent: true)
    }

    private func startTransactionListenerIfNeeded() {
        guard transactionListenerTask == nil else { return }
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                await self.processVerificationResult(result, sourceLabel: "App Store")
            }
        }
    }

    public func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.supportedSkus)
            guard !loaded.isEmpty else {
                isConnected = false
                return
            }

            productsById = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            var updatedOffers: [SubscriptionPlanOffer] = []
            for sku in Self.supportedSkus {
                if let product = productsById[sku] {
                    let isAnnual = (sku == Self.skuProTier1Annual)
                    updatedOffers.append(
                        SubscriptionPlanOffer(
                            productId: product.id,
                            title: isAnnual ? "Annual" : "Monthly",
                            formattedPrice: product.displayPrice,
                            periodLabel: isAnnual ? "/ year" : "/ month",
                            badge: isAnnual ? "SAVE 18%" : nil
                        )
                    )
                }
            }
            if !updatedOffers.isEmpty {
                plans = updatedOffers
                isConnected = true
            }
        } catch {
            isConnected = false
        }
    }

    @discardableResult
    public func purchase(productId: String? = nil) async -> Bool {
        let targetSku = productId.flatMap { Self.supportedSkus.contains($0) ? $0 : nil } ?? selectedProductId
        selectedProductId = targetSku
        isPurchasing = true
        statusMessage = nil

        defer { isPurchasing = false }

        if productsById[targetSku] == nil {
            await loadProducts()
        }

        guard let product = productsById[targetSku] else {
            #if DEBUG
            if let repo = repository, (CommandLine.arguments.contains("--uitesting-mock-billing") || repo.isDeveloperMode) {
                let unlocked = repo.upgradeToProTier1(productId: targetSku, transactionJws: nil)
                statusMessage = unlocked ? "✓ Activated Pro Tier 1 (Debug Sandbox)" : "⚠️ StoreKit products unavailable."
                return unlocked
            }
            #endif
            statusMessage = "⚠️ App Store subscription products are currently unavailable."
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                return await processVerificationResult(verificationResult, sourceLabel: "Apple App Store")
            case .userCancelled:
                statusMessage = "Purchase canceled."
                return false
            case .pending:
                statusMessage = "⏳ Purchase is pending App Store authorization."
                return false
            @unknown default:
                statusMessage = "⚠️ Unknown purchase state."
                return false
            }
        } catch {
            statusMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    public func restorePurchases() async {
        isRestoring = true
        statusMessage = "Checking App Store & Tuesday.sh entitlement..."
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
        } catch {
            // Continue into currentEntitlements + server check even if AppStore.sync hits sandbox hiccup
        }

        let foundLocal = await reconcileCurrentEntitlements(silent: false)
        if !foundLocal, let repo = repository {
            let serverTier = await repo.fetchServerEntitlementStatus()
            if EntitlementGatePolicy.isProTier1Entitled(serverTier) {
                statusMessage = "✓ Restored Pro Tier 1 entitlement from server"
            } else {
                statusMessage = "No active Pro Tier 1 subscription found for this Apple Account."
            }
        }
    }

    @discardableResult
    public func reconcileCurrentEntitlements(silent: Bool) async -> Bool {
        var foundVerified = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               Self.supportedSkus.contains(tx.productID),
               tx.revocationDate == nil {
                _ = await processVerificationResult(result, sourceLabel: silent ? "silent launch check" : "App Store restore")
                foundVerified = true
                break
            }
        }

        if !foundVerified {
            await repository?.reconcileWhenStoreHasNoActivePurchase()
        }
        return foundVerified
    }

    @discardableResult
    private func processVerificationResult(
        _ verificationResult: VerificationResult<Transaction>,
        sourceLabel: String
    ) async -> Bool {
        switch verificationResult {
        case .verified(let transaction):
            guard Self.supportedSkus.contains(transaction.productID) else {
                await transaction.finish()
                return false
            }
            guard transaction.revocationDate == nil else {
                repository?.downgradeToFreeTier()
                await transaction.finish()
                return false
            }

            let jws = verificationResult.jwsRepresentation
            _ = repository?.upgradeToProTier1(productId: transaction.productID, transactionJws: jws)
            await transaction.finish()
            statusMessage = "✓ Pro Tier 1 active via \(sourceLabel)"
            return true

        case .unverified(_, let error):
            statusMessage = "⚠️ Could not verify Apple receipt signature (\(error.localizedDescription))."
            return false
        }
    }
}
