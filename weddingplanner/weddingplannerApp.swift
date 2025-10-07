//
//  weddingplannerApp.swift
//  weddingplanner
//
//  Created by Deyar Zakir on 23.09.25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct WeddingPlannerApp: App {
    @StateObject private var notificationManager = NotificationManager.shared

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
                .onAppear {
                    // Clear badge when app opens
                    notificationManager.clearBadge()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}