import Foundation
import UserNotifications

// MARK: - Smart Trial Notification Manager
class TrialNotificationManager {
    static let shared = TrialNotificationManager()
    private let notificationManager = NotificationManager.shared

    /// Upper bound used when clearing engagement reminders, so a shorter trial
    /// still cleans up ids scheduled by an older/longer trial configuration.
    private static let maxEngagementDays = 14

    /// Welcome nudges WITHOUT any trial-ending reminder.
    ///
    /// Used when the current RevenueCat offering has no introductory offer at
    /// all: telling a user "your free trial ends tomorrow" when the store never
    /// gave them one is a trust-killer and contradicts the App Store. The
    /// trial-vs-no-trial test runs by swapping the offering, so this path is a
    /// first-class state, not an edge case.
    func scheduleEngagementOnlyNotifications(days: Int = 3) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: getTrialNotificationIds())
        scheduleEngagementNotifications(trialDays: max(1, days))
    }

    /// Schedules the trial reminder ladder against the ACTUAL trial length.
    /// This used to be hardcoded to a 7-day trial (reminders on day 5/6) while
    /// the product ships a 3-day trial — the reminders fired after the trial had
    /// already converted or lapsed.
    func scheduleSmartTrialNotifications(trialDays: Int = Config.fallbackTrialDays) {
        let days = max(1, trialDays)

        // Clear any existing trial notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: getTrialNotificationIds())

        // Daily engagement notifications for every full day of the trial.
        scheduleEngagementNotifications(trialDays: days)

        // Nothing sensible to remind about on a 1-day trial.
        guard days >= 2 else { return }

        // Heads-up reminder: 2 days before the trial ends when the trial is long
        // enough, otherwise 1 day before.
        let reminderOffset = max(1, days - 2)
        scheduleTrialReminderNotification(dayOffset: reminderOffset, daysLeft: days - reminderOffset)

        // Final reminder the day before the trial ends (skip if it collides
        // with the heads-up reminder on a short trial).
        let finalOffset = days - 1
        if finalOffset > reminderOffset {
            scheduleFinalReminderNotification(dayOffset: finalOffset)
        }
    }

    private func scheduleEngagementNotifications(trialDays: Int) {
        let engagementMessages = [
            String(localized: "Welcome to Blissful! Ready to start planning your perfect day? 💕"),
            String(localized: "Your wedding countdown has begun! Check your timeline today ✨"),
            String(localized: "How's your budget looking? Track your spending with ease 💰"),
            String(localized: "Don't forget to add your guests! Manage RSVPs effortlessly 👥"),
            String(localized: "Tasks keeping you organized? Mark off what you've completed ✅"),
            String(localized: "Your wedding plans are coming together beautifully! 🌸")
        ]

        // One per full day of the trial, never more than we have copy for.
        let lastDay = min(max(trialDays, 1), engagementMessages.count)
        for day in 1...lastDay {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Your Wedding Planning Journey")
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

    private func scheduleTrialReminderNotification(dayOffset: Int, daysLeft: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your Free Trial Ends Soon")
        content.body = daysLeft <= 1
            ? String(localized: "Only 1 day left! Continue planning your dream wedding with full access to all features 💍")
            : String(localized: "Only 2 days left! Continue planning your dream wedding with full access to all features 💍")
        content.sound = .default
        content.categoryIdentifier = "TRIAL_REMINDER"
        content.userInfo = ["type": "trial_reminder"]

        // `daysLeft` days before the trial ends, at 10 AM
        let triggerDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
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

    private func scheduleFinalReminderNotification(dayOffset: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Last Day of Your Free Trial")
        content.body = String(localized: "Your trial ends tomorrow. Keep planning your perfect wedding day! 🎊")
        content.sound = .default
        content.categoryIdentifier = "FINAL_REMINDER"
        content.userInfo = ["type": "final_reminder"]

        // 1 day before the trial ends, at 6 PM
        let triggerDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
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
        for day in 1...Self.maxEngagementDays {
            ids.append("engagement_day_\(day)")
        }
        return ids
    }
}
