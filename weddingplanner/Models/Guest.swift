import Foundation
import SwiftData

@Model
final class Guest {
    var id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var address: String?
    var rsvpStatus: RSVPStatus
    var group: GuestGroup
    var mealChoice: MealChoice?
    var partySize: Int
    var dietaryRestrictions: String?
    var allergies: String?
    var tableNumber: Int?
    var seatNumber: String?
    var notes: String?
    var invitationSent: Bool
    var invitationSentDate: Date?
    var invitationViewed: Bool
    var invitationViewedDate: Date?
    var rsvpDate: Date?
    var rsvpDeadline: Date?
    var reminderSent: Bool
    var reminderSentDate: Date?
    var needsTransportation: Bool
    var needsAccommodation: Bool
    var isVIP: Bool
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Wedding.guests) var wedding: Wedding?
    @Relationship var plusOnes: [PlusOne]?
    
    init(firstName: String, lastName: String, group: GuestGroup = .friends, partySize: Int = 1) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.group = group
        self.partySize = partySize
        self.rsvpStatus = .pending
        self.invitationSent = false
        self.invitationViewed = false
        self.reminderSent = false
        self.needsTransportation = false
        self.needsAccommodation = false
        self.isVIP = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var totalAttending: Int {
        guard rsvpStatus == .confirmed else { return 0 }
        let plusOneCount = plusOnes?.filter { $0.isAttending }.count ?? 0
        return 1 + plusOneCount
    }
}

enum RSVPStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case declined = "Declined"
    case maybe = "Maybe"
    
    var color: String {
        switch self {
        case .pending: return "9B9B9B"
        case .confirmed: return "4CAF50"
        case .declined: return "F44336"
        case .maybe: return "FF9800"
        }
    }
    
    var text: String {
        return self.rawValue
    }
}

@Model
final class PlusOne {
    var id: UUID
    var name: String
    var isChild: Bool
    var age: Int?
    var mealChoice: MealChoice?
    var dietaryRestrictions: String?
    var allergies: String?
    var isAttending: Bool

    @Relationship(inverse: \Guest.plusOnes) var guest: Guest?

    init(name: String, isChild: Bool = false, isAttending: Bool = true) {
        self.id = UUID()
        self.name = name
        self.isChild = isChild
        self.isAttending = isAttending
    }
}

enum GuestGroup: String, Codable, CaseIterable {
    case brideFamily = "Bride's Family"
    case groomFamily = "Groom's Family"
    case brideFriends = "Bride's Friends"
    case groomFriends = "Groom's Friends"
    case mutualFriends = "Mutual Friends"
    case friends = "Friends"
    case work = "Work Colleagues"
    case extended = "Extended Family"
    case other = "Other"

    var icon: String {
        switch self {
        case .brideFamily, .groomFamily, .extended: return "person.2.fill"
        case .brideFriends, .groomFriends, .mutualFriends, .friends: return "heart.fill"
        case .work: return "briefcase.fill"
        case .other: return "person.fill"
        }
    }

    var color: String {
        switch self {
        case .brideFamily: return "FFB3D9"
        case .groomFamily: return "B3D9FF"
        case .brideFriends: return "FFD9B3"
        case .groomFriends: return "B3FFD9"
        case .mutualFriends, .friends: return "D9B3FF"
        case .work: return "FFFAB3"
        case .extended: return "B3FFF0"
        case .other: return "E0E0E0"
        }
    }
}

enum MealChoice: String, Codable, CaseIterable {
    case meat = "Meat"
    case fish = "Fish"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case kids = "Kids Meal"
    case kosher = "Kosher"
    case halal = "Halal"
    case other = "Other"

    var icon: String {
        switch self {
        case .meat: return "fork.knife"
        case .fish: return "fish.fill"
        case .vegetarian, .vegan: return "leaf.fill"
        case .kids: return "star.fill"
        case .kosher, .halal: return "checkmark.seal.fill"
        case .other: return "questionmark.circle"
        }
    }
}