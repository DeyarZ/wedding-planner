import Foundation
import Combine
import SwiftUI
import SwiftData
import UserNotifications

@MainActor
class DataManager: ObservableObject {
    @Published var wedding: Wedding?
    @Published var isLoading = false
    @Published var hasWedding = false

    private var modelContext: ModelContext?

    /// Every gate below reads `SubscriptionManager.shared`, so a view that only
    /// observes the DataManager would keep its locks on screen after a purchase
    /// until something else happened to redraw it. Forwarding the subscription
    /// manager's change signal means the locks vanish the moment the
    /// entitlement flips — no relaunch, no stale padlocks for a paying user.
    private var subscriptionObserver: AnyCancellable?

    init() {
        subscriptionObserver = SubscriptionManager.shared.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.objectWillChange.send()
                }
            }
    }

    // MARK: - Free User Limits
    //
    // The single source of truth for the free tier. Nothing in the UI may
    // compare a count against a number inline — every limit is enforced by
    // exactly one method in the gate extension at the bottom of this file.
    enum FreeLimit {
        /// Guests a free user can create.
        static let guests = 10
        /// Vendors a free user can create.
        static let vendors = 3
        /// How many of the seeded checklist tasks a free user can tick off.
        /// The seeded plan stays fully *visible* — this only caps interaction.
        static let completableTasks = 5
        /// Vision-board photos a free user can upload.
        static let photos = 10
        /// Budget categories a free user can open. The rest stay listed but
        /// locked, so the value is visible instead of hidden.
        static let budgetCategories = 1
    }


    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadWedding()
    }
    
    func loadWedding() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Wedding>()
        do {
            let weddings = try modelContext.fetch(descriptor)
            if let firstWedding = weddings.first {
                self.wedding = firstWedding
                self.hasWedding = true
            } else {
                self.hasWedding = false
            }
        } catch {
            print("Error loading wedding: \(error)")
        }
    }
    
    func createWedding(coupleNames: String, date: Date, budget: Double, guestCount: Int) {
        createWeddingWithDetails(
            coupleNames: coupleNames,
            date: date,
            budget: budget,
            guestCount: guestCount,
            venue: nil,
            priorities: [],
            initialTasks: []
        )
    }

    func createWeddingWithDetails(coupleNames: String, date: Date, budget: Double, guestCount: Int, venue: String?, priorities: [String], initialTasks: [InitialTaskData]) {
        guard let modelContext = modelContext else { return }

        let newWedding = Wedding(coupleNames: coupleNames, date: date, totalBudget: budget, guestCount: guestCount)

        // Set venue if provided
        if let venue = venue, !venue.isEmpty {
            newWedding.venue = venue
        }

        modelContext.insert(newWedding)

        // Add budget categories with priority-based adjustments
        addBudgetCategories(to: newWedding, totalBudget: budget, priorities: priorities, modelContext: modelContext)

        // Add personalized initial tasks
        addInitialTasks(to: newWedding, tasks: initialTasks, modelContext: modelContext)

        do {
            try modelContext.save()
            self.wedding = newWedding
            self.hasWedding = true
            syncWinBackNotification()
        } catch {
            print("Error creating wedding: \(error)")
        }
    }

    /// Keeps the T-60 win-back aligned with the wedding date. Called from every
    /// save, so a date that moves anywhere in the app reschedules — the manager
    /// itself short-circuits when nothing changed, so this is cheap.
    private func syncWinBackNotification() {
        WinBackNotificationManager.shared.sync(
            weddingDate: wedding?.date,
            isSubscribed: SubscriptionManager.shared.isSubscribed
        )
    }

    private func addBudgetCategories(to wedding: Wedding, totalBudget: Double, priorities: [String], modelContext: ModelContext) {
        var adjustedPercentages = [BudgetCategory: Double]()

        // Start with default percentages
        for category in BudgetCategory.allCases {
            adjustedPercentages[category] = category.defaultPercentage
        }

        // Adjust percentages based on priorities
        let priorityBoost: Double = 5.0 // Add 5% to priority categories
        let totalPriorityBoost = Double(priorities.count) * priorityBoost

        if !priorities.isEmpty && totalPriorityBoost > 0 {
            // Boost priority categories
            for priority in priorities {
                switch priority {
                case "venue":
                    adjustedPercentages[.venue]! += priorityBoost
                case "photography":
                    adjustedPercentages[.photography]! += priorityBoost
                case "food":
                    adjustedPercentages[.venue]! += priorityBoost / 2 // Venue includes catering
                case "music":
                    adjustedPercentages[.entertainment]! += priorityBoost
                case "flowers":
                    adjustedPercentages[.flowers]! += priorityBoost
                case "attire":
                    adjustedPercentages[.attire]! += priorityBoost
                default:
                    break
                }
            }

            // Reduce other categories proportionally
            let nonPriorityCategories = BudgetCategory.allCases.filter { category in
                !priorities.contains { priority in
                    (priority == "venue" && category == .venue) ||
                    (priority == "photography" && category == .photography) ||
                    (priority == "food" && category == .venue) ||
                    (priority == "music" && category == .entertainment) ||
                    (priority == "flowers" && category == .flowers) ||
                    (priority == "attire" && category == .attire)
                }
            }

            let reductionPerCategory = totalPriorityBoost / Double(nonPriorityCategories.count)
            for category in nonPriorityCategories {
                adjustedPercentages[category]! = max(0, adjustedPercentages[category]! - reductionPerCategory)
            }
        }

        // Create budget items
        for category in BudgetCategory.allCases {
            let percentage = adjustedPercentages[category] ?? category.defaultPercentage
            let budgetAmount = totalBudget * (percentage / 100)
            if budgetAmount > 0 {
                let budgetItem = BudgetItem(name: category.rawValue, category: category, estimatedAmount: budgetAmount)
                budgetItem.wedding = wedding
                modelContext.insert(budgetItem)
            }
        }
    }

    /// Upper bound on how many of the seeded tasks get a local reminder.
    private static let maxSeededTaskReminders = 10

    private func addInitialTasks(to wedding: Wedding, tasks: [InitialTaskData], modelContext: ModelContext) {
        let calendar = Calendar.current

        for (index, taskData) in tasks.enumerated() {
            let task = WeddingTask(
                title: taskData.title,
                category: mapTaskCategory(taskData.category),
                priority: mapTaskPriority(taskData.priority)
            )

            // Set due dates based on priority and type
            let daysFromNow = getDaysFromNow(for: taskData, index: index)
            if let dueDate = calendar.date(byAdding: .day, value: daysFromNow, to: Date()) {
                task.dueDate = dueDate

                // iOS only keeps 64 pending local notifications. The seeded
                // checklist is now the full wedding plan, so only the nearest
                // tasks get a reminder — the rest are scheduled as they come up.
                if index < Self.maxSeededTaskReminders {
                    NotificationManager.shared.scheduleTaskReminder(for: task)
                }
            }

            task.wedding = wedding
            modelContext.insert(task)
        }
    }

    private func mapTaskCategory(_ category: String) -> TaskCategory {
        switch category {
        case "venue": return .venue
        case "photography": return .photography
        case "catering": return .catering
        case "budget": return .planning
        case "invitations": return .invitations
        case "guests": return .planning
        case "planning": return .planning
        case "vendors": return .vendors
        case "attire": return .attire
        case "decorations": return .decorations
        case "entertainment", "music": return .entertainment
        case "flowers": return .flowers
        case "transportation": return .transportation
        case "accommodation": return .accommodation
        case "legal": return .legal
        default: return .other
        }
    }

    private func mapTaskPriority(_ priority: Int) -> TaskPriority {
        switch priority {
        case 1: return .urgent
        case 2: return .high
        case 3: return .medium
        default: return .low
        }
    }

    private func getDaysFromNow(for task: InitialTaskData, index: Int) -> Int {
        // The onboarding checklist plans backwards from the wedding date and
        // supplies its own lead time; the category defaults below only apply to
        // callers that do not.
        if let explicit = task.daysFromNow { return max(1, explicit) }

        switch task.category {
        case "budget": return 1 // Review budget tomorrow
        case "venue": return 7 // Start venue research next week
        case "photography": return 14 // Find photographer in 2 weeks
        case "catering": return 21 // Catering decisions in 3 weeks
        case "invitations": return 30 // Save the dates in a month
        case "guests": return 3 // Guest list in 3 days
        default: return 7 + index // Spread other tasks over time
        }
    }
    
    
    func updateWedding() {
        guard let modelContext = modelContext else { return }

        do {
            try modelContext.save()
            syncWinBackNotification()
        } catch {
            print("Error updating wedding: \(error)")
        }
    }
    
    // Computed properties for the UI
    var daysUntilWedding: Int {
        wedding?.daysUntilWedding ?? 0
    }
    
    var totalBudget: Double {
        wedding?.totalBudget ?? 0
    }
    
    var spentBudget: Double {
        wedding?.totalSpent ?? 0
    }
    
    var taskProgress: Double {
        wedding?.taskProgress ?? 0
    }
    
    var budgetRemaining: Double {
        wedding?.budgetRemaining ?? 0
    }
    
    var weddingDate: Date {
        wedding?.date ?? Date()
    }
    
    var upcomingTasksCount: Int {
        guard let tasks = wedding?.tasks else { return 0 }
        let upcomingTasks = tasks.filter { task in
            !task.isCompleted && (task.dueDate ?? Date.distantFuture) <= Date().addingTimeInterval(7 * 24 * 60 * 60)
        }
        return upcomingTasks.count
    }
    
    var currentStressLevel: StressLevel {
        guard let wedding = wedding else { return .low }
        
        let daysLeft = wedding.daysUntilWedding
        let budgetUsed = wedding.totalBudget > 0 ? wedding.totalSpent / wedding.totalBudget : 0
        let tasksOverdue = wedding.tasks?.filter { $0.isOverdue }.count ?? 0
        
        if daysLeft < 7 || budgetUsed > 0.95 || tasksOverdue > 5 {
            return .panic
        } else if daysLeft < 30 || budgetUsed > 0.85 || tasksOverdue > 2 {
            return .high
        } else if daysLeft < 90 || budgetUsed > 0.7 || tasksOverdue > 0 {
            return .medium
        } else {
            return .low
        }
    }
}

struct InitialTaskData {
    let id: String
    let title: String
    let description: String
    let category: String
    let priority: Int
    let estimatedTime: String
    /// Explicit lead time in days. The onboarding checklist is planned
    /// backwards from the wedding date, so it needs to set the due date itself
    /// instead of falling back to the per-category defaults.
    var daysFromNow: Int? = nil
}

enum StressLevel {
    case low, medium, high, panic
    
    var color: Color {
        switch self {
        case .low: return Color(hex: "4CAF50")
        case .medium: return Color(hex: "2196F3")
        case .high: return Color(hex: "FF9800")
        case .panic: return Color(hex: "F44336")
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Smooth Sailing"
        case .medium: return "On Track"
        case .high: return "Needs Attention"
        case .panic: return "Critical"
        }
    }
}

// MARK: - Premium Purchase Extension
extension DataManager {
    func purchasePremium() {
        // Cancel trial reminder notifications when user purchases premium
        TrialNotificationManager.shared.cancelTrialReminders()
    }

    var hasPremiumAccess: Bool {
        return SubscriptionManager.shared.isSubscribed
    }

    // MARK: - Guests

    var guestCount: Int { wedding?.guests?.count ?? 0 }

    func canAddGuest() -> Bool {
        if hasPremiumAccess { return true }
        return guestCount < FreeLimit.guests
    }

    // MARK: - Vendors

    var vendorCount: Int { wedding?.vendors?.count ?? 0 }

    func canAddVendor() -> Bool {
        if hasPremiumAccess { return true }
        return vendorCount < FreeLimit.vendors
    }

    // MARK: - Tasks
    //
    // Free users SEE the entire seeded plan — hiding it would gut the product's
    // first impression. What is capped is interaction: the first
    // `FreeLimit.completableTasks` tasks of the plan can be ticked off, custom
    // tasks are premium-only.

    /// The checklist in its canonical order: soonest deadline first, then
    /// creation order. Deliberately independent of whatever filter or sort the
    /// UI happens to show, so "the first five" never moves under the user.
    private var orderedTasks: [WeddingTask] {
        (wedding?.tasks ?? []).sorted { lhs, rhs in
            let l = lhs.dueDate ?? Date.distantFuture
            let r = rhs.dueDate ?? Date.distantFuture
            if l != r { return l < r }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
            return lhs.title < rhs.title
        }
    }

    /// Identifiers of the tasks a free user may tick off.
    private var freeCompletableTaskIDs: Set<PersistentIdentifier> {
        Set(orderedTasks.prefix(FreeLimit.completableTasks).map { $0.persistentModelID })
    }

    /// Adding a custom task is premium — the seeded plan is the free product.
    func canAddTask() -> Bool {
        return hasPremiumAccess
    }

    /// Whether this specific task's checkbox is live for this user.
    ///
    /// Already-completed tasks always stay toggleable: an existing free user who
    /// ticked off 20 tasks before this gate shipped keeps every one of them and
    /// can still correct a mistake. The gate only blocks *new* completions.
    func canCompleteTask(_ task: WeddingTask) -> Bool {
        if hasPremiumAccess { return true }
        if task.isCompleted { return true }
        return freeCompletableTaskIDs.contains(task.persistentModelID)
    }

    // MARK: - Photos

    func canUploadPhoto(currentCount: Int) -> Bool {
        if hasPremiumAccess { return true }
        return currentCount < FreeLimit.photos
    }

    // MARK: - Budget
    //
    // Free users keep one category — the biggest one, which for practically
    // every wedding is venue & catering. It is derived from the data rather than
    // hardcoded so the free slot is the one that actually matters, and it is
    // stable as long as the budget split is.

    /// The one budget category a free user can open.
    var freeBudgetCategory: BudgetCategory {
        let items = wedding?.budgetItems ?? []
        let totals = Dictionary(grouping: items, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.estimatedAmount } }

        let best = BudgetCategory.allCases
            .filter { totals[$0] != nil }
            .max { (totals[$0] ?? 0) < (totals[$1] ?? 0) }

        return best ?? .venue
    }

    /// Categories this user may open, in `BudgetCategory` order.
    var unlockedBudgetCategories: [BudgetCategory] {
        if hasPremiumAccess { return BudgetCategory.allCases }
        return [freeBudgetCategory]
    }

    func canAccessBudgetCategory(_ category: BudgetCategory) -> Bool {
        if hasPremiumAccess { return true }
        return category == freeBudgetCategory
    }

    func canAccessAllBudgetCategories() -> Bool {
        return hasPremiumAccess
    }

    /// Budget insights / charts.
    func canViewBudgetAnalytics() -> Bool {
        return hasPremiumAccess
    }

    /// Guest RSVP / meal breakdowns.
    func canViewGuestAnalytics() -> Bool {
        return hasPremiumAccess
    }

    // MARK: - Export

    /// Covers every export surface — PDF, share sheet, guest and vendor lists.
    func canExportData() -> Bool {
        return hasPremiumAccess
    }

    // MARK: - Remaining slots (for the "3 of 10" affordances)

    func getRemainingGuestSlots() -> Int {
        if hasPremiumAccess { return -1 } // Unlimited
        return max(0, FreeLimit.guests - guestCount)
    }

    func getRemainingVendorSlots() -> Int {
        if hasPremiumAccess { return -1 } // Unlimited
        return max(0, FreeLimit.vendors - vendorCount)
    }

    func getRemainingTaskSlots() -> Int {
        if hasPremiumAccess { return -1 } // Unlimited
        let completed = orderedTasks.prefix(FreeLimit.completableTasks).filter { $0.isCompleted }.count
        return max(0, FreeLimit.completableTasks - completed)
    }

    // MARK: - Paywall Triggers

    /// Legacy entry point kept for the older view families that still call it
    /// with a string. It routes through the same `PremiumGate` enum so the
    /// analytics slug is identical no matter which surface fired.
    func showPaywallIfNeeded(for feature: String) {
        guard let gate = PremiumGate.fromLegacyFeature(feature) else { return }

        let blocked: Bool
        switch gate {
        case .guestsLimit: blocked = !canAddGuest()
        case .vendorsLimit: blocked = !canAddVendor()
        case .customTask, .taskCompleteLimit: blocked = !canAddTask()
        case .photosLimit: blocked = !hasPremiumAccess
        case .budgetCategories, .budgetAnalytics, .guestAnalytics: blocked = !hasPremiumAccess
        case .pdfExport, .dataExport: blocked = !canExportData()
        }

        if blocked { Self.requestUpgrade(for: gate) }
    }

    /// Fallback presentation path: posts to `ContentView`, which opens the
    /// paywall with `source: .featureGate` and this gate attached. Views that
    /// can present their own upsell sheet should do that instead.
    static func requestUpgrade(for gate: PremiumGate) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowPaywall"),
            object: nil,
            userInfo: ["gate": gate.rawValue]
        )
    }
}

// Import TrialNotificationManager if it's in a separate file
// This class should be accessible from DataManager