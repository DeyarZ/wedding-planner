import XCTest

/// Drives the Settings sheet end-to-end: open it from the header gear, change
/// the couple names, total budget and currency, save, and confirm the Funds
/// tab renders the new total in the new currency.
final class SettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testChangeBudgetAndCurrencyFromSettings() throws {
        let app = XCUIApplication()
        // NSArgumentDomain: skip onboarding, mute today's cold-start paywall,
        // and pin the UI to en_US so the labels below are stable regardless of
        // the simulator's language. The currency override is deliberately NOT
        // passed here — an argument-domain value would shadow whatever Save
        // writes and the assertion below would be meaningless.
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-lastColdStartPaywallAt", "\(Date().timeIntervalSince1970)",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        app.launch()

        let gear = app.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 15), "gear icon missing from header")
        gear.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        attach(app, "1-settings-opened")

        let names = app.textFields["settings.coupleNames"]
        XCTAssertTrue(names.waitForExistence(timeout: 5))
        names.replaceText(with: "Sofía & Diego")

        let budget = app.textFields["settings.totalBudget"]
        XCTAssertTrue(budget.exists)
        budget.replaceText(with: "850000")

        // Currency: navigation-link picker → row → pops back on selection.
        let currencyRow = app.buttons["settings.currency"]
        XCTAssertTrue(currencyRow.exists, "currency picker missing")
        currencyRow.tap()
        // Sorted by name, so "Mexican Peso" sits mid-list and off-screen;
        // List only vends visible cells to accessibility, so scroll to it.
        let mxn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'MXN'")).firstMatch
        XCTAssertTrue(app.buttons["Automatic (USD)"].waitForExistence(timeout: 5), "currency list did not open")
        // Swipes carry momentum and overshoot; drags scroll a fixed distance.
        // A tap on a row that is only half on screen lands on the dimmed area
        // above the sheet (dismissing it) or under the home indicator.
        let safe = 220.0...(app.frame.maxY - 120)
        for _ in 0..<20 {
            if mxn.exists, safe.contains(mxn.frame.midY) { break }
            app.dragDown(by: 240)
        }
        XCTAssertTrue(mxn.exists && safe.contains(mxn.frame.midY), "MXN row never scrolled fully into view")
        attach(app, "2-currency-list")
        mxn.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        attach(app, "3-settings-filled")
        app.buttons["Save"].tap()

        // Funds tab must now show the new total in pesos. en_US + MXN renders
        // "MX$850,000"; anything still reading "$850,000" plain would mean the
        // override never reached the formatter.
        let funds = app.buttons["FUNDS"].exists ? app.buttons["FUNDS"] : app.staticTexts["FUNDS"]
        funds.firstMatch.tap()
        let total = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'MX$850,000'")).firstMatch
        XCTAssertTrue(total.waitForExistence(timeout: 5), "Funds tab does not show MX$850,000")
        attach(app, "4-funds-mxn")

        // Reopen: the sheet must load what was saved.
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["settings.coupleNames"].value as? String, "Sofía & Diego")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'MXN'")).firstMatch.exists)
        attach(app, "5-settings-reopened")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
}

private extension XCUIApplication {
    /// Scrolls content up by `points` with a momentum-free drag.
    func dragDown(by points: CGFloat) {
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        let end = start.withOffset(CGVector(dx: 0, dy: -points))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
    }
}

private extension XCUIElement {
    /// Trailing-aligned fields put the caret wherever the tap lands, so tap at
    /// the very end before deleting backwards; select-all via long press is
    /// flaky inside Forms.
    func replaceText(with text: String) {
        // An element tap focuses the field (and waits for the keyboard); the
        // coordinate tap alone does not register as focus for XCTest.
        tap()
        _ = XCUIApplication().keyboards.firstMatch.waitForExistence(timeout: 3)
        coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        if let current = value as? String, !current.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
        }
        typeText(text)
    }
}
