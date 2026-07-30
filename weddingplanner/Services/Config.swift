import Foundation

enum Config {
    // MARK: - RevenueCat
    static let revenueCatAPIKey = "appl_vjZKEFBMhudkcRJzNaBjnzSbfUC"
    static let premiumEntitlementID = "premium"

    // MARK: - Singular
    static let singularAPIKey = "worlitzer_53424d7f"
    static let singularSecret = "4c3833fbe4a45809e6ffe2fbf01d5e4b"

    // MARK: - Meta (Facebook) SDK
    static let metaAppID = "1413776300508426"
    static let metaClientToken = "3a173ed5eb51014146764c434c062299"

    // MARK: - Support
    static let supportEmail = "m.worlitzer@gmx.de"

    // MARK: - Product IDs (App Store Connect)
    static let weeklyProductID = "com.manuelworlitzer.weddingplanner.premium.weekly"
    static let sixMonthProductID = "com.manuelworlitzer.weddingplanner.premium.6months"

    // MARK: - Trial
    /// Single source of truth for the free-trial length shown on the paywall and
    /// used to schedule trial reminders. Only a fallback: when RevenueCat has the
    /// product loaded, the introductory offer period on the StoreProduct wins
    /// (see `SubscriptionManager.trialDurationDays`).
    static let fallbackTrialDays = 3

    /// Billing periods per year used to derive the "per week" equivalent price
    /// of the 6-month plan (26 weeks in 6 months).
    static let weeksInSixMonths = 26
}
