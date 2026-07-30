import Foundation
import RevenueCat

/// Rules and persisted state for the Phase 4 revenue-recovery surfaces.
///
/// The point of centralising this: every one of these screens is a *second* ask
/// after the user already said no (or already paid). They earn their keep only
/// while they stay rare. All the frequency caps therefore live in one place,
/// next to each other, where a change can be seen against the others — not
/// scattered across three views.
///
/// Nothing here references a product identifier. Both surfaces render whatever
/// RevenueCat serves, and both no-op silently when the offering they need does
/// not exist yet — so the code can ship before the store-side config
/// (`PRICING-FLIP.md` §6) is done, and no user ever meets a broken sheet.
@MainActor
enum RecoveryOffers {

    // MARK: - Persistence keys
    //
    // Declared here so the `@AppStorage` properties on the views can never
    // drift from each other by a typo.
    enum Key {
        /// Unix timestamp of the last dismissal offer shown to this user.
        static let lastDismissalOfferAt = "lastDismissalOfferAt"
        /// Whether the one-time post-purchase Forever upsell has been used up.
        static let hasSeenForeverUpsell = "hasSeenForeverUpsell"
    }

    // MARK: - Dismissal offer (decline ladder)

    /// RevenueCat offering that drives the dismissal sheet. Deliberately *not*
    /// `current`: the decline ladder is its own offering so it can be reshaped,
    /// A/B tested, or switched off entirely (by deleting it) from the RC
    /// dashboard without a release.
    static let dismissalOfferingID = "dismissal"

    /// At most one dismissal offer per user per 7 days.
    static let dismissalCooldown: TimeInterval = 7 * 24 * 60 * 60

    /// Which paywall dismissals earn a follow-up offer. `.featureGate` is
    /// excluded on purpose: that user hit a wall in the middle of a task, and
    /// chaining a second sales screen onto that is nagging, not recovery.
    static let dismissalSources: Set<Analytics.PaywallSource> = [.postOnboarding, .coldStart]

    /// Session guard on top of the 7-day cap — a user who opens and closes the
    /// paywall twice in one sitting sees the offer once.
    private(set) static var dismissalOfferShownThisSession = false

    static func markDismissalOfferShown() {
        dismissalOfferShownThisSession = true
    }

    /// Every condition that has to hold before a closed paywall becomes a
    /// second offer. Written as one expression per rule so a future change has
    /// to state which rule it is loosening.
    static func shouldOfferDismissal(
        source: Analytics.PaywallSource,
        isSubscribed: Bool,
        offering: Offering?,
        lastShownAt: Double,
        now: Date = Date()
    ) -> Bool {
        guard !isSubscribed else { return false }
        guard dismissalSources.contains(source) else { return false }
        guard !dismissalOfferShownThisSession else { return false }
        // No `dismissal` offering configured yet (pre-flip) → skip silently.
        guard let offering, !offering.availablePackages.isEmpty else { return false }
        guard now.timeIntervalSince1970 - lastShownAt >= dismissalCooldown else { return false }
        return true
    }

    // MARK: - Post-purchase Forever upsell

    /// Shown at most once ever, only to someone who just bought a *subscription*
    /// and only when the current offering actually contains a lifetime package.
    static func shouldOfferForever(
        purchased: Package,
        lifetime: Package?,
        hasSeen: Bool
    ) -> Bool {
        guard !hasSeen else { return false }
        // No lifetime SKU in the offering yet (pre-flip) → skip silently.
        guard let lifetime else { return false }
        // They just bought Forever. Do not sell it to them again.
        guard SubscriptionManager.planKind(for: purchased) != .lifetime else { return false }
        guard lifetime.storeProduct.productIdentifier != purchased.storeProduct.productIdentifier else { return false }
        return true
    }
}
