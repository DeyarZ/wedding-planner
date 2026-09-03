import SwiftUI
import RevenueCat

/// The decline ladder: one follow-up offer for a user who just closed the main
/// paywall without buying.
///
/// It is driven by its own RevenueCat offering (`dismissal`), never by
/// `current` — so the discount anchor and the rescue SKU can be reshaped from
/// the dashboard, and the whole surface can be switched off by deleting the
/// offering. Everything renders from whatever packages that offering contains,
/// exactly like the main paywall; no product identifier appears anywhere here.
///
/// Frequency is not this view's business — `RecoveryOffers` decides whether it
/// is ever presented (see `PaywallView.dismissWithoutPurchase`).
struct DismissalPaywallView: View {
    @Binding var isPresented: Bool
    /// Which paywall the user just declined. Reported on the events so the
    /// decline ladder can be read separately for post-onboarding vs cold start.
    let source: Analytics.PaywallSource
    /// Called with the purchased package before the sheet closes, so the host
    /// can chain the Forever upsell onto a converted decline.
    let onPurchase: (Package) -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedPackageID: String?
    @State private var isPurchasing = false
    @State private var didPurchase = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FAFAFA"), Color(hex: "F2EFE9")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: skip) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            )
                            // 32pt disc, 44pt hit area — see PaywallView.
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(isPurchasing)
                    .accessibilityLabel(Text("Close"))
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header

                        if plans.isEmpty {
                            ProgressView()
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(plans) { plan in
                                    PlanRowCard(
                                        plan: plan,
                                        isSelected: plan.id == selectedPlan?.id,
                                        isBestValue: false,
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

                            Button(action: purchase) {
                                HStack(spacing: 8) {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)

                                        Text("Keep my plan")
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
                            .disabled(isPurchasing || selectedPlan == nil)

                            if let plan = selectedPlan {
                                Text(plan.summary)
                                    .font(.system(size: 15, weight: .regular, design: .serif))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Button(action: skip) {
                            Text("No thanks, I'll plan on my own")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "9B9B9B"))
                                .underline()
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .disabled(isPurchasing)

                        legalFooter
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showTermsOfUse) { TermsOfUseView() }
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }
        .onAppear {
            Analytics.dismissalPaywallViewed(source: source)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 16) {
            Text("ONE LAST OFFER")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "D4B5A9")))

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F6E7E1"), Color(hex: "EFDCD3")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "hourglass")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(Color(hex: "B89B91"))
            }

            VStack(spacing: 10) {
                Text("Your wedding won't wait")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("Keep your plan for less — one last offer before you go.")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var legalFooter: some View {
        VStack(spacing: 10) {
            Button(action: restore) {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .underline()
            }

            HStack(spacing: 4) {
                Button(action: { showTermsOfUse = true }) {
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

                Button(action: { showPrivacyPolicy = true }) {
                    Text("Privacy Policy")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .underline()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    // MARK: - The ladder

    /// Packages of the `dismissal` offering, in the same display order the main
    /// paywall uses. Empty when the offering does not exist — but in that case
    /// this view is never presented in the first place.
    private var plans: [PaywallPlan] {
        guard let offering = subscriptionManager.offering(RecoveryOffers.dismissalOfferingID) else { return [] }
        return offering.availablePackages
            .sorted { lhs, rhs in
                let l = SubscriptionManager.planKind(for: lhs).displayOrder
                let r = SubscriptionManager.planKind(for: rhs).displayOrder
                if l != r { return l < r }
                return lhs.storeProduct.productIdentifier < rhs.storeProduct.productIdentifier
            }
            .map(PaywallPlan.init)
    }

    private var selectedPlan: PaywallPlan? {
        if let id = selectedPackageID, let match = plans.first(where: { $0.id == id }) {
            return match
        }
        return plans.first
    }

    private var trustText: String {
        guard let plan = selectedPlan else { return String(localized: "Cancel anytime, no commitment") }
        if plan.trialDays != nil { return String(localized: "No payment due now") }
        if plan.kind == .lifetime { return String(localized: "One payment, no subscription") }
        return String(localized: "Cancel anytime, no commitment")
    }

    private func select(_ plan: PaywallPlan) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPackageID = plan.id
        }
    }

    // MARK: - Actions

    private func skip() {
        if !didPurchase {
            Analytics.dismissalPaywallDismissed(source: source)
        }
        isPresented = false
    }

    private func purchase() {
        guard let plan = selectedPlan else { return }
        isPurchasing = true

        Task {
            let success = await subscriptionManager.purchase(plan.package)
            isPurchasing = false
            guard success, subscriptionManager.isSubscribed else { return }

            didPurchase = true
            Analytics.dismissalPaywallPurchased(plan: plan.kind.analyticsName, source: source)
            TrialNotificationManager.shared.cancelTrialReminders()
            WinBackNotificationManager.shared.cancel()
            onPurchase(plan.package)
            isPresented = false
        }
    }

    private func restore() {
        Task {
            await subscriptionManager.restorePurchases()
            if subscriptionManager.isSubscribed {
                didPurchase = true
                TrialNotificationManager.shared.cancelTrialReminders()
                WinBackNotificationManager.shared.cancel()
                isPresented = false
            }
        }
    }
}
