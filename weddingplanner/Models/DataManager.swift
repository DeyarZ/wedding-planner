import Foundation
import SwiftUI
import SwiftData
import UserNotifications

@MainActor
class DataManager: ObservableObject {
    @Published var wedding: Wedding?
    @Published var isLoading = false
    @Published var hasWedding = false

    private var modelContext: ModelContext?

    // MARK: - Free User Limits
    private let FREE_GUEST_LIMIT = 10
    private let FREE_VENDOR_LIMIT = 3
    private let FREE_TASK_LIMIT = 5
    private let FREE_PHOTO_LIMIT = 10
    private let FREE_BUDGET_CATEGORY_LIMIT = 3
    
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
        } catch {
            print("Error creating wedding: \(error)")
        }
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

                // Schedule notification
                NotificationManager.shared.scheduleTaskReminder(for: task)
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

    func canAddGuest() -> Bool {
        if hasPremiumAccess { return true }
        return (wedding?.guests?.count ?? 0) < FREE_GUEST_LIMIT
    }

    func canAddVendor() -> Bool {
        if hasPremiumAccess { return true }
        return (wedding?.vendors?.count ?? 0) < FREE_VENDOR_LIMIT
    }

    func canAddTask() -> Bool {
        if hasPremiumAccess { return true }
        return (wedding?.tasks?.count ?? 0) < FREE_TASK_LIMIT
    }

    func canUploadPhoto() -> Bool {
        if hasPremiumAccess { return true }
        // Note: Photo count would need to be checked when Photo model is enabled
        return true // TODO: Check photo count when Photo model is available
    }

    func canAccessAllBudgetCategories() -> Bool {
        return hasPremiumAccess
    }

    func canExportData() -> Bool {
        return hasPremiumAccess
    }

    func getRemainingGuestSlots() -> Int {
        if hasPremiumAccess { return -1 } // Unlimited
        return max(0, FREE_GUEST_LIMIT - (wedding?.guests?.count ?? 0))
    }

    func getRemainingVendorSlots() -> Int {
        if hasPremiumAccess { return -1 } // Unlimited
        return max(0, FREE_VENDOR_LIMIT - (wedding?.vendors?.count ?? 0))
    }

    func getRemainingTaskSlots() -> Int {
        if hasPremiumAccess { return -1 } // Unlimited
        return max(0, FREE_TASK_LIMIT - (wedding?.tasks?.count ?? 0))
    }

    // MARK: - Paywall Triggers
    func showPaywallIfNeeded(for feature: String) {
        var shouldShowPaywall = false

        switch feature {
        case "guest":
            shouldShowPaywall = !canAddGuest()
        case "vendor":
            shouldShowPaywall = !canAddVendor()
        case "task":
            shouldShowPaywall = !canAddTask()
        case "photo":
            shouldShowPaywall = !canUploadPhoto()
        case "budget_categories":
            shouldShowPaywall = !canAccessAllBudgetCategories()
        case "export":
            shouldShowPaywall = !canExportData()
        default:
            break
        }

        if shouldShowPaywall {
            NotificationCenter.default.post(name: NSNotification.Name("ShowPaywall"), object: nil)
        }
    }
}

// Import TrialNotificationManager if it's in a separate file
// This class should be accessible from DataManager