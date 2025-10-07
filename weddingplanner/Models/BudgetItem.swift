import Foundation
import SwiftData

@Model
final class BudgetItem {
    var id: UUID
    var name: String
    var category: BudgetCategory
    var estimatedAmount: Double
    var amountSpent: Double
    var depositAmount: Double
    var depositPaid: Bool
    var isPaid: Bool
    var paymentDueDate: Date?
    var depositDueDate: Date?
    var finalPaymentDueDate: Date?
    var paymentStatus: PaymentStatusType
    var priority: BudgetPriority
    var notes: String?
    var invoiceNumber: String?
    var contractNumber: String?
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Wedding.budgetItems) var wedding: Wedding?
    @Relationship var vendor: Vendor?
    @Relationship(deleteRule: .cascade) var transactions: [Transaction]?
    
    init(name: String, category: BudgetCategory, estimatedAmount: Double) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.estimatedAmount = estimatedAmount
        self.amountSpent = 0
        self.depositAmount = 0
        self.depositPaid = false
        self.isPaid = false
        self.paymentStatus = .pending
        self.priority = .normal
        self.isRecurring = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var remainingAmount: Double {
        estimatedAmount - amountSpent
    }
    
    var isOverBudget: Bool {
        amountSpent > estimatedAmount
    }
    
    var percentageSpent: Double {
        guard estimatedAmount > 0 else { return 0 }
        return (amountSpent / estimatedAmount) * 100
    }

    var isOverdue: Bool {
        guard let dueDate = paymentDueDate, !isPaid else { return false }
        return dueDate < Date()
    }

    var daysUntilDue: Int? {
        guard let dueDate = paymentDueDate, !isPaid else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return days
    }

    var outstandingAmount: Double {
        max(0, estimatedAmount - amountSpent)
    }
}

enum BudgetCategory: String, Codable, CaseIterable {
    case venue = "Venue & Catering"
    case photography = "Photography & Video"
    case attire = "Attire & Beauty"
    case flowers = "Flowers & Decor"
    case entertainment = "Entertainment"
    case invitations = "Invitations & Favors"
    case transportation = "Transportation"
    case accommodation = "Accommodation"
    case rings = "Rings & Jewelry"
    case gifts = "Gifts"
    case honeymoon = "Honeymoon"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .venue: return "building.2"
        case .photography: return "camera"
        case .attire: return "tshirt"
        case .flowers: return "leaf"
        case .entertainment: return "music.note"
        case .invitations: return "envelope"
        case .transportation: return "car"
        case .accommodation: return "bed.double"
        case .rings: return "circle.circle"
        case .gifts: return "gift"
        case .honeymoon: return "airplane"
        case .other: return "ellipsis"
        }
    }
    
    var defaultPercentage: Double {
        switch self {
        case .venue: return 40
        case .photography: return 12
        case .attire: return 8
        case .flowers: return 8
        case .entertainment: return 8
        case .invitations: return 3
        case .transportation: return 3
        case .accommodation: return 5
        case .rings: return 5
        case .gifts: return 3
        case .honeymoon: return 5
        case .other: return 0
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var date: Date
    var paymentMethod: PaymentMethod
    var transactionDescription: String?
    var transactionType: TransactionType
    var receiptData: Data?
    var receiptFileName: String?
    var referenceNumber: String?
    var isVerified: Bool

    @Relationship(inverse: \BudgetItem.transactions) var budgetItem: BudgetItem?

    init(amount: Double, type: TransactionType, date: Date = Date(), description: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.transactionType = type
        self.date = date
        self.transactionDescription = description
        self.paymentMethod = .cash
        self.isVerified = false
    }
}

enum PaymentStatusType: String, Codable, CaseIterable {
    case pending = "Pending"
    case depositPaid = "Deposit Paid"
    case partiallyPaid = "Partially Paid"
    case fullyPaid = "Fully Paid"
    case overdue = "Overdue"
    case cancelled = "Cancelled"

    var color: String {
        switch self {
        case .pending: return "FFA726"
        case .depositPaid: return "42A5F5"
        case .partiallyPaid: return "9C27B0"
        case .fullyPaid: return "66BB6A"
        case .overdue: return "EF5350"
        case .cancelled: return "9E9E9E"
        }
    }
}

enum BudgetPriority: String, Codable, CaseIterable {
    case essential = "Essential"
    case high = "High"
    case normal = "Normal"
    case low = "Low"
    case optional = "Optional"
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case bankTransfer = "Bank Transfer"
    case check = "Check"
    case paypal = "PayPal"
    case venmo = "Venmo"
    case other = "Other"
}

enum TransactionType: String, Codable, CaseIterable {
    case deposit = "Deposit"
    case payment = "Payment"
    case finalPayment = "Final Payment"
    case refund = "Refund"
    case adjustment = "Adjustment"
}