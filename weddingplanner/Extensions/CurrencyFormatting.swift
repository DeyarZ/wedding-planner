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

    /// The viewer's own currency, e.g. "EUR" in Germany. Locales that carry no
    /// currency at all fall back to USD.
    static var code: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    /// Bare symbol for the viewer's currency, for places where a full formatted
    /// amount does not fit (field prefixes, placeholders).
    static var symbol: String {
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
