import SwiftUI

// MARK: - Display-only localization for String-backed enums
//
// These enums use their English `rawValue` as BOTH the persisted value
// (SwiftData / Codable storage, CSV export, equality checks) AND the label we
// show on screen. Handing a plain `String` to `Text` / `Label` skips the string
// catalog entirely, so those labels stayed English on non-English devices.
//
// `localizedName` resolves the rawValue through the catalog at render time.
// It is DISPLAY ONLY — `rawValue` itself is never changed, so nothing that is
// stored, compared, sorted or exported is affected.

protocol LocalizedRawRepresentable: RawRepresentable where RawValue == String {}

extension LocalizedRawRepresentable {
    /// Catalog-resolved label. Never persist, compare or export this value.
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }

    /// Same lookup as `localizedName`, resolved eagerly for the few APIs that
    /// need a plain `String` (accessibility labels, string interpolation).
    var localizedNameString: String { String(localized: String.LocalizationValue(rawValue)) }
}

// Budget
extension BudgetCategory: LocalizedRawRepresentable {}
extension PaymentStatusType: LocalizedRawRepresentable {}
extension BudgetPriority: LocalizedRawRepresentable {}
extension RecurringFrequency: LocalizedRawRepresentable {}
extension PaymentMethod: LocalizedRawRepresentable {}
extension TransactionType: LocalizedRawRepresentable {}

// Guests
extension RSVPStatus: LocalizedRawRepresentable {}
extension GuestGroup: LocalizedRawRepresentable {}
extension MealChoice: LocalizedRawRepresentable {}

// Vendors
extension VendorCategory: LocalizedRawRepresentable {}
extension CommunicationType: LocalizedRawRepresentable {}
extension VendorStatus: LocalizedRawRepresentable {}
extension PaymentStatus: LocalizedRawRepresentable {}
extension DocumentType: LocalizedRawRepresentable {}

// Schedule & tasks
extension EventCategory: LocalizedRawRepresentable {}
extension TaskCategory: LocalizedRawRepresentable {}
extension TaskPriority: LocalizedRawRepresentable {}

// MARK: - Budget item names

extension BudgetItem {
    /// Starter budgets seed `name` with the English category rawValue
    /// (`DataManager.createStarterBudget`), so the row would read "Venue &
    /// Catering" on a German device. When the stored name is still that
    /// untouched default we render the localized category instead.
    ///
    /// Display only — the persisted `name` is never rewritten, and the
    /// `name == category.rawValue` check keeps comparing English to English.
    var usesDefaultCategoryName: Bool { name == category.rawValue }

    /// `Text` for the item name, localized when it is still the seeded default.
    var displayNameText: Text {
        usesDefaultCategoryName ? Text(category.localizedName) : Text(name)
    }
}
