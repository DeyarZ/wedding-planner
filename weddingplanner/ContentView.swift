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
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTab = 0
    @State private var showNotificationPermission = false
    @State private var showOnboarding = false
    @State private var showPaywall = false

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
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
                    PaywallView(isPresented: $showPaywall)
                }
            }
        }
        .onAppear {
            dataManager.setup(modelContext: modelContext)

            // Check if this is the first launch
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            if !hasCompletedOnboarding {
                showOnboarding = true
            } else {
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

            // Check if this is first launch for notifications
            let hasAskedForNotifications = UserDefaults.standard.bool(forKey: "hasAskedForNotifications")
            if !hasAskedForNotifications && !notificationManager.hasPermission {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showNotificationPermission = true
                    UserDefaults.standard.set(true, forKey: "hasAskedForNotifications")
                }
            }

            // Schedule daily motivation if permissions granted
            if notificationManager.hasPermission {
                notificationManager.scheduleRandomMotivation()
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowPaywall"))) { _ in
            showPaywall = true
        }
        .fullScreenCover(isPresented: $showNotificationPermission) {
            NotificationPermissionView(showPermissionScreen: $showNotificationPermission)
                .environmentObject(notificationManager)
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
                    title: items[index],
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
    let title: String
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
        .modelContainer(for: [Wedding.self, Vendor.self, Guest.self, WeddingTask.self, BudgetItem.self, Transaction.self, PlusOne.self, VendorPayment.self, VendorCommunication.self])
}