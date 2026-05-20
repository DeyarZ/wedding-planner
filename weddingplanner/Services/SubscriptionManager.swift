import Foundation
import RevenueCat
import FacebookCore

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var isSubscribed: Bool {
        customerInfo?.entitlements[Config.premiumEntitlementID]?.isActive == true
    }

    var weeklyPackage: Package? {
        offerings?.current?.availablePackages.first {
            $0.storeProduct.productIdentifier == Config.weeklyProductID
        }
    }

    var sixMonthPackage: Package? {
        offerings?.current?.availablePackages.first {
            $0.storeProduct.productIdentifier == Config.sixMonthProductID
        }
    }

    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: Config.revenueCatAPIKey)
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        Purchases.shared.attribution.collectDeviceIdentifiers()
    }

    private override init() {
        super.init()
        Purchases.shared.delegate = self
        Task {
            await loadOfferings()
            await updateSubscriptionStatus()
        }
    }

    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("[SubscriptionManager] Failed to load offerings: \(error)")
        }
    }

    func updateSubscriptionStatus() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            print("[SubscriptionManager] Failed to update status: \(error)")
        }
    }

    func purchase(_ package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo

            if !result.userCancelled {
                if !isSubscribed {
                    await updateSubscriptionStatus()
                }

                let product = package.storeProduct
                let priceDouble = NSDecimalNumber(decimal: product.price).doubleValue
                let currencyCode = product.currencyCode ?? "USD"
                if hasFreeTrial(for: product) {
                    Singular.event(EVENT_SNG_START_TRIAL)
                    AppEvents.shared.logEvent(
                        .startTrial,
                        valueToSum: priceDouble,
                        parameters: [.currency: currencyCode]
                    )
                } else {
                    Singular.event(EVENT_SNG_SUBSCRIBE)
                    AppEvents.shared.logPurchase(amount: priceDouble, currency: currencyCode)
                }

                isLoading = false
                return true
            }

            isLoading = false
            return false
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            print("[SubscriptionManager] Purchase failed: \(error)")
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            customerInfo = try await Purchases.shared.restorePurchases()
            isLoading = false
            if !isSubscribed {
                errorMessage = "No active subscription found on this Apple ID."
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
            print("[SubscriptionManager] Restore failed: \(error)")
        }
    }

    func hasFreeTrial(for product: StoreProduct) -> Bool {
        guard let introDiscount = product.introductoryDiscount else { return false }
        return introDiscount.paymentMode == .freeTrial
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            self?.customerInfo = customerInfo
        }
    }
}
