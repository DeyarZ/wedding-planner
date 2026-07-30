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
    }

    /// Where a paywall impression came from. Sent as the `source` property on
    /// the paywall view / dismiss events so the three triggers are separable.
    enum PaywallSource: String {
        case postOnboarding = "post_onboarding"
        case coldStart = "cold_start"
        case featureGate = "feature_gate"
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
    /// on both SDKs) and adds the trigger as a `source` property.
    static func paywallView(source: PaywallSource) {
        Singular.event(EVENT_SNG_CONTENT_VIEW, withArgs: ["source": source.rawValue])
        AppEvents.shared.logEvent(
            .viewedContent,
            parameters: [AppEvents.ParameterName("source"): source.rawValue]
        )
    }

    /// Paywall closed without a completed purchase.
    static func paywallDismissed(source: PaywallSource) {
        track(Event.paywallDismissed, ["source": source.rawValue])
    }

    /// User tapped a different plan on the ladder. `plan` is the normalised
    /// duration slug (annual / lifetime / monthly / …), not a product ID, so it
    /// stays comparable across pricing changes and RC A/B variants.
    static func paywallPlanSelected(plan: String, source: PaywallSource) {
        track(Event.paywallPlanSelected, ["plan": plan, "source": source.rawValue])
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
