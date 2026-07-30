//
//  ContentView.swift
//  weddingplanner
//
//  Created by Deyar Zakir on 23.09.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager = DataManager()
    @ObservedObject private var feedbackManager = FeedbackManager.shared
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @State private var paywallSource: Analytics.PaywallSource = .coldStart
    /// Set only when the paywall was opened by a feature gate that could not
    /// present its own upsell sheet.
    @State private var paywallGate: PremiumGate? = nil

    /// Timestamp (seconds since 1970) of the last cold-start paywall. Persisted
    /// so it survives relaunches — as @State it reset every launch and the
    /// paywall was shown on EVERY cold start.
    @AppStorage("lastColdStartPaywallAt") private var lastColdStartPaywallAt: Double = 0

    /// At most one unprompted cold-start paywall per day.
    private let coldStartPaywallCooldown: TimeInterval = 24 * 60 * 60

    private var isPremiumUser: Bool { subscriptionManager.isSubscribed }

    private var canShowColdStartPaywall: Bool {
        Date().timeIntervalSince1970 - lastColdStartPaywallAt >= coldStartPaywallCooldown
    }

    private func syncWinBackNotification() {
        WinBackNotificationManager.shared.sync(
            weddingDate: dataManager.wedding?.date,
            isSubscribed: isPremiumUser
        )
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    // Onboarding completed callback
                    showOnboarding = false
                    // The paywall is the third page of the pre-paywall sequence
                    // (trial timeline → value recap → price), so it follows as
                    // quickly as the dismissal allows rather than feeling like a
                    // separate interruption after the app has appeared.
                    if !isPremiumUser {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            paywallSource = .postOnboarding
                            paywallGate = nil
                            showPaywall = true
                        }
                    }
                }
                .environmentObject(dataManager)
            } else {
                ZStack {
                // Ultra minimal background
                Color(hex: "FAFAFA")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Luxury header
                    LuxuryHeader()
                        .padding(.top, 60)
                        .padding(.horizontal, 32)

                    // Content
                    TabView(selection: $selectedTab) {
                        EmotionalDashboardView()
                            .tag(0)

                        // MoodBoardView()  // Temporarily disabled until Photo model fixed
                        //     .tag(1)

                        ProductionTimelineView()
                            .tag(1)

                        ProductionTeamView()
                            .tag(2)

                        ProductionGuestsView()
                            .tag(3)

                        ProductionFundsView()
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    // Ultra minimal navigation
                    LuxuryNavigation(selectedTab: $selectedTab)
                }
                }
                .preferredColorScheme(.light)
                .environmentObject(dataManager)
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallView(isPresented: $showPaywall, source: paywallSource, gate: paywallGate)
                }
                .sheet(isPresented: $feedbackManager.isPresented) {
                    FeedbackView()
                }
            }
        }
        .onAppear {
            dataManager.setup(modelContext: modelContext)
            feedbackManager.registerAppOpen()

            // Check if this is the first launch
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            if !hasCompletedOnboarding {
                showOnboarding = true
                // The post-onboarding paywall counts as today's impression, so a
                // cold-start paywall does not stack on top of it.
                lastColdStartPaywallAt = Date().timeIntervalSince1970
            } else {
                // Returning free users see the cold-start paywall at most once
                // per day instead of on every single launch.
                if !isPremiumUser && canShowColdStartPaywall {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        paywallSource = .coldStart
                        paywallGate = nil
                        showPaywall = true
                        lastColdStartPaywallAt = Date().timeIntervalSince1970
                    }
                }

                // Create a default wedding if none exists (for existing users)
                if !dataManager.hasWedding {
                    dataManager.createWedding(
                        coupleNames: "Emma & James",
                        date: Date().addingTimeInterval(180 * 24 * 60 * 60), // 6 months from now
                        budget: 50000,
                        guestCount: 150
                    )
                }
            }

            // Notification permission is NEVER requested from here. The single
            // request point is the primed screen in onboarding
            // (OnboardingNotificationScreen) — an unprimed prompt burns the
            // one-shot iOS dialog and tanks the opt-in rate.

            // Schedule daily motivation if permissions granted
            if notificationManager.hasPermission {
                notificationManager.scheduleRandomMotivation()
            }

            // T-60 win-back: reconciled on every launch, so a wedding date that
            // moved (or an expired trial) lands on the right day.
            syncWinBackNotification()

            // Gentle, infrequent feedback prompt for engaged users.
            // Defer so it never collides with onboarding / paywall flows.
            if !showOnboarding && !showPaywall && feedbackManager.shouldAutoPrompt() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if !showOnboarding && !showPaywall {
                        feedbackManager.requestFeedback()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChangeTab"))) { notification in
            if let userInfo = notification.userInfo,
               let tabIndex = userInfo["tab"] as? Int {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedTab = tabIndex
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPaywall"))) { notification in
            // Feature gates post this without a source; the win-back
            // notification posts `source = winback` so the two funnels stay
            // separable. A premium user never gets a paywall from here.
            let source = (notification.userInfo?["source"] as? String)
                .flatMap(Analytics.PaywallSource.init(rawValue:)) ?? .featureGate
            guard !isPremiumUser else { return }

            paywallSource = source
            paywallGate = (notification.userInfo?["gate"] as? String).flatMap(PremiumGate.init(rawValue:))
            showPaywall = true
        }
        .onChange(of: subscriptionManager.isSubscribed) { _, _ in
            // Entitlement resolved (or lapsed) — reconcile the T-60 win-back so
            // a paying user never gets it and a lapsed one gets it back.
            syncWinBackNotification()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowFeedback"))) { _ in
            feedbackManager.requestFeedback()
        }
    }
}

struct LuxuryHeader: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            // Time-based greeting
            VStack(alignment: .leading, spacing: 6) {
                Text(timeString)
                    .font(.system(size: 11, weight: .thin, design: .rounded))
                    .foregroundColor(Color(hex: "B8B8B8"))
                    .tracking(1)

                Text("YOUR WEDDING")
                    .font(.system(size: 12, weight: .thin, design: .serif))
                    .tracking(4)
                    .foregroundColor(Color(hex: "2C2C2C"))
            }

            Spacer()

            // Discreet feedback entry point
            Button {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowFeedback"),
                    object: nil
                )
            } label: {
                Image(systemName: "bubble.left")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "B8B8B8"))
            }
            .padding(.trailing, 14)

            // Minimal date
            if let wedding = dataManager.wedding {
                Text(wedding.date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.system(size: 11, weight: .thin, design: .rounded))
                    .foregroundColor(Color(hex: "B8B8B8"))
                    .tracking(1)
            }
        }
        .padding(.bottom, 20)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }
}

struct LuxuryNavigation: View {
    @Binding var selectedTab: Int
    @Namespace private var namespace

    let items = ["HOME", "TIME", "TEAM", "GUESTS", "FUNDS"]  // Temporarily removed VISION

    var body: some View {
        HStack(spacing: 30) {
            ForEach(0..<items.count, id: \.self) { index in
                LuxuryNavItem(
                    title: LocalizedStringKey(items[index]),
                    isSelected: selectedTab == index,
                    namespace: namespace,
                    action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 20, y: -10)
        )
    }
}

struct LuxuryNavItem: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 9, weight: .thin, design: .serif))
                    .tracking(2)
                    .foregroundColor(isSelected ? Color(hex: "2C2C2C") : Color(hex: "C4C4C4"))

                // Ultra thin indicator
                Rectangle()
                    .fill(Color(hex: "2C2C2C"))
                    .frame(width: 20, height: 0.5)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
        }
    }
}




#Preview {
    ContentView()
        .environmentObject(SubscriptionManager.shared)
        .modelContainer(for: [Wedding.self, Vendor.self, Guest.self, WeddingTask.self, BudgetItem.self, Transaction.self, PlusOne.self, VendorPayment.self, VendorCommunication.self])
}