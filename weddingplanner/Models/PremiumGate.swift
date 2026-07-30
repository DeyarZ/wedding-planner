import Foundation
import SwiftUI

/// Every premium gate in the app, in one place.
///
/// A gate is the *reason* a free user was stopped, not the screen they were on.
/// The raw value is the analytics slug — it is sent as the `gate` property on
/// `paywall_viewed` / `paywall_dismissed`, so the funnel can be split by which
/// limit actually drives revenue. Never invent a slug at a call site.
enum PremiumGate: String, Identifiable, CaseIterable {
    case guestsLimit = "guests_limit"
    case vendorsLimit = "vendors_limit"
    case customTask = "custom_task"
    case taskCompleteLimit = "task_complete_limit"
    case budgetCategories = "budget_categories"
    case budgetAnalytics = "budget_analytics"
    case guestAnalytics = "guest_analytics"
    case pdfExport = "pdf_export"
    case dataExport = "data_export"
    case photosLimit = "photos_limit"

    var id: String { rawValue }

    /// SF Symbol shown on the upsell sheet.
    var icon: String {
        switch self {
        case .guestsLimit: return "person.2"
        case .vendorsLimit: return "briefcase"
        case .customTask: return "plus.circle"
        case .taskCompleteLimit: return "checklist"
        case .budgetCategories: return "chart.pie"
        case .budgetAnalytics: return "chart.bar"
        case .guestAnalytics: return "chart.pie"
        case .pdfExport: return "doc.text"
        case .dataExport: return "square.and.arrow.up"
        case .photosLimit: return "photo.on.rectangle"
        }
    }

    /// Short headline naming what the user just ran into.
    var title: LocalizedStringKey {
        switch self {
        case .guestsLimit: return "Your guest list is full"
        case .vendorsLimit: return "Room for three vendors"
        case .customTask: return "Add your own tasks"
        case .taskCompleteLimit: return "You've checked off your free tasks"
        case .budgetCategories: return "One category is on us"
        case .budgetAnalytics: return "See where your budget goes"
        case .guestAnalytics: return "Know your guest list inside out"
        case .pdfExport: return "Export your wedding day"
        case .dataExport: return "Take your lists with you"
        case .photosLimit: return "Your vision board is full"
        }
    }

    /// One warm sentence on what Premium changes. No pressure, no shouting.
    var message: LocalizedStringKey {
        switch self {
        case .guestsLimit:
            return "The free plan holds 10 guests. Premium keeps every single name — with RSVPs, meals and groups."
        case .vendorsLimit:
            return "The free plan tracks 3 vendors. Premium tracks your whole dream team, contracts and payments included."
        case .customTask:
            return "Premium lets you add anything your wedding needs to the checklist — and check off every task on it."
        case .taskCompleteLimit:
            return "The free plan lets you tick off your first 5 tasks. Premium unlocks the whole checklist, so nothing gets left behind."
        case .budgetCategories:
            return "Premium opens every budget category, so each part of your wedding has its own place to live."
        case .budgetAnalytics:
            return "Premium turns your spending into clear insights — before a surprise does it for you."
        case .guestAnalytics:
            return "Premium breaks down RSVPs, meals and groups at a glance."
        case .pdfExport:
            return "Premium turns your plan into a beautiful PDF you can hand to anyone who needs it."
        case .dataExport:
            return "Premium lets you export your guests and vendors whenever you need them."
        case .photosLimit:
            return "The free plan holds 10 photos. Premium keeps every idea you fall in love with."
        }
    }

    /// Legacy string keys used by `DataManager.showPaywallIfNeeded(for:)`.
    static func fromLegacyFeature(_ feature: String) -> PremiumGate? {
        switch feature {
        case "guest": return .guestsLimit
        case "vendor": return .vendorsLimit
        case "task": return .customTask
        case "photo": return .photosLimit
        case "budget_categories": return .budgetCategories
        case "export": return .dataExport
        default: return nil
        }
    }
}
