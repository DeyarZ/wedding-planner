import SwiftUI
import StoreKit

struct PaywallView: View {
    @Binding var isPresented: Bool
    @State private var selectedPlan: PlanType = .weekly
    @State private var products: [Product] = []
    @State private var weeklyPrice = "$4.99"
    @State private var sixMonthPrice = "$29.99"
    @State private var isPurchasing = false
    @State private var showTermsOfUse = false
    @State private var showPrivacyPolicy = false

    private let weeklyProductID = "com.manuelworlitzer.weddingplanner.premium.weekly"
    private let sixMonthProductID = "com.manuelworlitzer.weddingplanner.premium.6months"

    enum PlanType {
        case weekly
        case sixMonth
    }

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
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color(hex: "9B9B9B"))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

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
                        FeatureRow(icon: "heart.fill", text: "Unlimited guests & vendors", color: Color(hex: "FFB6C1"))
                        FeatureRow(icon: "sparkles", text: "Smart budget insights", color: Color(hex: "FFD700"))
                        FeatureRow(icon: "calendar.badge.clock", text: "Timeline management", color: Color(hex: "D4B5A9"))
                    }
                    .padding(.horizontal, 32)

                    // Warm message
                    Text("We're here to make your planning journey stress-free")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Pricing cards - side by side
                    HStack(spacing: 16) {
                        // Weekly Plan Card
                        PricingCard(
                            isSelected: selectedPlan == .weekly,
                            mainText: "3 days free",
                            subText: "then \(weeklyPrice)/week",
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = .weekly
                                }
                            }
                        )

                        // 6-Month Plan Card
                        PricingCard(
                            isSelected: selectedPlan == .sixMonth,
                            mainText: calculateWeeklyPrice(),
                            subText: "billed 6-monthly",
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = .sixMonth
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 4)

                    Spacer()

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

                                Text(selectedPlan == .weekly ? "Start Planning Together" : "Unlock Full Experience")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
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
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showTermsOfUse) {
            TermsOfUseView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onAppear {
            loadProducts()
        }
    }

    private func loadProducts() {
        Task {
            do {
                let productIDs = [weeklyProductID, sixMonthProductID]
                let loadedProducts = try await Product.products(for: productIDs)

                await MainActor.run {
                    self.products = loadedProducts

                    // Update prices with real App Store prices
                    if let weeklyProduct = loadedProducts.first(where: { $0.id == weeklyProductID }) {
                        weeklyPrice = weeklyProduct.displayPrice
                    }

                    if let sixMonthProduct = loadedProducts.first(where: { $0.id == sixMonthProductID }) {
                        sixMonthPrice = sixMonthProduct.displayPrice
                    }
                }
            } catch {
                print("Failed to load products: \(error)")
            }
        }
    }

    private func calculateWeeklyPrice() -> String {
        // Extract numeric value from sixMonthPrice and divide by 26 weeks
        let priceString = sixMonthPrice.replacingOccurrences(of: "$", with: "")
        if let price = Double(priceString) {
            let weeklyPrice = price / 26.0
            return String(format: "$%.2f/week", weeklyPrice)
        }
        return "$1.15/week"
    }

    private func purchaseSubscription() {
        let productID = selectedPlan == .weekly ? weeklyProductID : sixMonthProductID
        guard let product = products.first(where: { $0.id == productID }) else { return }

        isPurchasing = true

        Task {
            do {
                let result = try await product.purchase()

                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        // Update premium status
                        await MainActor.run {
                            UserDefaults.standard.set(true, forKey: "isPremiumUser")
                            UserDefaults.standard.set(true, forKey: "hasPremiumAccess")
                            UserDefaults.standard.set(Date(), forKey: "premiumPurchaseDate")
                            isPurchasing = false
                            isPresented = false
                        }

                        // Finish the transaction
                        await transaction.finish()

                    case .unverified:
                        await MainActor.run {
                            isPurchasing = false
                        }
                        print("Transaction unverified")
                    }

                case .userCancelled:
                    await MainActor.run {
                        isPurchasing = false
                    }
                    print("User cancelled purchase")

                case .pending:
                    await MainActor.run {
                        isPurchasing = false
                    }
                    print("Purchase pending")

                @unknown default:
                    await MainActor.run {
                        isPurchasing = false
                    }
                    print("Unknown purchase result")
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    print("Purchase failed: \(error)")
                }
            }
        }
    }

    private func restorePurchases() {
        Task {
            // Restore purchases using StoreKit 2
            do {
                // This will restore all the user's purchased subscriptions
                try await AppStore.sync()

                // Check if user has active subscription
                var hasActiveSubscription = false

                // Get all products to check entitlements
                for product in products {
                    // Check if user has access to this product
                    let verificationResult = await product.currentEntitlement

                    switch verificationResult {
                    case .verified(let transaction):
                        hasActiveSubscription = true
                        await transaction.finish()
                    case .unverified:
                        print("Unverified entitlement for \(product.id)")
                    default:
                        break
                    }
                }

                // Update premium status if subscription found
                if hasActiveSubscription {
                    await MainActor.run {
                        UserDefaults.standard.set(true, forKey: "isPremiumUser")
                        UserDefaults.standard.set(true, forKey: "hasPremiumAccess")
                        isPresented = false
                    }
                }
            } catch {
                print("Failed to restore purchases: \(error)")
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

            Spacer()
        }
    }
}

// MARK: - Pricing Card Component
struct PricingCard: View {
    let isSelected: Bool
    let mainText: String
    let subText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Main text - bold
                Text(mainText)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .multilineTextAlignment(.center)

                // Sub text - small
                Text(subText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
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
            .scaleEffect(isSelected ? 1.02 : 1.0)
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
}