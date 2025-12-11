import SwiftUI

struct OnboardingView: View {
    @State private var currentScreen = 0
    @State private var showMainApp = false
    var onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    var body: some View {
        TabView(selection: $currentScreen) {
            Onboarding01_WelcomeScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 1
                }
            })
            .tag(0)

            Onboarding02_FeaturesScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 2
                }
            })
            .tag(1)

            Onboarding03_WeddingBasicsScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 3
                }
            })
            .tag(2)

            Onboarding04_BudgetSetupScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 4
                }
            })
            .tag(3)

            Onboarding05_GuestCountScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 5
                }
            })
            .tag(4)

            Onboarding06_PrioritiesScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 6
                }
            })
            .tag(5)

            Onboarding07_InitialTasksScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 7
                }
            })
            .tag(6)

            Onboarding08_TrialOfferScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 8
                }
            })
            .tag(7)

            Onboarding09_NotificationScreen(onContinue: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = 9
                }
            })
            .tag(8)

            Onboarding10_TrialTimelineScreen(onContinue: {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                showMainApp = true
                // Call the completion handler if provided
                onComplete?()
            })
            .tag(9)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(.all)
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
    }
}

// MARK: - Individual Onboarding Screens

struct Onboarding01_WelcomeScreen: View {
    let onContinue: () -> Void
    @State private var animateHeart = false
    @State private var showContent = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful gradient background - fills entire screen including safe areas
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),  // Warm cream
                        Color(hex: "F5EFE7")   // Soft beige
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer()

                    // Animated Heart
                    AnimatedHeartView(isAnimating: $animateHeart)
                        .frame(height: 120)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showContent)

                    Spacer()
                        .frame(height: 60)

                    // Headline Text
                    Text("YOUR PERFECT DAY\nSTARTS HERE")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)

                    Spacer()
                        .frame(height: 24)

                    // Body Text
                    Text("Plan your dream wedding with ease. From budget tracking to guest management, we'll guide you through every magical moment.")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                    Spacer()

                    // Continue Button
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                    Spacer()
                        .frame(height: 80)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
            animateHeart = true
        }
    }
}

// MARK: - Animated Heart Component
struct AnimatedHeartView: View {
    @Binding var isAnimating: Bool
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var sparkles: [SparkleView] = []
    @State private var floatingHearts: [FloatingHeart] = []

    var body: some View {
        ZStack {
            // Glow effect background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFB6C1").opacity(glowOpacity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)
                .scaleEffect(pulseScale)

            // Main heart with multiple effects
            Image(systemName: "heart.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFB6C1"),  // Light pink
                            Color(hex: "FFC0CB"),  // Pink
                            Color(hex: "DDA0DD")   // Plum
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color(hex: "FFB6C1").opacity(0.5), radius: 15, x: 0, y: 8)
                .shadow(color: Color(hex: "DDA0DD").opacity(0.3), radius: 25, x: 0, y: 12)

            // Floating hearts
            ForEach(floatingHearts.indices, id: \.self) { index in
                floatingHearts[index]
            }

            // Sparkle effects
            ForEach(sparkles.indices, id: \.self) { index in
                sparkles[index]
            }
        }
        .onChange(of: isAnimating) { _, animating in
            if animating {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Heart beat animation (more dramatic)
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scale = 1.15
        }

        // Pulse glow effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
            glowOpacity = 0.6
        }

        // Gentle rotation
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Add sparkles continuously
        addContinuousSparkles()

        // Add floating hearts
        addFloatingHearts()
    }

    private func addContinuousSparkles() {
        // Initial burst
        for i in 0..<8 {
            let delay = Double(i) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                addSparkle(delay: delay)
            }
        }

        // Continuous sparkles
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            addSparkle(delay: 0)
        }
    }

    private func addSparkle(delay: Double) {
        let sparkle = SparkleView(delay: delay)
        sparkles.append(sparkle)

        // Remove old sparkles
        if sparkles.count > 10 {
            sparkles.removeFirst()
        }
    }

    private func addFloatingHearts() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let heart = FloatingHeart()
            floatingHearts.append(heart)

            // Remove old hearts
            if floatingHearts.count > 6 {
                floatingHearts.removeFirst()
            }
        }
    }
}

// MARK: - Enhanced Sparkle Effect
struct SparkleView: View {
    let delay: Double
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 12...20), weight: .light))
            .foregroundColor(Color(hex: "FFD700").opacity(0.9))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeOut(duration: 2.0).delay(delay)) {
                    opacity = 1
                    scale = 1
                    rotation = Double.random(in: 0...360)
                    offset = CGSize(
                        width: Double.random(in: -80...80),
                        height: Double.random(in: -80...80)
                    )
                }

                withAnimation(.easeIn(duration: 1.0).delay(delay + 2.0)) {
                    opacity = 0
                    scale = 0.2
                }
            }
    }
}

// MARK: - Floating Hearts
struct FloatingHeart: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var offset: CGSize = .zero

    var body: some View {
        Image(systemName: "heart")
            .font(.system(size: CGFloat.random(in: 16...24), weight: .ultraLight))
            .foregroundColor(Color(hex: "FFB6C1").opacity(0.6))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                let endX = Double.random(in: -100...100)
                let endY = Double.random(in: -120...(-60))

                withAnimation(.easeOut(duration: 3.0)) {
                    opacity = 0.7
                    scale = 1.0
                    offset = CGSize(width: endX, height: endY)
                }

                withAnimation(.easeIn(duration: 1.0).delay(2.0)) {
                    opacity = 0
                }
            }
    }
}

struct Onboarding02_FeaturesScreen: View {
    let onContinue: () -> Void
    @State private var animateApp = false
    @State private var showContent = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background as first screen
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),  // Warm cream
                        Color(hex: "F5EFE7")   // Soft beige
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer()

                    // Animated App Demo
                    AppDemoView(isAnimating: $animateApp)
                        .frame(height: 200)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showContent)

                    Spacer()
                        .frame(height: 80)

                    // Headline Text
                    Text("EVERYTHING YOU NEED\nIN ONE PLACE")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)

                    Spacer()
                        .frame(height: 24)

                    // Body Text
                    Text("Track your budget, manage vendors, organize guests, and timeline every detail. Our smart features adapt to your style and stress levels.")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                    Spacer()

                    // Continue Button
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                    Spacer()
                        .frame(height: 80)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
            animateApp = true
        }
    }
}

// MARK: - App Demo Animation
struct AppDemoView: View {
    @Binding var isAnimating: Bool
    @State private var currentView = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            // Phone frame - cleaner design
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1C1C1E"))
                .frame(width: 140, height: 280)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 126, height: 266)
                        .overlay(
                            // Notch
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "1C1C1E"))
                                .frame(width: 40, height: 4)
                                .offset(y: -125),
                            alignment: .top
                        )
                        .overlay(
                            // App content that changes
                            Group {
                                switch currentView {
                                case 0:
                                    DashboardMockView()
                                case 1:
                                    BudgetMockView()
                                case 2:
                                    GuestsMockView()
                                default:
                                    TasksMockView()
                                }
                            }
                            .opacity(opacity)
                            .scaleEffect(scale)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)

            // Cleaner floating feature icons - more organized
            ForEach(0..<4, id: \.self) { index in
                FeatureIcon(
                    icon: ["calendar", "dollarsign.circle", "person.2", "checkmark.circle"][index],
                    color: [Color(hex: "D4B5A9"), Color(hex: "C8D4C8"), Color(hex: "C8D4E8"), Color(hex: "E8D4C8")][index],
                    delay: Double(index) * 0.2
                )
                .offset(
                    x: [60, -60, 70, -70][index],
                    y: [-40, -20, 20, 40][index]
                )
            }
        }
        .onChange(of: isAnimating) { _, animating in
            if animating {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Smoother phone screen transitions
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                opacity = 0.4
                scale = 0.98
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentView = (currentView + 1) % 4

                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 1.0
                    scale = 1.0
                }
            }
        }
    }
}

// MARK: - Mock App Views
struct DashboardMockView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 20)

            // Countdown
            VStack(spacing: 6) {
                Text("127")
                    .font(.system(size: 24, weight: .ultraLight, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("days to go")
                    .font(.system(size: 8, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            Spacer()
                .frame(height: 20)

            // Progress indicators
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill([Color(hex: "D4B5A9"), Color(hex: "C8D4C8"), Color(hex: "C8D4E8")][index])
                            .frame(width: 6, height: 6)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "F0F0F0"))
                            .frame(height: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill([Color(hex: "D4B5A9"), Color(hex: "C8D4C8"), Color(hex: "C8D4E8")][index])
                                    .frame(width: [45, 35, 55][index], height: 4),
                                alignment: .leading
                            )
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
        }
        .frame(width: 126, height: 266)
    }
}

struct BudgetMockView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 20)

            // Budget header
            VStack(spacing: 4) {
                Text("$45,000")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("of $50,000 spent")
                    .font(.system(size: 8, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            Spacer()
                .frame(height: 20)

            // Budget categories
            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill([Color(hex: "D4B5A9"), Color(hex: "C8D4C8"), Color(hex: "C8D4E8"), Color(hex: "E8D4C8")][index])
                            .frame(width: 6, height: 6)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "F0F0F0"))
                            .frame(height: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill([Color(hex: "D4B5A9"), Color(hex: "C8D4C8"), Color(hex: "C8D4E8"), Color(hex: "E8D4C8")][index])
                                    .frame(width: [50, 30, 40, 35][index], height: 4),
                                alignment: .leading
                            )
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
        }
        .frame(width: 126, height: 266)
    }
}

struct GuestsMockView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 20)

            // Guest stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("142")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                    Text("Invited")
                        .font(.system(size: 7, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }

                VStack(spacing: 4) {
                    Text("89")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                    Text("Confirmed")
                        .font(.system(size: 7, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }
            }

            Spacer()
                .frame(height: 20)

            // Guest list
            VStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color(hex: "E8E8E8"))
                            .frame(width: 8, height: 8)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "F8F8F8"))
                            .frame(height: 3)

                        Circle()
                            .fill([Color(hex: "C8D4C8"), Color(hex: "D4B5A9"), Color(hex: "E8E8E8")][index % 3])
                            .frame(width: 4, height: 4)
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
        }
        .frame(width: 126, height: 266)
    }
}

struct TasksMockView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 20)

            // Header
            Text("Today's Tasks")
                .font(.system(size: 12, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            Spacer()
                .frame(height: 10)

            // Task items
            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Circle()
                            .stroke(Color(hex: "D0D0D0"), lineWidth: 1)
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .fill(index < 2 ? Color(hex: "C8D4C8") : Color.clear)
                                    .frame(width: 3, height: 3)
                            )

                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "F8F8F8"))
                            .frame(height: 3)
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
        }
        .frame(width: 126, height: 266)
    }
}

// MARK: - Floating Feature Icons
struct FeatureIcon: View {
    let icon: String
    let color: Color
    let delay: Double
    @State private var isFloating = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .light))
            .foregroundColor(color)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: color.opacity(0.2), radius: 6, x: 0, y: 3)
            )
            .scaleEffect(isFloating ? 1.05 : 0.95)
            .opacity(isFloating ? 1.0 : 0.7)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(delay)) {
                    isFloating = true
                }
            }
    }
}

struct Onboarding08_TrialOfferScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background as other screens
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),  // Warm cream
                        Color(hex: "F5EFE7")   // Soft beige
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: geometry.size.height * 0.12)

                    // Headline Text
                    Text("We want you to try Blissful for free.")
                        .font(.system(size: geometry.size.height * 0.035, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(width: geometry.size.width * 0.8)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)

                    // Spacing
                    Spacer()
                        .frame(height: geometry.size.height * 0.08)

                    // Device Mockup (40-45% of screen height)
                    AppUIShowcaseView()
                        .frame(height: geometry.size.height * 0.42)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.9)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: showContent)

                    Spacer()

                    // No payment text
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "C8D4C8"))

                        Text("No payment due now")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "6B6B6B"))
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                    Spacer()
                        .frame(height: 16)

                    // Try it for $0.00 Button
                    Button(action: onContinue) {
                        Text("Try it for $0.00")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                    Spacer()
                        .frame(height: 80)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
        }
    }
}

// MARK: - App UI Showcase
struct AppUIShowcaseView: View {
    @State private var currentFeature = 0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Modern phone frame - clean design without weird notch
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(hex: "1C1C1E"))
                .frame(width: 200, height: 400)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .frame(width: 184, height: 384)
                        .overlay(
                            // App content showcase
                            Group {
                                switch currentFeature {
                                case 0:
                                    FeatureShowcase1()
                                case 1:
                                    FeatureShowcase2()
                                default:
                                    FeatureShowcase3()
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)

            // Feature labels - properly positioned below phone
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Text(["Budget Tracking", "Guest Management", "Timeline Planning"][index])
                        .font(.system(size: 11, weight: .light, design: .serif))
                        .foregroundColor(currentFeature == index ? Color(hex: "2C2C2C") : Color(hex: "9B9B9B"))
                        .opacity(isAnimating ? 1 : 0.7)
                }
            }
        }
        .onAppear {
            isAnimating = true
            startShowcase()
        }
    }

    private func startShowcase() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentFeature = (currentFeature + 1) % 3
            }
        }
    }
}

// MARK: - Feature Showcases
struct FeatureShowcase1: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Budget Overview")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("$45,000 of $50,000")
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
            .padding(.top, 30)

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color(hex: "F0F0F0"), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.9)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "D4B5A9"), Color(hex: "C8A89C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Text("90%")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
            }

            // Budget categories
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill([Color(hex: "D4B5A9"), Color(hex: "C8D4C8"), Color(hex: "C8D4E8")][index])
                            .frame(width: 8, height: 8)

                        Text(["Venue & Catering", "Photography", "Flowers & Decor"][index])
                            .font(.system(size: 10, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "6B6B6B"))

                        Spacer()

                        Text(["$20,000", "$6,000", "$4,500"][index])
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .frame(width: 184, height: 384)
    }
}

struct FeatureShowcase2: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Guest List")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                HStack(spacing: 20) {
                    VStack {
                        Text("142")
                            .font(.system(size: 14, weight: .light, design: .serif))
                        Text("Invited")
                            .font(.system(size: 8, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }

                    VStack {
                        Text("89")
                            .font(.system(size: 14, weight: .light, design: .serif))
                        Text("Confirmed")
                            .font(.system(size: 8, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }
            }
            .padding(.top, 30)

            // Guest entries
            VStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color(hex: "E8E8E8"))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(["JS", "MR", "AL", "DW", "KL", "PT"][index])
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(Color(hex: "6B6B6B"))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(["John & Sarah", "Mike Roberts", "Anna Lee", "David Wilson", "Kate Lewis", "Paul Taylor"][index])
                                .font(.system(size: 11, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text(["Party of 2", "Plus one", "Solo", "Party of 3", "Plus one", "Solo"][index])
                                .font(.system(size: 8, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        Spacer()

                        Circle()
                            .fill(index < 4 ? Color(hex: "C8D4C8") : Color(hex: "F0F0F0"))
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .frame(width: 184, height: 384)
    }
}

struct FeatureShowcase3: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Wedding Timeline")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .padding(.top, 30)

            // Timeline items
            VStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        // Time indicator
                        VStack {
                            Circle()
                                .fill(index < 2 ? Color(hex: "C8D4C8") : Color(hex: "E8E8E8"))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )

                            if index < 4 {
                                Rectangle()
                                    .fill(Color(hex: "E8E8E8"))
                                    .frame(width: 1, height: 20)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(["2:00 PM", "2:30 PM", "4:00 PM", "6:00 PM", "8:00 PM"][index])
                                .font(.system(size: 10, weight: .medium, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text(["Guest Arrival", "Ceremony", "Cocktail Hour", "Reception", "First Dance"][index])
                                .font(.system(size: 12, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "6B6B6B"))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .frame(width: 184, height: 384)
    }
}

struct Onboarding09_NotificationScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),  // Warm cream
                        Color(hex: "F5EFE7")   // Soft beige
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    // Top spacing to upper third
                    Spacer()
                        .frame(height: geometry.size.height * 0.15)

                    // Headline Text (4-5% of screen height)
                    Text("Set a reminder before your free trial ends.")
                        .font(.system(size: geometry.size.height * 0.045, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(width: geometry.size.width * 0.8)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)

                    // Spacing to center
                    Spacer()
                        .frame(height: geometry.size.height * 0.12)

                    // Animated Notification Bell (20-25% of screen height)
                    AnimatedNotificationBell()
                        .frame(height: geometry.size.height * 0.22)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: showContent)

                    Spacer()

                    // No payment text
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "C8D4C8"))

                        Text("No payment due now")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "6B6B6B"))
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                    Spacer()
                        .frame(height: 16)

                    // Proceed for free Button
                    Button(action: {
                        // Schedule smart notifications when user proceeds
                        scheduleSmartNotifications()
                        onContinue()
                    }) {
                        Text("Proceed for free")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                    Spacer()
                        .frame(height: 80)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
        }
    }

    private func scheduleSmartNotifications() {
        TrialNotificationManager.shared.scheduleSmartTrialNotifications()
    }
}

// MARK: - Animated Notification Bell
struct AnimatedNotificationBell: View {
    @State private var isRinging = false
    @State private var showNotificationDot = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Notification glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale)
                .blur(radius: 8)

            // Main bell icon
            Image(systemName: "bell.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD700"),  // Gold
                            Color(hex: "FFA500")   // Orange
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 12, x: 0, y: 6)

            // Notification dot
            if showNotificationDot {
                Circle()
                    .fill(Color(hex: "FF4444"))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .offset(x: 25, y: -25)
                    .scaleEffect(isRinging ? 1.2 : 1.0)
            }

            // Animated notification lines
            ForEach(0..<3, id: \.self) { index in
                NotificationWave(delay: Double(index) * 0.3)
                    .offset(x: 35, y: -35)
            }
        }
        .onAppear {
            startBellAnimation()
        }
    }

    private func startBellAnimation() {
        // Show notification dot
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showNotificationDot = true
        }

        // Bell ringing animation
        withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true).delay(0.8)) {
            rotation = 15
            isRinging = true
        }

        // Pulse glow effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            pulseScale = 1.2
        }
    }
}

// MARK: - Notification Wave Animation
struct NotificationWave: View {
    let delay: Double
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "FFD700"), lineWidth: 2)
                .frame(width: 20, height: 20)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(delay)) {
                scale = 2.0
                opacity = 0.0
            }
        }
    }
}

// MARK: - Smart Trial Notification Manager
class TrialNotificationManager {
    static let shared = TrialNotificationManager()
    private let notificationManager = NotificationManager.shared

    func scheduleSmartTrialNotifications() {
        // Clear any existing trial notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: getTrialNotificationIds())

        // Schedule daily engagement notifications (days 1-6)
        scheduleEngagementNotifications()

        // Schedule trial reminder (day 5 - 2 days before 7-day trial ends)
        scheduleTrialReminderNotification()

        // Schedule final reminder (day 6 - 1 day before trial ends)
        scheduleFinalReminderNotification()
    }

    private func scheduleEngagementNotifications() {
        let engagementMessages = [
            "Welcome to Blissful! Ready to start planning your perfect day? 💕",
            "Your wedding countdown has begun! Check your timeline today ✨",
            "How's your budget looking? Track your spending with ease 💰",
            "Don't forget to add your guests! Manage RSVPs effortlessly 👥",
            "Tasks keeping you organized? Mark off what you've completed ✅",
            "Your wedding plans are coming together beautifully! 🌸"
        ]

        for day in 1...6 {
            let content = UNMutableNotificationContent()
            content.title = "Your Wedding Planning Journey"
            content.body = engagementMessages[day - 1]
            content.sound = .default
            content.categoryIdentifier = "ENGAGEMENT"

            // Schedule for 7 PM each day
            let triggerDate = Calendar.current.date(byAdding: .day, value: day, to: Date())!
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            dateComponents.hour = 19
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "engagement_day_\(day)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    private func scheduleTrialReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Your Free Trial Ends Soon"
        content.body = "Only 2 days left! Continue planning your dream wedding with full access to all features 💍"
        content.sound = .default
        content.categoryIdentifier = "TRIAL_REMINDER"
        content.userInfo = ["type": "trial_reminder"]

        // Schedule for day 5 (2 days before trial ends) at 10 AM
        let triggerDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trial_reminder_main",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleFinalReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Last Day of Your Free Trial"
        content.body = "Your trial ends tomorrow. Keep planning your perfect wedding day! 🎊"
        content.sound = .default
        content.categoryIdentifier = "FINAL_REMINDER"
        content.userInfo = ["type": "final_reminder"]

        // Schedule for day 6 (1 day before trial ends) at 6 PM
        let triggerDate = Calendar.current.date(byAdding: .day, value: 6, to: Date())!
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trial_reminder_final",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // When user purchases premium, call this to cancel trial reminders
    func cancelTrialReminders() {
        let trialIds = ["trial_reminder_main", "trial_reminder_final"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: trialIds)
    }

    private func getTrialNotificationIds() -> [String] {
        var ids = ["trial_reminder_main", "trial_reminder_final"]
        for day in 1...6 {
            ids.append("engagement_day_\(day)")
        }
        return ids
    }
}

struct Onboarding10_TrialTimelineScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),  // Warm cream
                        Color(hex: "F5EFE7")   // Soft beige
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer(minLength: 20)

                    // Hero animation section
                    TrialHeroAnimation()
                        .frame(height: 100)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.9)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showContent)

                    Spacer()
                        .frame(height: 50)

                    // Headline
                    Text("How does your free trial work?")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)

                    Spacer()
                        .frame(height: 30)

                    // Timeline
                    TrialTimeline()
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                    Spacer(minLength: 20)

                    // Continue Button
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        onContinue()
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
        }
    }
}

// MARK: - Trial Hero Animation
struct TrialHeroAnimation: View {
    @State private var currentStep = 0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .frame(width: 300, height: 180)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)

            // Content that changes
            Group {
                switch currentStep {
                case 0:
                    TrialStep1Preview()
                case 1:
                    TrialStep2Preview()
                default:
                    TrialStep3Preview()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))

            // Floating trial badge
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "C8D4C8"))

                Text("Free Trial")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .offset(x: 110, y: -70)
        }
        .onAppear {
            startDemo()
        }
    }

    private func startDemo() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentStep = (currentStep + 1) % 3
            }
        }
    }
}

// MARK: - Trial Preview Steps
struct TrialStep1Preview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Today")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .padding(.top, 20)

            Image(systemName: "lock.open.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "C8D4C8"))

            Text("Full Access Unlocked")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(Color(hex: "6B6B6B"))

            Spacer()
        }
        .frame(width: 300, height: 180)
    }
}

struct TrialStep2Preview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("In 2 Days")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .padding(.top, 20)

            Image(systemName: "bell.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "FFD700"))

            Text("Still Free! Keep Enjoying")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(Color(hex: "6B6B6B"))

            Spacer()
        }
        .frame(width: 300, height: 180)
    }
}

struct TrialStep3Preview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("In 3 Days")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .padding(.top, 20)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "D4B5A9"))

            Text("Choose to Continue")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(Color(hex: "6B6B6B"))

            Spacer()
        }
        .frame(width: 300, height: 180)
    }
}

// MARK: - Trial Timeline
struct TrialTimeline: View {
    var body: some View {
        VStack(spacing: 20) {
            // Step 1: Today
            TimelineStep(
                icon: "lock.open.fill",
                iconColor: Color(hex: "C8D4C8"),
                title: "Today",
                description: "Budget tracking, guest management & more.",
                isLast: false
            )

            // Step 2: In 2 Days
            TimelineStep(
                icon: "bell.fill",
                iconColor: Color(hex: "FFD700"),
                title: "In 2 Days",
                description: "It's still free! Enjoy.",
                isLast: false
            )

            // Step 3: In 3 Days
            TimelineStep(
                icon: "checkmark.circle.fill",
                iconColor: Color(hex: "D4B5A9"),
                title: "In 3 Days",
                description: "You won't be charged beforehand. You can cancel earlier.",
                isLast: true
            )
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Timeline Step Component
struct TimelineStep: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with connecting line
            VStack(spacing: 0) {
                // Icon - smaller
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }

                // Connecting line (if not last) - shorter
                if !isLast {
                    Rectangle()
                        .fill(Color(hex: "E8E8E8"))
                        .frame(width: 2, height: 28)
                        .padding(.top, 6)
                }
            }

            // Content - more compact
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .lineSpacing(2)

                // Spacer to match icon height if not last - shorter
                if !isLast {
                    Spacer()
                        .frame(height: 20)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Navigation Component

struct OnboardingNavigation: View {
    @Binding var currentScreen: Int
    let totalScreens: Int
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<totalScreens, id: \.self) { index in
                    Circle()
                        .fill(currentScreen == index ? Color(hex: "D4B5A9") : Color(hex: "E8E8E8"))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentScreen)
                }
            }

            // Navigation buttons
            HStack {
                // Back button
                if currentScreen > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen -= 1
                        }
                    }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                } else {
                    Spacer()
                        .frame(width: 60)
                }

                Spacer()

                // Next/Complete button
                Button(action: {
                    if currentScreen < totalScreens - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    Text(currentScreen == totalScreens - 1 ? "Get Started" : "Next")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "D4B5A9"))
                        )
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Setup Screens

struct Onboarding03_WeddingBasicsScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var firstName = ""
    @State private var secondName = ""
    @State private var weddingDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // Default to 1 year from now
    @State private var venue = ""
    @State private var canContinue = false
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var isInputFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "F5EFE7")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: max(60, geometry.size.height * 0.1))

                        // Elegant icon
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)

                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(Color(hex: "D4B5A9"))
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showContent)

                            // Title
                            VStack(spacing: 8) {
                                Text("Tell us about your")
                                    .font(.system(size: 24, weight: .light, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text("SPECIAL DAY")
                                    .font(.system(size: 32, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                            }
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                        }

                        Spacer()
                            .frame(height: 50)

                        // Elegant Form Fields
                        VStack(spacing: 32) {
                            // Couple Names - Split into two fields
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "D4B5A9"))

                                    Text("Who's getting married?")
                                        .font(.system(size: 15, weight: .medium, design: .serif))
                                        .foregroundColor(Color(hex: "6B6B6B"))
                                }

                                VStack(spacing: 16) {
                                    TextField("First person's name", text: $firstName)
                                        .font(.system(size: 18, weight: .regular, design: .serif))
                                        .foregroundColor(Color(hex: "1A1A1A"))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 18)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                                                )
                                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                        )
                                        .focused($isInputFocused)
                                        .onChange(of: firstName) { _, _ in
                                            checkCanContinue()
                                        }

                                    TextField("Second person's name", text: $secondName)
                                        .font(.system(size: 18, weight: .regular, design: .serif))
                                        .foregroundColor(Color(hex: "1A1A1A"))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 18)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                                                )
                                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                        )
                                        .focused($isInputFocused)
                                        .onChange(of: secondName) { _, _ in
                                            checkCanContinue()
                                        }
                                }
                            }

                            // Wedding Date
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "D4B5A9"))

                                    Text("When's the big day?")
                                        .font(.system(size: 15, weight: .medium, design: .serif))
                                        .foregroundColor(Color(hex: "6B6B6B"))
                                }

                                DatePicker("", selection: $weddingDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                    )
                            }

                            // Venue (Optional)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "D4B5A9"))

                                    Text("Where will it happen?")
                                        .font(.system(size: 15, weight: .medium, design: .serif))
                                        .foregroundColor(Color(hex: "6B6B6B"))
                                }

                                TextField("Venue name (optional)", text: $venue)
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                    )
                                    .focused($isInputFocused)
                            }
                        }
                        .padding(.horizontal, 30)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)

                        Spacer()
                            .frame(height: 50)

                        // Continue Button
                        Button(action: {
                            isInputFocused = false
                            saveWeddingBasics()
                            onContinue()
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(canContinue ? Color(hex: "2C2C2C") : Color(hex: "9B9B9B"))
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    Capsule()
                                        .fill(canContinue ? Color.white : Color(hex: "F0F0F0"))
                                        .shadow(color: Color.black.opacity(canContinue ? 0.1 : 0.05), radius: 8, x: 0, y: 4)
                                )
                        }
                        .disabled(!canContinue)
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                        Spacer()
                            .frame(height: max(100, geometry.size.height * 0.15))
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea(.all)
        .onTapGesture {
            isInputFocused = false
        }
        .onAppear {
            showContent = true
            checkCanContinue()
        }
    }

    private func checkCanContinue() {
        canContinue = !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                     !secondName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveWeddingBasics() {
        // Save individual names
        UserDefaults.standard.set(firstName, forKey: "onboarding_firstName")
        UserDefaults.standard.set(secondName, forKey: "onboarding_secondName")

        // Also save combined names for backwards compatibility
        let coupleNames = "\(firstName) & \(secondName)"
        UserDefaults.standard.set(coupleNames, forKey: "onboarding_coupleNames")

        UserDefaults.standard.set(weddingDate, forKey: "onboarding_weddingDate")
        if !venue.isEmpty {
            UserDefaults.standard.set(venue, forKey: "onboarding_venue")
        }
    }
}

struct Onboarding04_BudgetSetupScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var totalBudget = ""
    @State private var canContinue = false
    @EnvironmentObject var dataManager: DataManager

    // Pre-selected popular budget ranges
    private let budgetRanges = [
        (label: "$10K - $20K", value: 15000.0),
        (label: "$20K - $35K", value: 27500.0),
        (label: "$35K - $50K", value: 42500.0),
        (label: "$50K - $75K", value: 62500.0),
        (label: "$75K+", value: 90000.0)
    ]
    @State private var selectedBudgetRange: Double? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "F5EFE7")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer()

                    // Elegant icon
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)

                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color(hex: "D4B5A9"))
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showContent)

                        // Title
                        VStack(spacing: 8) {
                            Text("What's your")
                                .font(.system(size: 24, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text("DREAM BUDGET")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                        }
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                    }

                    Spacer()
                        .frame(height: 40)

                    // Budget Selection
                    VStack(spacing: 24) {
                        // Quick budget range selection
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "D4B5A9"))

                                Text("Popular budget ranges")
                                    .font(.system(size: 15, weight: .medium, design: .serif))
                                    .foregroundColor(Color(hex: "6B6B6B"))

                                Spacer()
                            }

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(budgetRanges, id: \.value) { range in
                                    Button(action: {
                                        selectedBudgetRange = range.value
                                        totalBudget = String(format: "%.0f", range.value)
                                        checkCanContinue()
                                    }) {
                                        Text(range.label)
                                            .font(.system(size: 16, weight: .medium, design: .serif))
                                            .foregroundColor(selectedBudgetRange == range.value ? .white : Color(hex: "2C2C2C"))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedBudgetRange == range.value ? Color(hex: "D4B5A9") : Color.white)
                                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                            )
                                    }
                                }
                            }
                        }

                        // OR divider
                        HStack {
                            Rectangle()
                                .fill(Color(hex: "E8E8E8"))
                                .frame(height: 1)

                            Text("OR")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "9B9B9B"))
                                .padding(.horizontal, 16)

                            Rectangle()
                                .fill(Color(hex: "E8E8E8"))
                                .frame(height: 1)
                        }

                        // Custom amount input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "D4B5A9"))

                                Text("Enter custom amount")
                                    .font(.system(size: 15, weight: .medium, design: .serif))
                                    .foregroundColor(Color(hex: "6B6B6B"))
                            }

                            HStack {
                                Text("$")
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                TextField("50,000", text: $totalBudget)
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                                    .keyboardType(.numberPad)
                                    .onChange(of: totalBudget) { _, _ in
                                        selectedBudgetRange = nil
                                        checkCanContinue()
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)

                    Spacer(minLength: 30)

                    // Continue Button
                    Button(action: {
                        saveBudgetInfo()
                        onContinue()
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(canContinue ? Color(hex: "2C2C2C") : Color(hex: "9B9B9B"))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(canContinue ? Color.white : Color(hex: "F0F0F0"))
                                    .shadow(color: Color.black.opacity(canContinue ? 0.1 : 0.05), radius: 8, x: 0, y: 4)
                            )
                    }
                    .disabled(!canContinue)
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
            checkCanContinue()
        }
    }

    private func checkCanContinue() {
        let budgetText = totalBudget.trimmingCharacters(in: .whitespacesAndNewlines)
        if let budgetValue = Double(budgetText.replacingOccurrences(of: ",", with: "")), budgetValue > 0 {
            canContinue = true
        } else {
            canContinue = selectedBudgetRange != nil
        }
    }

    private func saveBudgetInfo() {
        let finalBudget: Double

        if let selected = selectedBudgetRange {
            finalBudget = selected
        } else if let budgetValue = Double(totalBudget.replacingOccurrences(of: ",", with: "")) {
            finalBudget = budgetValue
        } else {
            finalBudget = 0
        }

        UserDefaults.standard.set(finalBudget, forKey: "onboarding_totalBudget")
    }
}

struct Onboarding05_GuestCountScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var guestCount = 100
    @State private var canContinue = true
    @EnvironmentObject var dataManager: DataManager

    // Pre-selected guest count ranges
    private let guestRanges = [
        (label: "Intimate\n25 or fewer", value: 20),
        (label: "Small\n26-75 guests", value: 50),
        (label: "Medium\n76-150 guests", value: 100),
        (label: "Large\n151-300 guests", value: 200),
        (label: "Grand\n300+ guests", value: 350)
    ]
    @State private var selectedGuestRange: Int? = 100

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "F5EFE7")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: max(60, geometry.size.height * 0.1))

                        // Elegant icon
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)

                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(Color(hex: "D4B5A9"))
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showContent)

                            // Title
                            VStack(spacing: 8) {
                                Text("How many guests")
                                    .font(.system(size: 24, weight: .light, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text("ARE YOU EXPECTING?")
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                            }
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                        }

                        Spacer()
                            .frame(height: 40)

                        // Guest Count Selection
                        VStack(spacing: 32) {
                            // Quick guest count selection
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "D4B5A9"))

                                    Text("Popular wedding sizes")
                                        .font(.system(size: 15, weight: .medium, design: .serif))
                                        .foregroundColor(Color(hex: "6B6B6B"))

                                    Spacer()
                                }

                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(guestRanges, id: \.value) { range in
                                        Button(action: {
                                            selectedGuestRange = range.value
                                            guestCount = range.value
                                        }) {
                                            VStack(spacing: 8) {
                                                Text(range.label)
                                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                                    .foregroundColor(selectedGuestRange == range.value ? .white : Color(hex: "2C2C2C"))
                                                    .multilineTextAlignment(.center)
                                                    .lineSpacing(2)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 70)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedGuestRange == range.value ? Color(hex: "D4B5A9") : Color.white)
                                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                            )
                                        }
                                    }
                                }
                            }

                            // OR divider
                            HStack {
                                Rectangle()
                                    .fill(Color(hex: "E8E8E8"))
                                    .frame(height: 1)

                                Text("OR")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                                    .padding(.horizontal, 16)

                                Rectangle()
                                    .fill(Color(hex: "E8E8E8"))
                                    .frame(height: 1)
                            }

                            // Custom slider input
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "D4B5A9"))

                                    Text("Choose exact number")
                                        .font(.system(size: 15, weight: .medium, design: .serif))
                                        .foregroundColor(Color(hex: "6B6B6B"))
                                }

                                VStack(spacing: 16) {
                                    // Current count display
                                    Text("\(guestCount)")
                                        .font(.system(size: 48, weight: .light, design: .serif))
                                        .foregroundColor(Color(hex: "2C2C2C"))

                                    Text("guests")
                                        .font(.system(size: 16, weight: .regular, design: .serif))
                                        .foregroundColor(Color(hex: "6B6B6B"))

                                    // Slider
                                    VStack(spacing: 12) {
                                        Slider(value: Binding(
                                            get: { Double(guestCount) },
                                            set: { guestCount = Int($0) }
                                        ), in: 10...500, step: 5)
                                        .tint(Color(hex: "D4B5A9"))
                                        .onChange(of: guestCount) { _, _ in
                                            selectedGuestRange = nil
                                        }

                                        HStack {
                                            Text("10")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(Color(hex: "9B9B9B"))
                                            Spacer()
                                            Text("500")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(Color(hex: "9B9B9B"))
                                        }
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)

                        Spacer()
                            .frame(height: 50)

                        // Continue Button
                        Button(action: {
                            saveGuestCount()
                            onContinue()
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)

                        Spacer()
                            .frame(height: max(100, geometry.size.height * 0.15))
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
        }
    }

    private func saveGuestCount() {
        UserDefaults.standard.set(guestCount, forKey: "onboarding_guestCount")
    }
}

struct Onboarding06_PrioritiesScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var selectedPriorities = Set<WeddingPriority>()
    @State private var canContinue = false
    @EnvironmentObject var dataManager: DataManager

    // Wedding priorities with icons and descriptions
    private let priorities = [
        WeddingPriority(id: "photography", name: "Photography", icon: "camera.fill", description: "Capturing every moment"),
        WeddingPriority(id: "venue", name: "Venue", icon: "building.2.fill", description: "The perfect setting"),
        WeddingPriority(id: "food", name: "Food & Drinks", icon: "fork.knife", description: "Amazing dining experience"),
        WeddingPriority(id: "music", name: "Music & Entertainment", icon: "music.note", description: "Dancing all night"),
        WeddingPriority(id: "flowers", name: "Flowers & Decor", icon: "leaf.fill", description: "Beautiful aesthetics"),
        WeddingPriority(id: "attire", name: "Attire & Beauty", icon: "tshirt.fill", description: "Looking your best"),
        WeddingPriority(id: "guest_experience", name: "Guest Experience", icon: "heart.fill", description: "Everyone having fun"),
        WeddingPriority(id: "budget", name: "Staying on Budget", icon: "dollarsign.circle.fill", description: "Financial peace of mind")
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "F5EFE7")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: max(60, geometry.size.height * 0.08))

                        // Elegant icon
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)

                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(Color(hex: "D4B5A9"))
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showContent)

                            // Title
                            VStack(spacing: 8) {
                                Text("What matters")
                                    .font(.system(size: 24, weight: .light, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text("MOST TO YOU?")
                                    .font(.system(size: 32, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                            }
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)

                            Text("Select 2-4 things that are most important for your special day")
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "6B6B6B"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
                        }

                        Spacer()
                            .frame(height: 40)

                        // Priorities Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(Array(priorities.enumerated()), id: \.element.id) { index, priority in
                                PriorityCard(
                                    priority: priority,
                                    isSelected: selectedPriorities.contains(priority)
                                ) {
                                    togglePriority(priority)
                                }
                                .opacity(showContent ? 1 : 0)
                                .scaleEffect(showContent ? 1 : 0.9)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.7)
                                    .delay(0.4 + Double(index) * 0.05),
                                    value: showContent
                                )
                            }
                        }
                        .padding(.horizontal, 30)

                        Spacer()
                            .frame(height: 50)

                        // Continue Button
                        Button(action: {
                            savePriorities()
                            onContinue()
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(canContinue ? Color(hex: "2C2C2C") : Color(hex: "9B9B9B"))
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    Capsule()
                                        .fill(canContinue ? Color.white : Color(hex: "F0F0F0"))
                                        .shadow(color: Color.black.opacity(canContinue ? 0.1 : 0.05), radius: 8, x: 0, y: 4)
                                )
                        }
                        .disabled(!canContinue)
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                        Spacer()
                            .frame(height: max(100, geometry.size.height * 0.1))
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            showContent = true
        }
    }

    private func togglePriority(_ priority: WeddingPriority) {
        if selectedPriorities.contains(priority) {
            selectedPriorities.remove(priority)
        } else if selectedPriorities.count < 4 {
            selectedPriorities.insert(priority)
        }
        canContinue = selectedPriorities.count >= 2
    }

    private func savePriorities() {
        let priorityIds = selectedPriorities.map { $0.id }
        UserDefaults.standard.set(priorityIds, forKey: "onboarding_priorities")
    }
}

struct WeddingPriority: Hashable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
}

struct PriorityCard: View {
    let priority: WeddingPriority
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: priority.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "D4B5A9"))

                VStack(spacing: 4) {
                    Text(priority.name)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(isSelected ? .white : Color(hex: "2C2C2C"))
                        .multilineTextAlignment(.center)

                    Text(priority.description)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundColor(isSelected ? Color.white.opacity(0.9) : Color(hex: "6B6B6B"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "D4B5A9") : Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 6 : 4)
            )
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct Onboarding07_InitialTasksScreen: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var initialTasks: [InitialTask] = []
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "F8F4F0"),
                        Color(hex: "F5EFE7")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea(.all)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: max(60, geometry.size.height * 0.08))

                        // Elegant icon
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(Color(hex: "D4B5A9"))
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showContent)

                            // Title
                            VStack(spacing: 8) {
                                Text("Your personalized")
                                    .font(.system(size: 24, weight: .light, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text("FIRST STEPS")
                                    .font(.system(size: 32, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                            }
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)

                            Text("Based on your priorities, here are your next tasks")
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "6B6B6B"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
                        }

                        Spacer()
                            .frame(height: 40)

                        // Tasks List
                        VStack(spacing: 16) {
                            ForEach(Array(initialTasks.enumerated()), id: \.element.id) { index, task in
                                InitialTaskCard(task: task, index: index + 1)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(x: showContent ? 0 : 30)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(0.4 + Double(index) * 0.1),
                                        value: showContent
                                    )
                            }
                        }
                        .padding(.horizontal, 30)

                        Spacer()
                            .frame(height: 50)

                        // Continue Button
                        Button(action: {
                            createWeddingWithData()
                            onContinue()
                        }) {
                            Text("Start Planning!")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                        }
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)

                        Spacer()
                            .frame(height: max(100, geometry.size.height * 0.1))
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            generateInitialTasks()
            showContent = true
        }
    }

    private func generateInitialTasks() {
        // Get saved data from UserDefaults
        let priorities = UserDefaults.standard.array(forKey: "onboarding_priorities") as? [String] ?? []
        let weddingDate = UserDefaults.standard.object(forKey: "onboarding_weddingDate") as? Date ?? Date()
        let daysUntilWedding = Calendar.current.dateComponents([.day], from: Date(), to: weddingDate).day ?? 365

        // Generate tasks based on priorities and timeline
        var tasks: [InitialTask] = []

        // Always include essential tasks
        tasks.append(InitialTask(
            id: "budget_review",
            title: "Review Your Budget Breakdown",
            description: "See how your budget is allocated across different categories",
            category: "budget",
            priority: 1,
            estimatedTime: "10 min"
        ))

        // Priority-based tasks
        if priorities.contains("venue") {
            tasks.append(InitialTask(
                id: "venue_research",
                title: "Start Venue Research",
                description: "Browse venues that match your style and guest count",
                category: "venue",
                priority: 2,
                estimatedTime: "30 min"
            ))
        }

        if priorities.contains("photography") {
            tasks.append(InitialTask(
                id: "photographer_research",
                title: "Find Your Photographer",
                description: "Look for photographers whose style matches your vision",
                category: "photography",
                priority: 2,
                estimatedTime: "45 min"
            ))
        }

        if priorities.contains("food") {
            tasks.append(InitialTask(
                id: "catering_style",
                title: "Choose Catering Style",
                description: "Decide between plated dinner, buffet, or cocktail reception",
                category: "catering",
                priority: 3,
                estimatedTime: "15 min"
            ))
        }

        // Timeline-based tasks
        if daysUntilWedding > 300 {
            tasks.append(InitialTask(
                id: "save_dates",
                title: "Design Save the Dates",
                description: "Create and send save the dates to your guest list",
                category: "invitations",
                priority: 3,
                estimatedTime: "20 min"
            ))
        }

        // Always end with guest list
        tasks.append(InitialTask(
            id: "guest_list",
            title: "Finalize Guest List",
            description: "Add contact details and manage RSVPs",
            category: "guests",
            priority: 4,
            estimatedTime: "25 min"
        ))

        // Take first 5 tasks
        initialTasks = Array(tasks.prefix(5))
    }

    private func createWeddingWithData() {
        // Get all saved onboarding data
        let firstName = UserDefaults.standard.string(forKey: "onboarding_firstName") ?? ""
        let secondName = UserDefaults.standard.string(forKey: "onboarding_secondName") ?? ""
        let coupleNames = "\(firstName) & \(secondName)"
        let weddingDate = UserDefaults.standard.object(forKey: "onboarding_weddingDate") as? Date ?? Date()
        let venue = UserDefaults.standard.string(forKey: "onboarding_venue")
        let totalBudget = UserDefaults.standard.double(forKey: "onboarding_totalBudget")
        let guestCount = UserDefaults.standard.integer(forKey: "onboarding_guestCount")
        let priorities = UserDefaults.standard.array(forKey: "onboarding_priorities") as? [String] ?? []

        // Convert initial tasks to InitialTaskData
        let taskDataArray = initialTasks.map { task in
            InitialTaskData(
                id: task.id,
                title: task.title,
                description: task.description,
                category: task.category,
                priority: task.priority,
                estimatedTime: task.estimatedTime
            )
        }

        // Create the wedding with all collected data
        dataManager.createWeddingWithDetails(
            coupleNames: coupleNames,
            date: weddingDate,
            budget: totalBudget,
            guestCount: guestCount,
            venue: venue,
            priorities: priorities,
            initialTasks: taskDataArray
        )

        // Clean up onboarding data
        let keys = ["onboarding_firstName", "onboarding_secondName", "onboarding_coupleNames",
                   "onboarding_weddingDate", "onboarding_venue", "onboarding_totalBudget",
                   "onboarding_guestCount", "onboarding_priorities"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}

struct InitialTask: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let priority: Int
    let estimatedTime: String
}

struct InitialTaskCard: View {
    let task: InitialTask
    let index: Int

    var body: some View {
        HStack(spacing: 16) {
            // Task number
            ZStack {
                Circle()
                    .fill(Color(hex: "D4B5A9"))
                    .frame(width: 32, height: 32)

                Text("\(index)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }

            // Task content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    Spacer()

                    Text(task.estimatedTime)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "F0F0F0"))
                        )
                }

                Text(task.description)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    OnboardingView()
}