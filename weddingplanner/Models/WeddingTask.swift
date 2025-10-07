import Foundation
import SwiftData

@Model
final class WeddingTask {
    var title: String
    var taskDescription: String?
    var category: TaskCategory
    var dueDate: Date?
    var priority: TaskPriority
    var isCompleted: Bool
    var completedDate: Date?
    var assignedTo: String?
    var estimatedCost: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Wedding.tasks) var wedding: Wedding?
    @Relationship var vendor: Vendor?
    
    init(title: String, category: TaskCategory, priority: TaskPriority = .medium) {
        self.title = title
        self.category = category
        self.priority = priority
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: dueDate).day
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case planning = "Planning"
    case venue = "Venue"
    case vendors = "Vendors"
    case attire = "Attire"
    case invitations = "Invitations"
    case decorations = "Decorations"
    case catering = "Catering"
    case entertainment = "Entertainment"
    case photography = "Photography"
    case flowers = "Flowers"
    case transportation = "Transportation"
    case accommodation = "Accommodation"
    case legal = "Legal/Documents"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .planning: return "calendar"
        case .venue: return "building.2"
        case .vendors: return "person.2"
        case .attire: return "tshirt"
        case .invitations: return "envelope"
        case .decorations: return "sparkles"
        case .catering: return "fork.knife"
        case .entertainment: return "music.note"
        case .photography: return "camera"
        case .flowers: return "leaf"
        case .transportation: return "car"
        case .accommodation: return "bed.double"
        case .legal: return "doc.text"
        case .other: return "ellipsis"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "4CAF50"
        case .medium: return "2196F3"
        case .high: return "FF9800"
        case .urgent: return "F44336"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}