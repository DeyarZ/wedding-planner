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

    // MARK: - Cross-promo (Everlens)
    /// Everlens — the studio's disposable-camera app for wedding guests
    /// (`com.wizarddynamics.eventcam`). See `EverlensPromo`.
    static let everlensAppStoreID = "6775506628"
    /// Account-wide App Store provider token. Campaign links need it for the
    /// `ct=` token to show up in App Analytics → Sources → Campaigns.
    static let appStoreProviderToken = "127508914"

    // MARK: - Product IDs (App Store Connect)
    //
    // These constants exist for tooling, debugging and the pricing runbook only.
    // The paywall itself NEVER filters on a product identifier — it renders
    // whatever the current RevenueCat offering contains, keyed by package type
    // (see `SubscriptionManager.PlanKind`). That is what makes RC-native A/B
    // testing possible without shipping a build.

    /// New ladder (Phase 1). Created in App Store Connect + attached to the
    /// `default` RevenueCat offering by a human — see `PRICING-FLIP.md`.
    static let annualProductID = "com.manuelworlitzer.weddingplanner.premium.annual"
    static let lifetimeProductID = "com.manuelworlitzer.weddingplanner.premium.lifetime"
    static let monthlyProductID = "com.manuelworlitzer.weddingplanner.premium.monthly"

    /// LEGACY — the two SKUs that are live today. After the pricing flip these
    /// leave the main paywall: weekly becomes the dismissal rescue SKU and the
    /// 6-month plan becomes the dismissal discount offer (Phase 4).
    static let weeklyProductID = "com.manuelworlitzer.weddingplanner.premium.weekly"
    static let sixMonthProductID = "com.manuelworlitzer.weddingplanner.premium.6months"

    // MARK: - Trial
    /// Single source of truth for the free-trial length shown on the paywall and
    /// used to schedule trial reminders. Only a fallback: when RevenueCat has the
    /// product loaded, the introductory offer period on the StoreProduct wins
    /// (see `SubscriptionManager.trialDurationDays`).
    static let fallbackTrialDays = 3
}
