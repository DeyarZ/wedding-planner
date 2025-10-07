import Foundation
import SwiftData

@Model
final class DayScheduleEvent {
    var id: UUID
    var title: String
    var startTime: Date
    var duration: Int // in minutes
    var location: String?
    var notes: String?
    var category: EventCategory
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \Wedding.scheduleEvents) var wedding: Wedding?

    init(title: String, startTime: Date, duration: Int, category: EventCategory = .other, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.category = category
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

enum EventCategory: String, Codable, CaseIterable {
    case preparation = "Getting Ready"
    case photography = "Photography"
    case ceremony = "Ceremony"
    case reception = "Reception"
    case entertainment = "Entertainment"
    case food = "Food & Drinks"
    case transportation = "Transportation"
    case other = "Other"

    var icon: String {
        switch self {
        case .preparation: return "sparkles"
        case .photography: return "camera"
        case .ceremony: return "heart"
        case .reception: return "music.note"
        case .entertainment: return "party.popper"
        case .food: return "fork.knife"
        case .transportation: return "car"
        case .other: return "star"
        }
    }

    var color: String {
        switch self {
        case .preparation: return "E8C4B8"
        case .photography: return "C8D4E8"
        case .ceremony: return "FFB5BA"
        case .reception: return "D4B5E8"
        case .entertainment: return "B5E8D4"
        case .food: return "E8E4B5"
        case .transportation: return "B5C8E8"
        case .other: return "E8B5C4"
        }
    }
}

extension DayScheduleEvent {
    static func defaultSchedule() -> [DayScheduleEvent] {
        let calendar = Calendar.current
        let weddingDate = Date() // This should be the actual wedding date

        var events: [DayScheduleEvent] = []
        var sortOrder = 0

        // Helper to create time on wedding day
        func timeOn(hour: Int, minute: Int) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: weddingDate)
            components.hour = hour
            components.minute = minute
            return calendar.date(from: components) ?? Date()
        }

        events.append(DayScheduleEvent(
            title: "Hair & Makeup",
            startTime: timeOn(hour: 8, minute: 0),
            duration: 120,
            category: .preparation,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Getting Ready Photos",
            startTime: timeOn(hour: 10, minute: 0),
            duration: 60,
            category: .photography,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "First Look",
            startTime: timeOn(hour: 11, minute: 30),
            duration: 30,
            category: .photography,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Travel to Venue",
            startTime: timeOn(hour: 12, minute: 30),
            duration: 30,
            category: .transportation,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Guest Arrival",
            startTime: timeOn(hour: 13, minute: 0),
            duration: 30,
            category: .ceremony,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Ceremony",
            startTime: timeOn(hour: 13, minute: 30),
            duration: 30,
            category: .ceremony,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Cocktail Hour",
            startTime: timeOn(hour: 14, minute: 0),
            duration: 90,
            category: .food,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Reception Entrance",
            startTime: timeOn(hour: 15, minute: 30),
            duration: 15,
            category: .reception,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Dinner Service",
            startTime: timeOn(hour: 16, minute: 0),
            duration: 90,
            category: .food,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Speeches & Toasts",
            startTime: timeOn(hour: 17, minute: 30),
            duration: 30,
            category: .reception,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "First Dance",
            startTime: timeOn(hour: 18, minute: 0),
            duration: 10,
            category: .entertainment,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Party & Dancing",
            startTime: timeOn(hour: 18, minute: 15),
            duration: 180,
            category: .entertainment,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Cake Cutting",
            startTime: timeOn(hour: 21, minute: 0),
            duration: 15,
            category: .reception,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        events.append(DayScheduleEvent(
            title: "Grand Exit",
            startTime: timeOn(hour: 22, minute: 0),
            duration: 15,
            category: .ceremony,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        return events
    }
}