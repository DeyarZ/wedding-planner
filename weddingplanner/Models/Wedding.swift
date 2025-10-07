import Foundation
import SwiftData

@Model
final class Wedding {
    var coupleNames: String
    var date: Date
    var venue: String?
    var totalBudget: Double
    var theme: String?
    var guestCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) var vendors: [Vendor]?
    @Relationship(deleteRule: .cascade) var guests: [Guest]?
    @Relationship(deleteRule: .cascade) var tasks: [WeddingTask]?
    @Relationship(deleteRule: .cascade) var budgetItems: [BudgetItem]?
    @Relationship(deleteRule: .cascade) var scheduleEvents: [DayScheduleEvent]?
    // @Relationship(deleteRule: .cascade) var photos: [Photo]?  // Temporarily disabled
    
    init(coupleNames: String, date: Date, totalBudget: Double, guestCount: Int) {
        self.coupleNames = coupleNames
        self.date = date
        self.totalBudget = totalBudget
        self.guestCount = guestCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var daysUntilWedding: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(0, days)
    }
    
    var totalSpent: Double {
        budgetItems?.reduce(0) { $0 + $1.amountSpent } ?? 0
    }
    
    var budgetRemaining: Double {
        totalBudget - totalSpent
    }
    
    var completedTasksCount: Int {
        tasks?.filter { $0.isCompleted }.count ?? 0
    }
    
    var totalTasksCount: Int {
        tasks?.count ?? 0
    }
    
    var taskProgress: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }
    
    var confirmedGuestsCount: Int {
        guests?.filter { $0.rsvpStatus == .confirmed }.count ?? 0
    }
}