//
//  CurrencyFormatting.swift
//  weddingplanner
//
//  Locale-aware display of USER-ENTERED money.
//

import Foundation

/// Formatting for money the couple typed in themselves — budgets, vendor
/// contracts, deposits, payments.
///
/// Every screen used to hardcode `currencyCode = "USD"` (or, worse,
/// `String(format: "$%.2f", …)`), so a German user entered a 50,000 budget and
/// then read it back as "$50,000". Everything here derives from
/// `Locale.current`, matching the existing `OnboardingCurrency` in the
/// onboarding flow.
///
/// - Important: This is **not** for App Store prices. StoreKit / RevenueCat
///   hand back prices already localized to the customer's storefront, and those
///   must be displayed verbatim — never routed through here.
enum BudgetCurrency {

    /// UserDefaults key for the explicit currency choice made in Settings. An
    /// empty string means "follow the device region".
    static let overrideKey = "budget_currency_override"

    /// The currency the device region implies, e.g. "EUR" in Germany. Locales
    /// that carry no currency at all fall back to USD.
    static var automaticCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    /// The currency chosen in Settings, or `nil` when the viewer follows the
    /// device region. Stored as a bare ISO code, never a symbol.
    static var override: String? {
        get {
            let stored = UserDefaults.standard.string(forKey: overrideKey) ?? ""
            return stored.isEmpty ? nil : stored
        }
        set {
            UserDefaults.standard.set(newValue ?? "", forKey: overrideKey)
        }
    }

    /// The currency every user-entered amount is displayed in: the explicit
    /// choice from Settings when there is one, the device region otherwise.
    ///
    /// A couple planning a Mexican wedding from a US-region iPad needs the
    /// override — the region alone would print pesos as dollars forever.
    static var code: String {
        override ?? automaticCode
    }

    /// The currencies offered in Settings. Common wedding-market currencies
    /// plus whatever the device region and the current choice resolve to, so
    /// the picker can always show the selected value. Sorted by localized name.
    static var selectableCodes: [String] {
        let common = [
            "USD", "EUR", "GBP", "MXN", "CAD", "AUD", "NZD", "BRL", "ARS", "CLP",
            "COP", "PEN", "CHF", "SEK", "NOK", "DKK", "ISK", "PLN", "CZK", "HUF",
            "RON", "TRY", "RUB", "UAH", "ILS", "AED", "SAR", "EGP", "MAD",
            "ZAR", "NGN", "KES", "INR", "PKR", "IDR", "MYR", "SGD", "THB", "VND",
            "PHP", "JPY", "KRW", "CNY", "TWD", "HKD"
        ]
        var codes = Set(common)
        codes.insert(automaticCode)
        if let override { codes.insert(override) }
        return codes.sorted { localizedName(for: $0) < localizedName(for: $1) }
    }

    /// "Mexican Peso" in the viewer's language; the bare code when the OS has
    /// no name for it.
    static func localizedName(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// Bare symbol for the viewer's currency, for places where a full formatted
    /// amount does not fit (field prefixes, placeholders).
    static var symbol: String {
        symbol(for: code)
    }

    /// Bare symbol for an arbitrary currency, e.g. "MX$" for MXN on an en_US
    /// device but "$" on an es_MX one.
    static func symbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        formatter.currencyCode = code
        return formatter.currencySymbol ?? "$"
    }

    /// Currencies without minor units. Asking for cents in one of these would
    /// print "¥1,200.00", which is simply wrong, so the request gets clamped.
    /// Mirrors the list in `OnboardingCurrency`.
    private static let zeroDecimalCurrencies: Set<String> = [
        "JPY", "KRW", "VND", "CLP", "ISK", "HUF", "TWD", "COP", "IDR"
    ]

    static func resolvedFractionDigits(_ requested: Int) -> Int {
        zeroDecimalCurrencies.contains(code) ? 0 : requested
    }
}

/// Formats a stored amount in the viewer's own currency.
///
/// No FX conversion happens and none is wanted: a budget stored as `50000` stays
/// 50000, it is only *displayed* with the local symbol, grouping and separator.
///
/// - Parameters:
///   - amount: the stored value, a plain number.
///   - fractionDigits: `0` for headline and summary figures (the common case),
///     `2` where cents are meaningful — payment rows, contract amounts.
func formatBudget(_ amount: Double, fractionDigits: Int = 0) -> String {
    let digits = BudgetCurrency.resolvedFractionDigits(fractionDigits)

    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = .current
    formatter.currencyCode = BudgetCurrency.code
    formatter.maximumFractionDigits = digits
    formatter.minimumFractionDigits = digits

    return formatter.string(from: NSNumber(value: amount))
        ?? BudgetCurrency.symbol + String(format: "%.\(digits)f", amount)
}
