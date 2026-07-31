import SwiftUI
import RevenueCat

/// The one-time post-purchase upsell: someone who just started a subscription
/// gets a single congratulations screen offering the lifetime SKU.
///
/// Pure incremental revenue — the user has already paid, the payment sheet is
/// warm, and the ask is one screen. It is capped at once *ever* per user
/// (`RecoveryOffers.Key.hasSeenForeverUpsell`) and never reaches someone who
/// just bought Forever, so it can only ever be a bonus, never a nag.
///
/// The price comes off the `StoreProduct` (locale-aware, via its own formatter),
/// never a string we build.
struct ForeverUpsellView: View {
    @Binding var isPresented: Bool
    /// The lifetime package from the CURRENT offering. Guaranteed non-nil by
    /// the caller — this view is not presented when the offering has none.
    let package: Package

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isPurchasing = false

    private var priceText: String { package.storeProduct.localizedPriceString }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FAFAFA"), Color(hex: "F2EFE9")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Sits outside the ScrollView on purpose: this screen is a
                // fullScreenCover with no swipe-to-dismiss, and the "No thanks"
                // link at the bottom can fall below the fold at large Dynamic
                // Type — leaving no visible way out. Same control, same
                // placement and 44pt target as PaywallView.
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
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(isPurchasing)
                    .accessibilityLabel(Text("Close"))
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    PaywallHeartAnimation()
                        .frame(height: 90)
                        .padding(.top, 12)

                    VStack(spacing: 12) {
                        Text("You're in!")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("Want to make it forever?")
                            .font(.system(size: 20, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "6B6B6B"))

                        Text("One payment, yours beyond the big day.")
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "infinity")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(Color(hex: "B89B91"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Forever")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text("Pay once, yours until the big day & beyond")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(hex: "6B6B6B"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 8)

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(priceText)
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text("one-time")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
                        )
                    }

                    VStack(spacing: 12) {
                        Button(action: purchase) {
                            HStack(spacing: 8) {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(String(format: String(localized: "Make it Forever — %@"), priceText))
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
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

                        // Honest, and it prevents the refund/1-star cycle: the
                        // lifetime purchase does NOT cancel the subscription
                        // they bought thirty seconds ago — only they can.
                        Text("Your current plan stays active until you cancel it in the App Store.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: skip) {
                            Text("No thanks, I'm happy with my plan")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "9B9B9B"))
                                .underline()
                        }
                        .padding(.top, 4)
                        .disabled(isPurchasing)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            Analytics.foreverUpsellViewed()
        }
    }

    // MARK: - Actions

    private func skip() {
        Analytics.foreverUpsellSkipped()
        isPresented = false
    }

    private func purchase() {
        isPurchasing = true

        Task {
            let success = await subscriptionManager.purchase(package)
            isPurchasing = false
            guard success else { return }

            Analytics.foreverUpsellPurchased()
            isPresented = false
        }
    }
}
