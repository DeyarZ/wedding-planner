import Foundation
import SwiftData

@Model
final class Vendor {
    var id: UUID
    var name: String
    var category: VendorCategory
    var contactName: String?
    var phone: String?
    var email: String?
    var website: String?
    var contractAmount: Double
    var depositPaid: Double
    var totalPaid: Double
    var notes: String?
    var specialInstructions: String?
    var rating: Int?
    var status: VendorStatus
    var contractDate: Date?
    var finalPaymentDueDate: Date?
    var logoImageData: Data?
    var contractFileData: Data?
    var contractFileName: String?
    var isBooked: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \Wedding.vendors) var wedding: Wedding?
    @Relationship(deleteRule: .cascade) var payments: [VendorPayment]?
    @Relationship(deleteRule: .cascade) var communications: [VendorCommunication]?
    @Relationship(deleteRule: .cascade) var documents: [VendorDocument]?
    // @Relationship(deleteRule: .cascade) var photos: [Photo]?  // Temporarily disabled
    
    init(name: String, category: VendorCategory, contractAmount: Double = 0) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.contractAmount = contractAmount
        self.depositPaid = 0
        self.totalPaid = 0
        self.status = .pending
        self.isBooked = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var remainingBalance: Double {
        contractAmount - totalPaid
    }
    
    var lastCommunication: Date? {
        communications?.sorted { $0.date > $1.date }.first?.date
    }

    var paymentProgress: Double {
        guard contractAmount > 0 else { return 0 }
        return totalPaid / contractAmount
    }

    var paymentStatus: PaymentStatus {
        if totalPaid >= contractAmount {
            return .paidInFull
        } else if depositPaid > 0 {
            return .depositPaid
        } else {
            return .outstanding
        }
    }
}

enum VendorCategory: String, Codable, CaseIterable {
    case venue = "Venue"
    case catering = "Catering"
    case photography = "Photography"
    case videography = "Videography"
    case florist = "Florist"
    case music = "Music/DJ"
    case planner = "Wedding Planner"
    case officiant = "Officiant"
    case transportation = "Transportation"
    case cake = "Cake/Desserts"
    case attire = "Attire"
    case beauty = "Hair & Makeup"
    case decor = "Decor/Rentals"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .venue: return "building.2"
        case .catering: return "fork.knife"
        case .photography: return "camera"
        case .videography: return "video"
        case .florist: return "leaf"
        case .music: return "music.note"
        case .planner: return "calendar"
        case .officiant: return "book"
        case .transportation: return "car"
        case .cake: return "birthday.cake"
        case .attire: return "tshirt"
        case .beauty: return "sparkles"
        case .decor: return "lamp.table"
        case .other: return "ellipsis"
        }
    }
}

@Model
final class VendorPayment {
    var amount: Double
    var date: Date
    var paymentMethod: String?
    var notes: String?
    
    @Relationship(inverse: \Vendor.payments) var vendor: Vendor?
    
    init(amount: Double, date: Date = Date()) {
        self.amount = amount
        self.date = date
    }
}

@Model
final class VendorCommunication {
    var date: Date
    var type: CommunicationType
    var subject: String
    var notes: String?
    var followUpDate: Date?
    
    @Relationship(inverse: \Vendor.communications) var vendor: Vendor?
    
    init(type: CommunicationType, subject: String, date: Date = Date()) {
        self.type = type
        self.subject = subject
        self.date = date
    }
}

enum CommunicationType: String, Codable, CaseIterable {
    case email = "Email"
    case phone = "Phone"
    case meeting = "Meeting"
    case text = "Text"
    case whatsapp = "WhatsApp"
    case videoCall = "Video Call"
}

enum VendorStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case booked = "Booked"
    case confirmed = "Confirmed"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .pending: return "FFA726"
        case .booked: return "66BB6A"
        case .confirmed: return "42A5F5"
        case .cancelled: return "EF5350"
        }
    }
}

enum PaymentStatus: String, CaseIterable {
    case outstanding = "Outstanding"
    case depositPaid = "Deposit Paid"
    case paidInFull = "Paid in Full"

    var color: String {
        switch self {
        case .outstanding: return "EF5350"
        case .depositPaid: return "FFA726"
        case .paidInFull: return "66BB6A"
        }
    }
}

@Model
final class VendorDocument {
    var id: UUID
    var fileName: String
    var fileData: Data
    var uploadDate: Date
    var documentType: DocumentType

    @Relationship(inverse: \Vendor.documents) var vendor: Vendor?

    init(fileName: String, fileData: Data, documentType: DocumentType) {
        self.id = UUID()
        self.fileName = fileName
        self.fileData = fileData
        self.documentType = documentType
        self.uploadDate = Date()
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case contract = "Contract"
    case invoice = "Invoice"
    case proposal = "Proposal"
    case portfolio = "Portfolio"
    case other = "Other"
}