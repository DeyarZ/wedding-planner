import Foundation
import StoreKit
import SwiftData
import UIKit

/// Cross-promotion for Everlens, the studio's disposable-camera app for wedding
/// guests: one QR code on the table, guests shoot via App Clip, the photos stay
/// hidden until the couple taps Reveal. Every Everlens placement in BridePlan
/// funnels through here so the gating, the attribution and the copy stay in
/// one place — and so the whole thing can be switched off with one flag.
///
/// Placements (all contextual, no promo icon in the header):
/// - a checklist task due six weeks before the wedding, with a banner in the
///   timeline card and the task detail sheet,
/// - a banner in the vendors tab when the photographer filter is active and
///   inside a photographer's detail view,
/// - a dashboard card once the wedding is 60 days out.
enum EverlensPromo {

    // MARK: - Availability

    /// Languages Everlens is localized in (App Store `languageCodesISO2A`).
    /// BridePlan ships 31, so every surface is gated on this — a Polish couple
    /// must never be sent to an English-only app.
    static let supportedLanguages: Set<String> = ["en", "de", "es", "fr", "it", "pt", "nl"]

    /// True when the language BridePlan is currently running in is one Everlens
    /// speaks too. Uses the bundle's resolved localization rather than the
    /// device locale so a per-app language override is respected.
    static var isAvailable: Bool {
        guard let localization = Bundle.main.preferredLocalizations.first else { return false }
        let language = localization.split(separator: "-").first.map(String.init) ?? localization
        return supportedLanguages.contains(language.lowercased())
    }

    // MARK: - Surfaces

    /// Where the promo was shown. The raw value doubles as the App Store
    /// campaign token (`ct=`), so App Analytics → Sources → Campaigns breaks
    /// Everlens installs down per placement without any Everlens-side work.
    enum Surface: String {
        case task = "brideplan-task"
        case timeline = "brideplan-timeline"
        case dashboard = "brideplan-dashboard"
        case vendors = "brideplan-vendors"
        case vendorDetail = "brideplan-vendor-detail"
    }

    /// Campaign link for the surface. `pt` is the account-wide provider token —
    /// without it Apple drops the `ct` and the install lands in "Unavailable".
    static func appStoreURL(for surface: Surface) -> URL {
        var components = URLComponents(string: "https://apps.apple.com/app/id\(Config.everlensAppStoreID)")!
        components.queryItems = [
            URLQueryItem(name: "pt", value: Config.appStoreProviderToken),
            URLQueryItem(name: "ct", value: surface.rawValue),
            URLQueryItem(name: "mt", value: "8")
        ]
        return components.url!
    }

    // MARK: - Seeded checklist task

    /// Catalog key of the checklist task. Task titles are stored as display
    /// strings (see `OnboardingChecklist`), so a seeded task is recognised by
    /// matching its title against this key in every Everlens language rather
    /// than by a schema field — the store has never been migrated and a
    /// cross-promo is not the feature to start with.
    static let taskTitleKey = "Collect your guests' photos"

    /// Due date offset: the couple sets Everlens up in the final stretch, when
    /// the seating plan and the table decoration are being decided anyway.
    static let taskLeadDays = 42

    private static let taskSeededKey = "everlens.taskSeeded"
    private static let dashboardDismissedKey = "everlens.dashboardDismissed"

    /// The task title in every supported language — every string a seeded
    /// task's stored title can be, regardless of the language it was seeded in.
    static let seededTitles: Set<String> = {
        var titles: Set<String> = [taskTitleKey]
        for language in supportedLanguages {
            guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
                  let bundle = Bundle(path: path) else { continue }
            titles.insert(bundle.localizedString(forKey: taskTitleKey, value: nil, table: nil))
        }
        return titles
    }()

    static func isSeededTask(_ task: WeddingTask) -> Bool {
        task.category == .photography && seededTitles.contains(task.title)
    }

    /// Whether the Everlens banner belongs on this task right now.
    static func showsPromo(for task: WeddingTask) -> Bool {
        isAvailable && !task.isCompleted && isSeededTask(task)
    }

    /// Adds the guest-photos task once per install, due six weeks before the
    /// wedding (today when the wedding is closer than that). Runs on every
    /// launch and is idempotent, so the couples who onboarded before this
    /// shipped get it as well — not only new sign-ups.
    static func seedTaskIfNeeded(for wedding: Wedding, in context: ModelContext) {
        guard isAvailable, wedding.date > Date() else { return }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: taskSeededKey) else { return }
        if wedding.tasks?.contains(where: isSeededTask) == true {
            defaults.set(true, forKey: taskSeededKey)
            return
        }

        let task = WeddingTask(
            title: NSLocalizedString(taskTitleKey, comment: "Seeded checklist task title"),
            category: .photography,
            priority: .medium
        )
        let ideal = Calendar.current.date(byAdding: .day, value: -taskLeadDays, to: wedding.date) ?? wedding.date
        task.dueDate = max(ideal, Date())
        task.wedding = wedding
        context.insert(task)

        do {
            try context.save()
            defaults.set(true, forKey: taskSeededKey)
            NotificationManager.shared.scheduleTaskReminder(for: task)
        } catch {
            print("Error seeding Everlens task: \(error)")
        }
    }

    // MARK: - Dashboard card

    /// The card appears in the last two months — the same window the win-back
    /// notification uses, when the wedding stops being abstract.
    static let dashboardLeadDays = 60

    static func shouldShowDashboardCard(for wedding: Wedding?) -> Bool {
        guard isAvailable, let wedding else { return false }
        guard !UserDefaults.standard.bool(forKey: dashboardDismissedKey) else { return false }

        let days = wedding.daysUntilWedding
        guard days > 0, days <= dashboardLeadDays else { return false }

        // The couple ticked the guest-photos task off — they have this covered.
        if wedding.tasks?.contains(where: { isSeededTask($0) && $0.isCompleted }) == true {
            return false
        }
        return true
    }

    static func dismissDashboardCard() {
        UserDefaults.standard.set(true, forKey: dashboardDismissedKey)
        Analytics.everlensPromoDismissed(surface: Surface.dashboard.rawValue)
    }

    // MARK: - App Store

    /// Opens Everlens in an in-app `SKOverlay` — the native "GET" banner, the
    /// couple never leaves BridePlan — and falls back to the campaign URL when
    /// the overlay cannot load (Simulator, no foreground scene).
    static func openStore(from surface: Surface) {
        Analytics.everlensStoreOpened(surface: surface.rawValue)
        StoreOverlayPresenter.shared.present(surface: surface)
    }

    final class StoreOverlayPresenter: NSObject, SKOverlayDelegate {
        static let shared = StoreOverlayPresenter()

        private var fallbackURL: URL?

        func present(surface: Surface) {
            let url = appStoreURL(for: surface)
            fallbackURL = url

            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            guard let scene else {
                UIApplication.shared.open(url)
                return
            }

            let configuration = SKOverlay.AppConfiguration(appIdentifier: Config.everlensAppStoreID, position: .bottom)
            configuration.campaignToken = surface.rawValue
            configuration.providerToken = Config.appStoreProviderToken

            let overlay = SKOverlay(configuration: configuration)
            overlay.delegate = self
            overlay.present(in: scene)
        }

        func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: Error) {
            guard let fallbackURL else { return }
            UIApplication.shared.open(fallbackURL)
        }
    }
}
