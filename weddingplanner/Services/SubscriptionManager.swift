import Foundation
import RevenueCat
import FacebookCore
import Singular

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
                    Singular.customRevenue(
                        EVENT_SNG_START_TRIAL,
                        currency: currencyCode,
                        amount: priceDouble
                    )
                } else {
                    Singular.customRevenue(
                        EVENT_SNG_SUBSCRIBE,
                        currency: currencyCode,
                        amount: priceDouble
                    )
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

    // MARK: - Trial length

    /// The real free-trial length in days, read from the introductory offer on
    /// the StoreProduct. Falls back to `Config.fallbackTrialDays` when offerings
    /// have not loaded yet. Everything that talks about the trial (copy,
    /// reminders) must go through this so the app can never contradict itself.
    var trialDurationDays: Int {
        let products = [weeklyPackage?.storeProduct, sixMonthPackage?.storeProduct].compactMap { $0 }
        for product in products {
            guard let intro = product.introductoryDiscount,
                  intro.paymentMode == .freeTrial else { continue }
            if let days = Self.days(in: intro.subscriptionPeriod), days > 0 {
                return days
            }
        }
        return Config.fallbackTrialDays
    }

    private static func days(in period: RevenueCat.SubscriptionPeriod) -> Int? {
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        }
    }

    // MARK: - Pricing helpers

    /// Locale-aware "per week" equivalent for a multi-week product.
    /// Uses the product's own price (Decimal) and price formatter, so it is
    /// correct in every currency — never parse the localized price string.
    static func localizedPricePerWeek(for product: StoreProduct, weeks: Int) -> String? {
        guard weeks > 0 else { return nil }
        let perWeek = NSDecimalNumber(decimal: product.price)
            .dividing(by: NSDecimalNumber(value: weeks))

        if let formatter = product.priceFormatter,
           let formatted = formatter.string(from: perWeek) {
            return formatted
        }

        let fallback = NumberFormatter()
        fallback.numberStyle = .currency
        fallback.locale = .current
        if let currencyCode = product.currencyCode {
            fallback.currencyCode = currencyCode
        }
        return fallback.string(from: perWeek)
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            self?.customerInfo = customerInfo
        }
    }
}
