import Foundation
import SwiftUI

// MARK: - Steps

/// Every screen of the first-run flow, in order. The raw value is the stable
/// analytics slug sent with `onboarding_step` — never renumber or rename a case
/// without accepting that the funnel breaks at that point.
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case socialProof
    case partnerNames
    case namesPayoff
    case weddingDate
    case datePayoff
    case planningStage
    case stagePayoff
    case guestCount
    case guestPayoff
    case budgetRange
    case budgetPayoff
    case venue
    case stressors
    case stressorPayoff
    case priorities
    case planningParty
    case buildingPlan
    case planReveal
    case previewChecklist
    case previewBudget
    case previewGuests
    case commit
    case notifications
    case trialTimeline
    case valueRecap

    var slug: String {
        switch self {
        case .welcome:          return "welcome"
        case .socialProof:      return "social_proof"
        case .partnerNames:     return "partner_names"
        case .namesPayoff:      return "names_payoff"
        case .weddingDate:      return "wedding_date"
        case .datePayoff:       return "date_payoff"
        case .planningStage:    return "planning_stage"
        case .stagePayoff:      return "stage_payoff"
        case .guestCount:       return "guest_count"
        case .guestPayoff:      return "guest_payoff"
        case .budgetRange:      return "budget_range"
        case .budgetPayoff:     return "budget_payoff"
        case .venue:            return "venue"
        case .stressors:        return "stressors"
        case .stressorPayoff:   return "stressor_payoff"
        case .priorities:       return "priorities"
        case .planningParty:    return "planning_party"
        case .buildingPlan:     return "building_plan"
        case .planReveal:       return "plan_reveal"
        case .previewChecklist: return "preview_checklist"
        case .previewBudget:    return "preview_budget"
        case .previewGuests:    return "preview_guests"
        case .commit:           return "commit"
        case .notifications:    return "notifications"
        case .trialTimeline:    return "trial_timeline"
        case .valueRecap:       return "value_recap"
        }
    }

    /// The warm-open screens carry no progress bar — a progress indicator on
    /// screen one reads as "this is a long form" before any value was shown.
    var showsProgress: Bool {
        switch self {
        case .welcome, .socialProof: return false
        default: return true
        }
    }

    /// 0…1 position in the flow, used by the thin progress bar. Deliberately
    /// never rendered as "3 of 26".
    var progress: Double {
        let total = Double(OnboardingStep.allCases.count - 1)
        guard total > 0 else { return 1 }
        return Double(rawValue) / total
    }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
}

// MARK: - Answer types

enum PlanningStage: String, CaseIterable, Identifiable {
    case justEngaged
    case earlyPlanning
    case venueBooked
    case finalStretch

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .justEngaged:   return "Just engaged"
        case .earlyPlanning: return "Started planning"
        case .venueBooked:   return "Venue is booked"
        case .finalStretch:  return "In the final stretch"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .justEngaged:   return "The ring is on, nothing booked yet"
        case .earlyPlanning: return "A few ideas, a few appointments"
        case .venueBooked:   return "Date and place are locked in"
        case .finalStretch:  return "Weeks away, details everywhere"
        }
    }

    var icon: String {
        switch self {
        case .justEngaged:   return "sparkles"
        case .earlyPlanning: return "list.bullet.clipboard"
        case .venueBooked:   return "building.2.fill"
        case .finalStretch:  return "flag.checkered"
        }
    }

}

enum GuestBand: String, CaseIterable, Identifiable {
    case intimate, small, medium, large, grand

    var id: String { rawValue }

    var count: Int {
        switch self {
        case .intimate: return 20
        case .small:    return 50
        case .medium:   return 100
        case .large:    return 200
        case .grand:    return 350
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .intimate: return "Intimate"
        case .small:    return "Small"
        case .medium:   return "Medium"
        case .large:    return "Large"
        case .grand:    return "Grand"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .intimate: return "25 guests or fewer"
        case .small:    return "26–75 guests"
        case .medium:   return "76–150 guests"
        case .large:    return "151–300 guests"
        case .grand:    return "More than 300 guests"
        }
    }
}

enum Stressor: String, CaseIterable, Identifiable {
    case budget, guestList, vendors, timeline, family, time

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .budget:    return "Keeping the budget"
        case .guestList: return "The guest list"
        case .vendors:   return "Finding good vendors"
        case .timeline:  return "Not missing a deadline"
        case .family:    return "Family expectations"
        case .time:      return "Having no time"
        }
    }

    var icon: String {
        switch self {
        case .budget:    return "creditcard.fill"
        case .guestList: return "person.3.fill"
        case .vendors:   return "storefront.fill"
        case .timeline:  return "clock.fill"
        case .family:    return "house.fill"
        case .time:      return "hourglass"
        }
    }

    /// The reassurance shown on the payoff screen after the multi-select.
    /// Returns a resolved String because the payoff screen mixes it with copy
    /// that interpolates the user's own answers.
    var reassurance: String {
        switch self {
        case .budget:    return String(localized: "Every last cost lands in one of 12 categories, so you always know what is left before you commit to anything.")
        case .guestList: return String(localized: "Guests, plus-ones and RSVPs live in one list that stays in sync — no more three versions of the same spreadsheet.")
        case .vendors:   return String(localized: "Every vendor keeps its own quotes, contracts, payments and notes, so nothing gets lost in your inbox.")
        case .timeline:  return String(localized: "Your checklist is dated backwards from your wedding day and reminds you before something is late — not after.")
        case .family:    return String(localized: "Seating, plus-ones and dietary notes stay documented, so the awkward conversations happen once.")
        case .time:      return String(localized: "The plan is already built. You only ever see the handful of things that matter this week.")
        }
    }
}

enum PlanningParty: String, CaseIterable, Identifiable {
    case solo, together, withFamily, withPlanner

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .solo:        return "Mostly me"
        case .together:    return "The two of us"
        case .withFamily:  return "Us and our families"
        case .withPlanner: return "We have a planner"
        }
    }

    var icon: String {
        switch self {
        case .solo:        return "person.fill"
        case .together:    return "heart.fill"
        case .withFamily:  return "person.3.fill"
        case .withPlanner: return "briefcase.fill"
        }
    }
}

// MARK: - Currency

/// Locale-aware money formatting for the onboarding flow.
///
/// The budget question used to be hardcoded in US dollars, which meant a German
/// user planned a "$50,000" wedding and then saw euros everywhere else in the
/// app. Everything here derives from `Locale.current`.
enum OnboardingCurrency {

    static var code: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    static var symbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? "$"
    }

    /// Currencies without minor units (JPY, KRW, …) carry roughly two more
    /// digits than the euro/dollar band, so the same numeric ladder would offer
    /// a ¥10,000 wedding. Scaling keeps the bands in a plausible range without
    /// shipping a full FX table.
    static var bandScale: Double {
        zeroDecimalCurrencies.contains(code) ? 100 : 1
    }

    private static let zeroDecimalCurrencies: Set<String> = [
        "JPY", "KRW", "VND", "CLP", "ISK", "HUF", "TWD", "COP", "IDR"
    ]

    static func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

/// One selectable budget band. Values are in the user's own currency.
struct BudgetBand: Identifiable {
    let id: String
    let lower: Double
    let upper: Double?

    var value: Double { upper.map { ($0 + lower) / 2 } ?? lower * 1.2 }

    var label: String {
        if let upper {
            return "\(OnboardingCurrency.format(lower)) – \(OnboardingCurrency.format(upper))"
        }
        return "\(OnboardingCurrency.format(lower))+"
    }

    static var all: [BudgetBand] {
        let s = OnboardingCurrency.bandScale
        return [
            BudgetBand(id: "b1", lower: 5_000 * s, upper: 10_000 * s),
            BudgetBand(id: "b2", lower: 10_000 * s, upper: 20_000 * s),
            BudgetBand(id: "b3", lower: 20_000 * s, upper: 35_000 * s),
            BudgetBand(id: "b4", lower: 35_000 * s, upper: 50_000 * s),
            BudgetBand(id: "b5", lower: 50_000 * s, upper: 75_000 * s),
            BudgetBand(id: "b6", lower: 75_000 * s, upper: nil)
        ]
    }
}

// MARK: - Collected data

/// Everything the flow collects, in one observable place.
///
/// The old flow stashed each answer in `UserDefaults` and read it back three
/// screens later. Keeping it in memory means the payoff screens can quote the
/// user's own answers, and the wedding is still created through the exact same
/// `DataManager.createWeddingWithDetails` entry point at the end.
@MainActor
final class OnboardingData: ObservableObject {
    @Published var firstName: String = ""
    @Published var partnerName: String = ""
    @Published var weddingDate: Date = Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date()
    @Published var hasDate: Bool = true
    @Published var stage: PlanningStage?
    @Published var guestBand: GuestBand?
    @Published var budget: Double = 0
    @Published var venue: String = ""
    @Published var stressors: Set<Stressor> = []
    @Published var priorities: Set<String> = []
    @Published var party: PlanningParty?
    @Published var didCommit: Bool = false

    /// Guards against creating a second wedding if the reveal screen re-appears
    /// (TabView keeps neighbouring pages alive and re-runs `onAppear`).
    private(set) var didCreateWedding = false

    // MARK: Derived

    var coupleNames: String {
        let a = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if a.isEmpty && b.isEmpty { return String(localized: "Our Wedding") }
        if b.isEmpty { return a }
        if a.isEmpty { return b }
        return "\(a) & \(b)"
    }

    /// The date the plan is built against. Without a date we plan against a
    /// 12-month horizon so the checklist still has sensible due dates.
    var effectiveDate: Date {
        hasDate ? weddingDate : (Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date())
    }

    var daysUntilWedding: Int {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: effectiveDate)
        return max(0, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    var monthsUntilWedding: Int {
        max(0, Calendar.current.dateComponents([.month], from: Date(), to: effectiveDate).month ?? 0)
    }

    var guestCount: Int { guestBand?.count ?? 100 }

    var formattedBudget: String { OnboardingCurrency.format(budget) }

    var formattedDate: String {
        guard hasDate else { return String(localized: "your wedding day") }
        return weddingDate.formatted(.dateTime.day().month(.wide).year())
    }

    /// The stressor we address by name on the payoff screen — the first one the
    /// user picked, in the canonical order of the list.
    var primaryStressor: Stressor? {
        Stressor.allCases.first { stressors.contains($0) }
    }

    var tasks: [InitialTaskData] {
        OnboardingChecklist.tasks(
            daysUntilWedding: daysUntilWedding,
            stage: stage ?? .earlyPlanning,
            priorities: priorities,
            stressors: stressors
        )
    }

    var taskCount: Int { tasks.count }

    /// Everything the flow collected, handed to SwiftData in one call.
    ///
    /// Kept as the single write point so the seeded wedding, its 12 budget
    /// categories and the full checklist always come from the same source.
    func createWeddingWithData(using dataManager: DataManager) {
        guard !didCreateWedding else { return }
        didCreateWedding = true

        dataManager.createWeddingWithDetails(
            coupleNames: coupleNames,
            date: effectiveDate,
            budget: budget,
            guestCount: guestCount,
            venue: venue.trimmingCharacters(in: .whitespacesAndNewlines),
            priorities: Array(priorities),
            initialTasks: tasks
        )

        // Kept for anything downstream that still reads the legacy keys.
        UserDefaults.standard.set(firstName, forKey: "onboarding_firstName")
        UserDefaults.standard.set(partnerName, forKey: "onboarding_secondName")
        UserDefaults.standard.set(coupleNames, forKey: "onboarding_coupleNames")
    }
}
