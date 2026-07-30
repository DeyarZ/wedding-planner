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

    // MARK: - Offering / package access
    //
    // Everything below is keyed by *package type*, never by product identifier.
    // That is deliberate: the paywall renders whatever the current RevenueCat
    // offering contains, so pricing and the SKU ladder can be changed (and
    // A/B tested) from the RevenueCat dashboard without shipping a build.

    /// The offering RevenueCat currently serves this user.
    var currentOffering: Offering? { offerings?.current }

    /// A specific offering by identifier — used for the secondary surfaces
    /// (dismissal / win-back) that do not run off `current`.
    func offering(_ identifier: String) -> Offering? {
        offerings?.offering(identifier: identifier)
    }

    /// Packages of the current offering in paywall display order:
    /// annual → forever → monthly → 6-month → 3-month → weekly → anything else.
    var availablePackages: [Package] {
        guard let packages = currentOffering?.availablePackages else { return [] }
        return packages.sorted { lhs, rhs in
            let l = Self.planKind(for: lhs).displayOrder
            let r = Self.planKind(for: rhs).displayOrder
            if l != r { return l < r }
            return lhs.storeProduct.productIdentifier < rhs.storeProduct.productIdentifier
        }
    }

    /// First package of the current offering matching `kind`, if any.
    func package(_ kind: PlanKind) -> Package? {
        availablePackages.first { Self.planKind(for: $0) == kind }
    }

    /// The package that should come pre-selected on the paywall. Front-loads
    /// cash: annual wins, then the one-time "Forever", then the longest
    /// remaining subscription. Falls back to whatever the offering has.
    var defaultPackage: Package? {
        for kind in PlanKind.selectionPriority {
            if let package = package(kind) { return package }
        }
        return availablePackages.first
    }

    // MARK: - Plan kinds

    /// Normalised plan duration, derived from the RevenueCat package type with
    /// a fallback to the StoreProduct's own subscription period. The fallback
    /// matters for `.custom` packages — a one-time "Forever" product attached
    /// to a custom package still has to be recognised as lifetime.
    enum PlanKind: Hashable {
        case annual
        case lifetime
        case monthly
        case sixMonth
        case threeMonth
        case weekly
        case other

        /// Order the cards appear in on the paywall.
        var displayOrder: Int {
            switch self {
            case .annual: return 0
            case .lifetime: return 1
            case .monthly: return 2
            case .sixMonth: return 3
            case .threeMonth: return 4
            case .weekly: return 5
            case .other: return 6
            }
        }

        /// Which plan is pre-selected, best first.
        static let selectionPriority: [PlanKind] = [.annual, .lifetime, .sixMonth, .threeMonth, .monthly, .weekly]

        /// Which plan carries the "BEST VALUE" badge, best first.
        static let bestValuePriority: [PlanKind] = [.annual, .lifetime, .sixMonth]

        /// Stable slug for analytics.
        var analyticsName: String {
            switch self {
            case .annual: return "annual"
            case .lifetime: return "lifetime"
            case .monthly: return "monthly"
            case .sixMonth: return "six_month"
            case .threeMonth: return "three_month"
            case .weekly: return "weekly"
            case .other: return "other"
            }
        }
    }

    nonisolated static func planKind(for package: Package) -> PlanKind {
        switch package.packageType {
        case .annual: return .annual
        case .lifetime: return .lifetime
        case .sixMonth: return .sixMonth
        case .monthly: return .monthly
        case .weekly: return .weekly
        default: return planKind(for: package.storeProduct)
        }
    }

    /// Fallback classification straight off the product: a product without a
    /// subscription period is a one-time purchase, i.e. "Forever".
    nonisolated static func planKind(for product: StoreProduct) -> PlanKind {
        guard let period = product.subscriptionPeriod else { return .lifetime }
        switch period.unit {
        case .year:
            return .annual
        case .month:
            switch period.value {
            case 1: return .monthly
            case 2, 3: return .threeMonth
            case 6: return .sixMonth
            case 12...: return .annual
            default: return .other
            }
        case .week, .day:
            return (days(in: period) ?? 7) <= 10 ? .weekly : .other
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

    /// Free-trial length in days for one specific package, read from its
    /// introductory offer. `nil` means this package has no free trial — which
    /// is a first-class state: the trial-vs-no-trial A/B runs by swapping the
    /// RevenueCat offering, so the paywall must render both without a rebuild.
    nonisolated static func trialDays(for package: Package) -> Int? {
        trialDays(for: package.storeProduct)
    }

    nonisolated static func trialDays(for product: StoreProduct) -> Int? {
        guard let intro = product.introductoryDiscount,
              intro.paymentMode == .freeTrial,
              let days = days(in: intro.subscriptionPeriod),
              days > 0 else { return nil }
        return days
    }

    /// The trial length that drives app-level logic (reminder scheduling, trial
    /// copy outside the paywall). Reads the default (pre-selected) package
    /// first, then anything else in the offering that has a trial, and only
    /// falls back to `Config.fallbackTrialDays` before offerings have loaded.
    /// Everything that talks about "the trial" must go through this so the app
    /// can never contradict the App Store.
    var trialDurationDays: Int {
        if let package = defaultPackage, let days = Self.trialDays(for: package) {
            return days
        }
        for package in availablePackages {
            if let days = Self.trialDays(for: package) { return days }
        }
        return Config.fallbackTrialDays
    }

    private nonisolated static func days(in period: RevenueCat.SubscriptionPeriod) -> Int? {
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        }
    }

    // MARK: - Pricing helpers

    /// Number of whole weeks in a product's billing period, rounded to the
    /// nearest week (year → 52, 6 months → 26, month → 4). `nil` for one-time
    /// products, which have no billing period to divide by.
    nonisolated static func weeksInBillingPeriod(of product: StoreProduct) -> Int? {
        guard let period = product.subscriptionPeriod,
              let days = days(in: period), days >= 7 else { return nil }
        return Int((Double(days) / 7.0).rounded())
    }

    /// Locale-aware "per week" equivalent for any recurring product, derived
    /// from its own billing period. `nil` when the product is one-time or the
    /// period is shorter than a week (the price already IS the weekly price).
    nonisolated static func localizedPricePerWeek(for product: StoreProduct) -> String? {
        guard let weeks = weeksInBillingPeriod(of: product), weeks > 1 else { return nil }
        return localizedPricePerWeek(for: product, weeks: weeks)
    }

    /// Locale-aware "per week" equivalent for a multi-week product.
    /// Uses the product's own price (Decimal) and price formatter, so it is
    /// correct in every currency — never parse the localized price string.
    nonisolated static func localizedPricePerWeek(for product: StoreProduct, weeks: Int) -> String? {
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
