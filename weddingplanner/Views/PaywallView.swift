import SwiftUI
import RevenueCat
import FacebookCore

struct PaywallView: View {
    @Binding var isPresented: Bool
    /// Which trigger opened this paywall. Sent as the `source` property on the
    /// paywall view / dismiss events.
    var source: Analytics.PaywallSource = .featureGate
    /// Which feature gate sent the user here, when `source` is `.featureGate`.
    /// Reported as the `gate` property on the paywall view / dismiss events.
    var gate: PremiumGate? = nil
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    /// RevenueCat package identifier of the card the user tapped. `nil` means
    /// "whatever the offering says is the default" — see `selectedPlan`.
    @State private var selectedPackageID: String?
    @State private var isPurchasing = false
    @State private var didPurchase = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false

    // MARK: - Phase 4 recovery surfaces
    //
    // Both follow-ups are presented ON TOP of this view and only let it close
    // when they are done, so the chain works identically from every host
    // (cold start, post-onboarding, feature gate) with no host-side wiring.

    /// Last time this user saw the decline ladder — the 7-day frequency cap.
    @AppStorage(RecoveryOffers.Key.lastDismissalOfferAt) private var lastDismissalOfferAt: Double = 0
    /// The Forever upsell is a once-in-a-lifetime screen.
    @AppStorage(RecoveryOffers.Key.hasSeenForeverUpsell) private var hasSeenForeverUpsell = false

    @State private var showDismissalOffer = false
    @State private var dismissalPurchase: Package?
    @State private var showForeverUpsell = false
    @State private var foreverPackage: Package?

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "FAFAFA"),
                    Color(hex: "F2EFE9")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismissWithoutPurchase()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            )
                            // The disc stays 32pt so it keeps its visual weight,
                            // but the hit area is padded out to the 44pt HIG
                            // minimum — App Review checks that a paywall can be
                            // dismissed, and a 32pt target is a rejection risk.
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    // Closing mid-purchase would tear the flow down under the
                    // in-flight StoreKit callback.
                    .disabled(isPurchasing)
                    .accessibilityLabel(Text("Close"))
                }
                // 18/14 + the 6pt inset of the 32pt disc inside its 44pt target
                // == the 24/20 the disc sat at before it was enlarged.
                .padding(.horizontal, 18)
                .padding(.top, 14)

                // The ladder can be 1–4 cards tall depending on what the
                // current RevenueCat offering contains, so the whole sheet
                // scrolls rather than clipping on small devices.
                ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                // Romantic hero section
                VStack(spacing: 16) {
                    // Animated hearts icon
                    PaywallHeartAnimation()
                        .frame(height: 80)

                    // Heartfelt title
                    VStack(spacing: 8) {
                        Text("Your love story deserves")
                            .font(.system(size: 20, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "6B6B6B"))

                        Text("The Perfect Plan")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                // Main content
                VStack(spacing: 24) {
                    // Sweet features with hearts
                    VStack(spacing: 12) {
                        FeatureRow(icon: "heart.fill", text: String(localized: "Unlimited guests & vendors"), color: Color(hex: "FFB6C1"))
                        FeatureRow(icon: "sparkles", text: String(localized: "Smart budget insights"), color: Color(hex: "FFD700"))
                        FeatureRow(icon: "calendar.badge.clock", text: String(localized: "Timeline management"), color: Color(hex: "D4B5A9"))
                    }
                    .padding(.horizontal, 32)

                    // Warm message
                    Text("We're here to make your planning journey stress-free")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)

                    // Pricing ladder — one card per package in the current
                    // RevenueCat offering, ordered annual → forever → monthly.
                    // No product identifier is referenced anywhere here, so the
                    // ladder can be reshaped from the RC dashboard.
                    if plans.isEmpty {
                        ProgressView()
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(plans) { plan in
                                PlanRowCard(
                                    plan: plan,
                                    isSelected: plan.id == selectedPlan?.id,
                                    isBestValue: plan.id == bestValuePlanID,
                                    onTap: { select(plan) }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    VStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "2C2C2C"))
                            Text(trustText)
                                .font(.system(size: 14, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Purchase button
                        Button(action: {
                            purchaseSubscription()
                        }) {
                            HStack(spacing: 8) {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)

                                    Text(ctaTitle)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.7)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "B89B91").opacity(0.3), radius: 12, y: 6)
                        }
                        .disabled(isPurchasing)

                        summaryText
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Restore Purchases Button
                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .underline()
                    }
                    .padding(.top, 8)

                    // Terms of Use & Privacy Policy
                    HStack(spacing: 4) {
                        Button(action: {
                            showTermsOfUse = true
                        }) {
                            Text("Terms of Use")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: "9B9B9B"))
                                .underline()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        Text(" & ")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))

                        Button(action: {
                            showPrivacyPolicy = true
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: "9B9B9B"))
                                .underline()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                }
                }
            }
        }
        .sheet(isPresented: $showTermsOfUse) {
            TermsOfUseView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .fullScreenCover(isPresented: $showDismissalOffer, onDismiss: {
            // A decline that converted is still a purchase, so it gets the
            // Forever upsell like any other. A decline that stayed a decline
            // ends the chain and finally closes the paywall.
            if let package = dismissalPurchase {
                presentForeverUpsellOrDismiss(after: package)
            } else {
                isPresented = false
            }
        }) {
            DismissalPaywallView(
                isPresented: $showDismissalOffer,
                source: source,
                onPurchase: { package in
                    didPurchase = true
                    dismissalPurchase = package
                }
            )
            .environmentObject(subscriptionManager)
        }
        .fullScreenCover(isPresented: $showForeverUpsell, onDismiss: {
            isPresented = false
        }) {
            if let package = foreverPackage {
                ForeverUpsellView(isPresented: $showForeverUpsell, package: package)
                    .environmentObject(subscriptionManager)
            } else {
                // Unreachable by construction (`foreverPackage` is always set
                // before this cover is raised) — but a fullScreenCover cannot be
                // swiped away, so an empty one would trap the user. Bail out
                // instead of rendering nothing.
                Color.clear.onAppear { showForeverUpsell = false }
            }
        }
        .onAppear {
            Analytics.paywallView(source: source, gate: gate)
            loadOfferings()
        }
    }

    // MARK: - The ladder

    /// One card per package in the current RevenueCat offering, already in
    /// display order. Empty until offerings have loaded.
    private var plans: [PaywallPlan] {
        subscriptionManager.availablePackages.map(PaywallPlan.init)
    }

    /// The card that is highlighted. Defaults to whatever the offering says is
    /// the best plan (annual first) until the user taps something else, so the
    /// default selection moves with the RC offering — never with the binary.
    private var selectedPlan: PaywallPlan? {
        if let id = selectedPackageID, let match = plans.first(where: { $0.id == id }) {
            return match
        }
        if let defaultID = subscriptionManager.defaultPackage?.identifier,
           let match = plans.first(where: { $0.id == defaultID }) {
            return match
        }
        return plans.first
    }

    /// "BEST VALUE" goes on the longest-commitment plan present. Suppressed
    /// when there is only one card — a badge on a single option says nothing.
    private var bestValuePlanID: String? {
        guard plans.count > 1 else { return nil }
        for kind in SubscriptionManager.PlanKind.bestValuePriority {
            if let match = plans.first(where: { $0.kind == kind }) { return match.id }
        }
        return nil
    }

    private func select(_ plan: PaywallPlan) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPackageID = plan.id
        }
        Analytics.paywallPlanSelected(plan: plan.kind.analyticsName, source: source)
    }

    // MARK: - Copy

    private var ctaTitle: String {
        guard let plan = selectedPlan else { return String(localized: "Continue") }
        if plan.trialDays != nil { return String(localized: "Start Planning Together") }
        return String(localized: "Unlock everything")
    }

    /// The line under the CTA. Always spells out the real billing amount and
    /// the trial length actually attached to the selected product (App Store
    /// guideline 3.1.2) — no hardcoded trial length anywhere.
    private var summaryText: Text {
        guard let plan = selectedPlan else { return Text("") }
        return Text(plan.summary)
            .font(.system(size: 15, weight: .regular, design: .serif))
    }

    private var trustText: String {
        guard let plan = selectedPlan else { return String(localized: "Cancel anytime, no commitment") }
        if plan.trialDays != nil { return String(localized: "No payment due now") }
        if plan.kind == .lifetime { return String(localized: "One payment, no subscription") }
        return String(localized: "Cancel anytime, no commitment")
    }

    private func loadOfferings() {
        Task {
            if subscriptionManager.offerings == nil {
                await subscriptionManager.loadOfferings()
            }
        }
    }

    private func dismissWithoutPurchase() {
        guard !didPurchase else {
            isPresented = false
            return
        }
        Analytics.paywallDismissed(source: source, gate: gate)

        // The decline ladder. Every guard lives in `RecoveryOffers` — including
        // "no `dismissal` offering configured yet", which makes this a silent
        // no-op before the store-side flip rather than a broken sheet.
        if RecoveryOffers.shouldOfferDismissal(
            source: source,
            isSubscribed: subscriptionManager.isSubscribed,
            offering: subscriptionManager.offering(RecoveryOffers.dismissalOfferingID),
            lastShownAt: lastDismissalOfferAt
        ) {
            RecoveryOffers.markDismissalOfferShown()
            lastDismissalOfferAt = Date().timeIntervalSince1970
            showDismissalOffer = true
            return
        }

        isPresented = false
    }

    /// Single exit point for a completed purchase: kill the notifications that
    /// only make sense for a non-payer, then either chain the Forever upsell or
    /// close the paywall.
    private func handlePurchase(of package: Package) {
        didPurchase = true
        TrialNotificationManager.shared.cancelTrialReminders()
        WinBackNotificationManager.shared.cancel()
        presentForeverUpsellOrDismiss(after: package)
    }

    private func presentForeverUpsellOrDismiss(after package: Package) {
        guard RecoveryOffers.shouldOfferForever(
            purchased: package,
            lifetime: subscriptionManager.package(.lifetime),
            hasSeen: hasSeenForeverUpsell
        ), let lifetime = subscriptionManager.package(.lifetime) else {
            isPresented = false
            return
        }

        hasSeenForeverUpsell = true
        foreverPackage = lifetime
        showForeverUpsell = true
    }

    private func purchaseSubscription() {
        Singular.event("sng_initiated_checkout")
        AppEvents.shared.logEvent(.initiatedCheckout)

        guard let plan = selectedPlan else {
            print("[Paywall] No package available in the current offering")
            return
        }
        let package = plan.package

        isPurchasing = true

        Task {
            let success = await subscriptionManager.purchase(package)
            isPurchasing = false
            if success && subscriptionManager.isSubscribed {
                handlePurchase(of: package)
            }
        }
    }

    private func restorePurchases() {
        Task {
            await subscriptionManager.restorePurchases()
            if subscriptionManager.isSubscribed {
                didPurchase = true
                // A restore is not a fresh purchase — no upsell, just get out
                // of the way.
                TrialNotificationManager.shared.cancelTrialReminders()
                WinBackNotificationManager.shared.cancel()
                isPresented = false
            }
        }
    }
}

// MARK: - Paywall Heart Animation
struct PaywallHeartAnimation: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFB6C1").opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .blur(radius: 10)

            // Main heart
            Image(systemName: "heart.fill")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFB6C1"),
                            Color(hex: "FFC0CB")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color(hex: "FFB6C1").opacity(0.4), radius: 12, x: 0, y: 6)

            // Small orbiting hearts
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FFB6C1").opacity(0.6))
                    .offset(
                        x: cos(Angle(degrees: Double(index) * 120 + rotation * 2).radians) * 35,
                        y: sin(Angle(degrees: Double(index) * 120 + rotation * 2).radians) * 35
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "4A4A4A"))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Paywall plan view model

/// One rendered row of the pricing ladder, derived entirely from a RevenueCat
/// package. Every price string comes off the `StoreProduct` (locale-aware, via
/// its own formatter) — nothing here is ever string-built or hardcoded, and no
/// product identifier is referenced, so the ladder follows the RC offering.
struct PaywallPlan: Identifiable {
    let package: Package
    let kind: SubscriptionManager.PlanKind

    init(package: Package) {
        self.package = package
        self.kind = SubscriptionManager.planKind(for: package)
    }

    /// RevenueCat package identifier — unique inside an offering.
    var id: String { package.identifier }

    var product: StoreProduct { package.storeProduct }

    /// Free-trial length of *this* package, or nil when it has no trial. The
    /// trial-vs-no-trial test runs by swapping the RC offering, so both must
    /// render correctly from the same binary.
    var trialDays: Int? { SubscriptionManager.trialDays(for: package) }

    /// Left-hand label.
    var title: String {
        switch kind {
        case .annual: return String(localized: "Yearly")
        case .lifetime: return String(localized: "Forever")
        case .monthly: return String(localized: "Monthly")
        case .sixMonth: return String(localized: "6 Months")
        case .threeMonth: return String(localized: "3 Months")
        case .weekly: return String(localized: "Weekly")
        case .other: return product.localizedTitle
        }
    }

    /// Full billing price with its period, e.g. "€59.99/year".
    var recurringPriceText: String {
        let price = product.localizedPriceString
        switch kind {
        case .annual: return String(format: String(localized: "%@/year"), price)
        case .monthly: return String(format: String(localized: "%@/month"), price)
        case .weekly: return String(format: String(localized: "%@/week"), price)
        case .sixMonth: return String(format: String(localized: "%@ every 6 months"), price)
        case .threeMonth: return String(format: String(localized: "%@ every 3 months"), price)
        case .lifetime, .other: return price
        }
    }

    /// Line under the plan title on the card.
    var subtitle: String {
        if let days = trialDays {
            return String(format: String(localized: "%1$lld days free, then %2$@"), days, recurringPriceText)
        }
        if kind == .lifetime {
            return String(localized: "Pay once, yours until the big day & beyond")
        }
        return recurringPriceText
    }

    /// Line under the CTA for the selected plan.
    var summary: String {
        if let days = trialDays {
            return String(format: String(localized: "%1$lld days free, then %2$@"), days, recurringPriceText)
        }
        if kind == .lifetime {
            return String(format: String(localized: "%@ once — yours forever"), product.localizedPriceString)
        }
        return String(format: String(localized: "Just %@"), recurringPriceText)
    }

    /// Locale-aware per-week equivalent, derived from the product's own price
    /// and billing period. Nil for one-time and weekly products.
    private var pricePerWeek: String? {
        SubscriptionManager.localizedPricePerWeek(for: product)
    }

    /// Big number on the right of the card.
    var priceHeadline: String {
        pricePerWeek ?? product.localizedPriceString
    }

    var priceCaption: String {
        if pricePerWeek != nil { return String(localized: "per week") }
        switch kind {
        case .weekly: return String(localized: "per week")
        case .monthly: return String(localized: "per month")
        case .lifetime: return String(localized: "one-time")
        case .other: return ""
        default: return ""
        }
    }
}

// MARK: - Pricing Card Component

struct PlanRowCard: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let isBestValue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(isSelected ? Color(hex: "D4B5A9") : Color(hex: "C9C9C9"))

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(plan.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.priceHeadline)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if !plan.priceCaption.isEmpty {
                        Text(plan.priceCaption)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                // The price column keeps its intrinsic width; a long German or
                // Polish plan name wraps instead of clipping the number.
                .layoutPriority(1)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color(hex: "D4B5A9") : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? Color(hex: "D4B5A9").opacity(0.3) : Color.black.opacity(0.08),
                        radius: isSelected ? 16 : 12,
                        y: 6
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isBestValue {
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "D4B5A9")))
                        .offset(x: -12, y: -9)
                }
            }
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Use")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .padding(.bottom, 10)

                    Group {
                        Text("1. Acceptance of Terms")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("By downloading, installing, or using the Wedding Planner app, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use our app.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("2. Service Description")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("Wedding Planner is a mobile application that helps users plan and organize their wedding events. The app provides tools for vendor management, budget tracking, timeline creation, and other wedding-related planning features.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("3. User Responsibilities")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You agree to use the app only for lawful purposes and in accordance with these Terms of Use.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("4. Subscription and Payment")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("Premium features require a subscription. Subscriptions are automatically renewable unless cancelled at least 24 hours before the end of the current period. You may cancel your subscription at any time through your App Store account settings.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("5. Limitation of Liability")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("The app is provided 'as is' without any warranties. We shall not be liable for any damages arising from the use of this app. Your use of the app is at your own risk.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))
                    }

                    Text("For more information, visit:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4A4A4A"))
                        .padding(.top, 20)

                    Text("https://weddingplanner.app/terms")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "D4B5A9"))
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .padding(.bottom, 10)

                    Group {
                        Text("Information We Collect")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("We collect information you provide directly to us, such as when you create an account, plan your wedding events, or contact us for support. This may include your name, email address, wedding date, and planning preferences.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("How We Use Your Information")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("We use the information we collect to provide, maintain, and improve our services, process transactions, send you technical notices and support messages, and communicate with you about products, services, and events.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("Data Security")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("Third-Party Services")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))

                        Text("Contact Us")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("If you have any questions about this Privacy Policy, please contact us. We reserve the right to update this policy at any time, and we will notify you of any material changes.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "4A4A4A"))
                    }

                    Text("For more information, visit:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4A4A4A"))
                        .padding(.top, 20)

                    Text("https://weddingplanner.app/privacy")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "D4B5A9"))
                }
            }
        }
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
        .environmentObject(SubscriptionManager.shared)
}