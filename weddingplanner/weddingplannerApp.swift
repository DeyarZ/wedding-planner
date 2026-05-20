//
//  weddingplannerApp.swift
//  weddingplanner
//
//  Created by Deyar Zakir on 23.09.25.
//

import SwiftUI
import SwiftData
import UserNotifications
import StoreKit
import RevenueCat
import FacebookCore
import AppTrackingTransparency

@main
struct WeddingPlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        // Request notification permissions on first launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("✅ Notifications enabled")
            }
        }
    }
    var sharedModelContainer: ModelContainer = {
        // ALL models need to be included because of relationships
        let schema = Schema([
            Wedding.self,
            Vendor.self,
            Guest.self,
            WeddingTask.self,
            BudgetItem.self,
            Transaction.self,
            PlusOne.self,
            VendorPayment.self,
            VendorCommunication.self,
            DayScheduleEvent.self,
            VendorDocument.self
            // Photo.self  // Temporarily removed to debug
        ])

        // Use simple local configuration without CloudKit for now
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Disable CloudKit completely
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ Error creating ModelContainer: \(error)")
            // Try with in-memory as last resort to avoid crash
            let memoryConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                print("⚠️ Using in-memory storage as fallback")
                return try ModelContainer(for: schema, configurations: [memoryConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even with in-memory: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .environmentObject(subscriptionManager)
                .onAppear {
                    // Clear badge when app opens
                    notificationManager.clearBadge()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - AppDelegate (RevenueCat + Singular + Meta bootstrap)
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        SubscriptionManager.configure()

        // Meta SDK: set credentials from Config so the user only edits Config.swift.
        Settings.shared.appID = Config.metaAppID
        Settings.shared.clientToken = Config.metaClientToken
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        if let config = makeSingularConfig() {
            Singular.start(config)

            if let singularID = Singular.singularID() {
                Purchases.shared.attribution.setAttributes([
                    "singular_device_id": singularID
                ])
            }
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.shared.activateApp()

        // An ATT request already exists in OnboardingView (requestTrackingAuthorization).
        // Do not request again here; just reflect the current authorization status
        // into the Meta SDK so advertiser tracking matches the user's choice.
        let status = ATTrackingManager.trackingAuthorizationStatus
        Settings.shared.isAdvertiserTrackingEnabled = (status == .authorized)
    }

    private func makeSingularConfig() -> SingularConfig? {
        guard let config = SingularConfig(
            apiKey: Config.singularAPIKey,
            andSecret: Config.singularSecret
        ) else { return nil }

        config.waitForTrackingAuthorizationWithTimeoutInterval = 300
        config.skAdNetworkEnabled = true

        #if DEBUG
        config.enableLogging = true
        #endif

        config.conversionValuesUpdatedCallback = { conversionValue, coarse, lock in
            print("🎯 SKAN Conversion Value: \(conversionValue), Coarse: \(coarse?.stringValue ?? "nil"), Lock: \(lock)")
        }

        return config
    }
}
