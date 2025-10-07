import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var hasPermission = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissions()
    }

    // MARK: - Permission Management

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleDefaultNotifications()
                }
            }
        }
    }

    func checkPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleDefaultNotifications() {
        // Clear existing notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Schedule daily morning check-in
        scheduleDailyMorningCheckIn()

        // Schedule evening reflection
        scheduleEveningReflection()

        // Schedule weekly milestone
        scheduleWeeklyMilestone()
    }

    func scheduleDailyMorningCheckIn() {
        let content = UNMutableNotificationContent()
        let greetings = [
            "Good morning beautiful! Ready to plan your perfect day? 💕",
            "Rise and shine! Let's tackle today's wedding tasks together ✨",
            "Morning sunshine! Your wedding is getting closer 🌸",
            "Hello lovely! Time to make wedding magic happen today 💫",
            "Good morning! Every step brings you closer to 'I do' 💍"
        ]
        content.title = "Your Daily Wedding Check-in"
        content.body = greetings.randomElement() ?? greetings[0]
        content.sound = .default
        content.badge = 1

        // Schedule for 9 AM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily.morning", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleEveningReflection() {
        let content = UNMutableNotificationContent()
        content.title = "Evening Check-in"
        content.body = "You did amazing today! Take a moment to review tomorrow's tasks 🌙"
        content.sound = .default

        // Schedule for 8 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily.evening", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWeeklyMilestone() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Milestone"
        content.body = "Another week closer to your big day! Let's see your progress 🎉"
        content.sound = .default

        // Schedule for Sunday at 6 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly.milestone", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Task-Based Notifications

    func scheduleTaskReminder(for task: WeddingTask) {
        guard let dueDate = task.dueDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "\(task.title) is due today! Let's get it done 💪"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": task.id.hashValue]

        // Schedule for 10 AM on the due date
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task.\(task.id.hashValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleVendorAppointment(for vendor: Vendor, date: Date, notes: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Vendor Appointment"
        content.body = "Meeting with \(vendor.name) in 1 hour! \(notes ?? "")"
        content.sound = .default
        content.categoryIdentifier = "VENDOR_APPOINTMENT"
        content.userInfo = ["vendorId": vendor.id.hashValue]

        // Schedule for 1 hour before appointment
        let triggerDate = date.addingTimeInterval(-3600)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: triggerDate.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "vendor.\(vendor.id.hashValue).\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        if triggerDate > Date() {
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Milestone Notifications

    func scheduleMilestoneNotification(daysUntilWedding: Int) {
        let content = UNMutableNotificationContent()

        switch daysUntilWedding {
        case 365:
            content.title = "One Year to Go! 🎊"
            content.body = "Your wedding journey officially begins! Let's make this year amazing"
        case 180:
            content.title = "6 Months to Go! 💕"
            content.body = "Halfway there! Time to finalize those big decisions"
        case 90:
            content.title = "3 Months! 🌸"
            content.body = "The final stretch begins! Your dream day is so close"
        case 60:
            content.title = "2 Months! ✨"
            content.body = "Things are getting real! Let's nail these final details"
        case 30:
            content.title = "ONE MONTH! 💍"
            content.body = "30 days until you say 'I do'! How exciting is this?!"
        case 7:
            content.title = "ONE WEEK! 🎉"
            content.body = "7 days! Take a deep breath - you've got this!"
        case 1:
            content.title = "TOMORROW! 💕✨🎊"
            content.body = "Tomorrow you marry your best friend! Get some rest, beautiful bride!"
        case 0:
            content.title = "TODAY'S THE DAY! 👰"
            content.body = "Happy Wedding Day! Enjoy every magical moment! 💕"
        default:
            return
        }

        content.sound = .default
        content.badge = 1

        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone.\(daysUntilWedding)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Motivational Notifications

    func scheduleRandomMotivation() {
        let motivations = [
            "Your venue is going to look absolutely stunning! 🏰",
            "Remember: Perfect is not the goal, joy is! 💕",
            "You're doing an amazing job planning this wedding! ⭐",
            "Take a breath. Everything is falling into place beautifully ✨",
            "Your love story deserves this beautiful celebration! 💑",
            "The little details are adding up to something magical! 🌟",
            "You're going to be the most beautiful bride! 👰",
            "This stress is temporary, the marriage is forever! 💍"
        ]

        let content = UNMutableNotificationContent()
        content.title = "A Little Reminder"
        content.body = motivations.randomElement() ?? motivations[0]
        content.sound = .default

        // Random time between 2-5 PM
        let hour = Int.random(in: 14...17)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = Int.random(in: 0...59)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "motivation.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Delegate Methods

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo

        if let taskId = userInfo["taskId"] as? String {
            // Navigate to task detail
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenTask"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
        } else if let vendorId = userInfo["vendorId"] as? String {
            // Navigate to vendor detail
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenVendor"),
                object: nil,
                userInfo: ["vendorId": vendorId]
            )
        }

        completionHandler()
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}