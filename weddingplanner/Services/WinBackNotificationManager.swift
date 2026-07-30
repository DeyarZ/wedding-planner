import Foundation
import UserNotifications

/// T-60 win-back for users who never subscribed (or whose trial lapsed).
///
/// This is the one recovery surface that needs no store-side offer at all: we
/// *know* the wedding date, so we can hit the highest-intent moment the category
/// has — the start of panic season, sixty days out — with a local notification
/// that deep-links straight into the paywall.
///
/// Scoping rules (Phase 0 pattern): this manager only ever adds and removes the
/// single identifier below. It never calls `removeAllPendingNotificationRequests`,
/// so it cannot wipe the trial reminders or the daily schedule — and because no
/// other manager knows this identifier, nothing can wipe it either.
@MainActor
final class WinBackNotificationManager {
    static let shared = WinBackNotificationManager()
    private init() {}

    /// The only identifier this manager owns. `nonisolated` so it can be read
    /// from the notification-centre completion handlers.
    nonisolated static let identifier = "winback.t60"

    /// Days before the wedding the win-back fires.
    static let leadDays = 60

    /// Local hour of day. 10:00 — planning happens in the morning, and it keeps
    /// the notification away from the 19:00/20:00 engagement slots.
    private static let fireHour = 10

    /// Last fire date this process verified as scheduled. Purely an in-memory
    /// short-circuit so `sync` can be called from hot paths (every model save)
    /// without a notification-centre round trip each time. It resets on launch,
    /// so a schedule that silently failed (e.g. permission was still denied)
    /// gets retried on the next cold start.
    private var verifiedFireDate: Date?

    /// Reconciles the pending win-back with the current facts. Safe and cheap to
    /// call from anywhere, as often as you like.
    ///
    /// - Premium user, or no wedding date → nothing pending.
    /// - Wedding already inside the final 60 days → nothing pending. We do NOT
    ///   fire "60 days to go" immediately at someone who has 40; that is spam,
    ///   and the claim would be false.
    /// - Wedding date moved → the old request is replaced, not duplicated.
    func sync(weddingDate: Date?, isSubscribed: Bool, now: Date = Date()) {
        guard !isSubscribed, let weddingDate else {
            cancel()
            return
        }
        guard let fireDate = Self.fireDate(for: weddingDate, now: now) else {
            cancel()
            return
        }
        guard verifiedFireDate != fireDate else { return }

        // Ground truth, not a mirror: ask the notification centre what is
        // actually pending rather than trusting a local flag.
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let pending = requests
                .first { $0.identifier == Self.identifier }
                .flatMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }

            Task { @MainActor in
                if let pending, abs(pending.timeIntervalSince(fireDate)) < 60 {
                    self.verifiedFireDate = fireDate
                    return
                }
                self.schedule(at: fireDate)
            }
        }
    }

    /// The moment the win-back should fire, or `nil` when it should not exist:
    /// the wedding is less than `leadDays` away (or the date is in the past).
    static func fireDate(for weddingDate: Date, now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        guard let shifted = calendar.date(byAdding: .day, value: -leadDays, to: weddingDate) else { return nil }

        var components = calendar.dateComponents([.year, .month, .day], from: shifted)
        components.hour = fireHour
        components.minute = 0
        guard let fireDate = calendar.date(from: components) else { return nil }

        guard fireDate > now else { return nil }
        return fireDate
    }

    private func schedule(at fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "60 days to go")
        content.body = String(localized: "Final stretch. Get everything ready with Premium.")
        content.sound = .default
        content.categoryIdentifier = "WINBACK"
        // Read by `NotificationManager` to open the paywall with source `winback`.
        content.userInfo = ["type": "winback"]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.identifier,
            content: content,
            trigger: trigger
        )

        // Replaces any existing request with the same identifier, so a moved
        // wedding date reschedules instead of stacking.
        UNUserNotificationCenter.current().add(request) { error in
            guard error == nil else { return }
            Task { @MainActor in self.verifiedFireDate = fireDate }
        }
    }

    /// Removes the pending win-back. Called when the user goes premium.
    func cancel() {
        verifiedFireDate = nil
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
