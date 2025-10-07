import SwiftUI
import StoreKit

struct PaywallView: View {
    @Binding var isPresented: Bool
    @State private var showTrialOption = true
    @State private var products: [Product] = []
    @State private var weeklyPrice = "$4.99"
    @State private var sixMonthPrice = "$29.99"
    @State private var isPurchasing = false

    private let weeklyProductID = "com.manuelworlitzer.weddingplanner.premium.weekly"
    private let sixMonthProductID = "com.manuelworlitzer.weddingplanner.premium.6months"

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

                // Top 25% - Hero Image
                VStack(spacing: 20) {
                    Image("paywall-hero-image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: UIScreen.main.bounds.height * 0.25)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                // Main content
                VStack(spacing: 32) {
                    // Title section
                    VStack(spacing: 12) {
                        Text(showTrialOption ? "Test it 3 days for free" : "Enjoy the premium experience")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .multilineTextAlignment(.center)

                        Text("Scan unlimited, get insights and more")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                            .multilineTextAlignment(.center)

                        Text("Cancel anytime")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "D4B5A9"))
                    }

                    // Pricing section
                    VStack(spacing: 8) {
                        if showTrialOption {
                            VStack(spacing: 4) {
                                Text("3 days free then")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text(weeklyPrice + " per week")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text("Auto renewable. Cancel anytime")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                            }
                        } else {
                            Text(sixMonthPrice + " for 6 months")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(hex: "2C2C2C"))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showTrialOption)

                    // Toggle container
                    HStack {
                        Text(showTrialOption ? "3 days free" : "6 month plan")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Spacer()

                        Toggle("", isOn: $showTrialOption)
                            .toggleStyle(CustomToggleStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
                    )

                    Spacer()

                    // Purchase button
                    Button(action: {
                        purchaseSubscription()
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(showTrialOption ? "Test for free" : "Subscribe now")
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
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
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

    private func purchaseSubscription() {
        let productID = showTrialOption ? weeklyProductID : sixMonthProductID
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
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Button(action: {
                configuration.isOn.toggle()
            }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color(hex: "D4B5A9") : Color(hex: "E0E0E0"))
                    .frame(width: 50, height: 28)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .offset(x: configuration.isOn ? 11 : -11)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    )
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            }
        }
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
}