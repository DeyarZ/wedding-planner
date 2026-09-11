import Foundation
import Singular
import FacebookCore

/// Central funnel instrumentation.
///
/// Every event is mirrored to Singular (attribution / SKAN) and Meta (ad
/// optimisation) so both funnels stay comparable. Revenue events stay in
/// `SubscriptionManager` — this type only covers the pre-purchase funnel.
enum Analytics {

    // MARK: - Custom event names
    enum Event {
        static let onboardingStep = "onboarding_step"
        static let paywallDismissed = "paywall_dismissed"
        static let paywallPlanSelected = "paywall_plan_selected"

        // Phase 4 — recovery surfaces.
        static let dismissalPaywallViewed = "dismissal_paywall_viewed"
        static let dismissalPaywallPurchased = "dismissal_paywall_purchased"
        static let dismissalPaywallDismissed = "dismissal_paywall_dismissed"
        static let foreverUpsellViewed = "forever_upsell_viewed"
        static let foreverUpsellPurchased = "forever_upsell_purchased"
        static let foreverUpsellSkipped = "forever_upsell_skipped"

        // Cross-promo — Everlens placements (see `EverlensPromo`).
        static let everlensPromoViewed = "everlens_promo_viewed"
        static let everlensStoreOpened = "everlens_store_opened"
        static let everlensPromoDismissed = "everlens_promo_dismissed"
    }

    /// Where a paywall impression came from. Sent as the `source` property on
    /// the paywall view / dismiss events so the triggers are separable.
    enum PaywallSource: String {
        case postOnboarding = "post_onboarding"
        case coldStart = "cold_start"
        case featureGate = "feature_gate"
        /// Opened from the T-60-days-before-the-wedding win-back notification.
        case winback = "winback"
    }

    // MARK: - Generic

    static func track(_ name: String, _ params: [String: Any] = [:]) {
        guard !params.isEmpty else {
            Singular.event(name)
            AppEvents.shared.logEvent(AppEvents.Name(name))
            return
        }
        Singular.event(name, withArgs: params)
        AppEvents.shared.logEvent(AppEvents.Name(name), parameters: metaParameters(params))
    }

    // MARK: - Funnel

    /// One event per onboarding screen the user advances past.
    /// `step` is the zero-based screen index, `screen` a short stable slug.
    static func onboardingStep(_ step: Int, _ screen: String) {
        track(Event.onboardingStep, ["step": step, "screen": screen])
    }

    /// Paywall impression. Uses the standard content-view event (already wired
    /// on both SDKs) and adds the trigger as a `source` property. When the
    /// trigger was a feature gate, `gate` names which limit fired
    /// (`guests_limit`, `budget_categories`, `pdf_export`, …) so the funnel can
    /// be split by the limit that actually earns the money.
    static func paywallView(source: PaywallSource, gate: PremiumGate? = nil) {
        var params: [String: Any] = ["source": source.rawValue]
        if let gate { params["gate"] = gate.rawValue }

        Singular.event(EVENT_SNG_CONTENT_VIEW, withArgs: params)
        AppEvents.shared.logEvent(.viewedContent, parameters: metaParameters(params))
    }

    /// Paywall closed without a completed purchase.
    static func paywallDismissed(source: PaywallSource, gate: PremiumGate? = nil) {
        var params: [String: Any] = ["source": source.rawValue]
        if let gate { params["gate"] = gate.rawValue }
        track(Event.paywallDismissed, params)
    }

    /// User tapped a different plan on the ladder. `plan` is the normalised
    /// duration slug (annual / lifetime / monthly / …), not a product ID, so it
    /// stays comparable across pricing changes and RC A/B variants.
    static func paywallPlanSelected(plan: String, source: PaywallSource) {
        track(Event.paywallPlanSelected, ["plan": plan, "source": source.rawValue])
    }

    // MARK: - Recovery surfaces (Phase 4)

    /// The decline-ladder sheet was shown after a paywall was closed without a
    /// purchase. `source` is the paywall the user actually declined, so the
    /// recovery rate can be read per trigger.
    static func dismissalPaywallViewed(source: PaywallSource) {
        track(Event.dismissalPaywallViewed, ["source": source.rawValue])
    }

    /// The decline ladder converted. `plan` is the normalised duration slug of
    /// whatever the `dismissal` offering sold, not a product ID.
    static func dismissalPaywallPurchased(plan: String, source: PaywallSource) {
        track(Event.dismissalPaywallPurchased, ["plan": plan, "source": source.rawValue])
    }

    /// The decline ladder was closed without a purchase — the end of the road.
    static func dismissalPaywallDismissed(source: PaywallSource) {
        track(Event.dismissalPaywallDismissed, ["source": source.rawValue])
    }

    /// The one-time post-purchase Forever upsell was shown.
    static func foreverUpsellViewed() {
        track(Event.foreverUpsellViewed)
    }

    /// A subscriber upgraded to the lifetime SKU straight after subscribing.
    static func foreverUpsellPurchased() {
        track(Event.foreverUpsellPurchased)
    }

    /// The Forever upsell was declined. Fires once per user at most.
    static func foreverUpsellSkipped() {
        track(Event.foreverUpsellSkipped)
    }

    // MARK: - Cross-promo

    /// The Everlens sheet was opened. `surface` is the placement it came from
    /// (`brideplan-task`, `brideplan-dashboard`, …) — the same token the App
    /// Store campaign link carries, so impressions and installs line up.
    static func everlensPromoViewed(surface: String) {
        track(Event.everlensPromoViewed, ["surface": surface])
    }

    /// The couple tapped through to Everlens on the App Store.
    static func everlensStoreOpened(surface: String) {
        track(Event.everlensStoreOpened, ["surface": surface])
    }

    /// A placement was closed for good (only the dashboard card is dismissable).
    static func everlensPromoDismissed(surface: String) {
        track(Event.everlensPromoDismissed, ["surface": surface])
    }

    // MARK: - Helpers

    private static func metaParameters(_ params: [String: Any]) -> [AppEvents.ParameterName: Any] {
        var result: [AppEvents.ParameterName: Any] = [:]
        for (key, value) in params {
            result[AppEvents.ParameterName(key)] = value
        }
        return result
    }
}
