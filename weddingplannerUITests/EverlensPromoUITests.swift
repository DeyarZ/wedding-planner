import XCTest

/// Walks every Everlens placement on a fresh install: the seeded guest-photos
/// task (dashboard milestone → task sheet → promo sheet), the compact banner on
/// the timeline card, the photographer banner in the vendors tab, and — after
/// pulling the wedding date inside 60 days via Settings — the dashboard card.
final class EverlensPromoUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEverlensPlacements() throws {
        let app = XCUIApplication()
        // Fresh install + completed onboarding → ContentView creates the
        // "Emma & James" fallback wedding 180 days out with no seeded tasks,
        // so the Everlens task is the only one and therefore the next milestone.
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-lastColdStartPaywallAt", "\(Date().timeIntervalSince1970)",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        app.launch()

        // 1. Dashboard → next milestone is the seeded task → task sheet carries the banner.
        let milestone = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Collect your guests'")).firstMatch
        XCTAssertTrue(milestone.waitForExistence(timeout: 20), "seeded Everlens task is not the next milestone")
        attach(app, "1-dashboard-milestone")
        milestone.tap()

        let taskBanner = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Everlens'")).firstMatch
        XCTAssertTrue(taskBanner.waitForExistence(timeout: 5), "banner missing from task sheet")
        attach(app, "2-task-sheet-banner")
        taskBanner.tap()

        let sheetTitle = app.staticTexts["Your wedding through your guests' eyes"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5), "Everlens sheet did not open from task sheet")
        XCTAssertTrue(app.buttons["Get Everlens — it's free"].exists)
        attach(app, "3-everlens-sheet")
        app.buttons["everlens.notNow"].tap()
        XCTAssertTrue(waitForDisappearance(sheetTitle, timeout: 5))
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // 2. Timeline → the task card carries the compact banner.
        navigate(app, to: "TIME")
        let timelineBanner = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Everlens'")).firstMatch
        XCTAssertTrue(timelineBanner.waitForExistence(timeout: 10), "banner missing from timeline card")
        // The card sits below the phase carousel; bring it into view so the
        // attachment actually shows it.
        for _ in 0..<4 where !timelineBanner.isHittable { scroll(app, by: 300) }
        attach(app, "4-timeline-card")
        timelineBanner.tap()
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5), "Everlens sheet did not open from timeline")
        app.buttons["everlens.notNow"].tap()
        XCTAssertTrue(waitForDisappearance(sheetTitle, timeout: 5))

        // 3. Team → Photography filter → banner under the chips. The "All" chip
        // only exists on this tab, so it proves the tab switch actually landed
        // (the timeline card also carries a "Photography" label).
        navigate(app, to: "TEAM")
        let allChip = app.buttons["All"].exists ? app.buttons["All"] : app.staticTexts["All"]
        XCTAssertTrue(allChip.firstMatch.waitForExistence(timeout: 10), "Team tab did not open")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Everlens'")).firstMatch.exists,
                       "banner must not show before the Photography filter is active")
        let chip = app.buttons["Photography"].exists ? app.buttons["Photography"] : app.staticTexts["Photography"]
        XCTAssertTrue(chip.firstMatch.waitForExistence(timeout: 5), "Photography chip missing")
        chip.firstMatch.tap()
        let vendorsBanner = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Everlens'")).firstMatch
        XCTAssertTrue(vendorsBanner.waitForExistence(timeout: 5), "banner missing from vendors tab")
        attach(app, "5-vendors-photography")
        vendorsBanner.tap()
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5), "Everlens sheet did not open from vendors tab")
        app.buttons["everlens.notNow"].tap()
        XCTAssertTrue(waitForDisappearance(sheetTitle, timeout: 5))

        // 4. Settings → wedding date 30 days out → dashboard shows the card.
        navigate(app, to: "HOME")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Give your guests a camera'")).firstMatch.exists,
                       "dashboard card must stay hidden at 180 days")
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        try pickWeddingDate(app, daysFromNow: 30)
        attach(app, "6-settings-date-moved")
        app.buttons["Save"].tap()

        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Give your guests a camera'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "dashboard card missing at 30 days")
        attach(app, "7-dashboard-card")
        card.tap()
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5), "Everlens sheet did not open from dashboard card")
        app.buttons["everlens.notNow"].tap()
        XCTAssertTrue(waitForDisappearance(sheetTitle, timeout: 5))

        let close = app.buttons["everlens.dismissCard"]
        XCTAssertTrue(close.waitForExistence(timeout: 5), "dashboard card close button missing")
        close.tap()
        XCTAssertTrue(waitForDisappearance(card, timeout: 5), "dashboard card did not dismiss")
        attach(app, "8-dashboard-card-dismissed")

        // 5. The call to action raises the SKOverlay above the sheet. On the
        // Simulator StoreKit renders it as an "App Store · Developer Preview"
        // placeholder in a remote view that is invisible to accessibility, so
        // the attachment is the evidence; the app staying in front proves the
        // URL fallback did not fire instead.
        navigate(app, to: "TIME")
        XCTAssertTrue(timelineBanner.waitForExistence(timeout: 10))
        timelineBanner.tap()
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5))
        app.buttons["Get Everlens — it's free"].tap()
        sleep(3)
        attach(app, "9-store-overlay")
        XCTAssertEqual(app.state, .runningForeground, "app left the foreground — the URL fallback fired instead of SKOverlay")
        XCTAssertTrue(sheetTitle.exists)
    }

    // MARK: - Helpers

    private func navigate(_ app: XCUIApplication, to item: String) {
        let element = app.buttons[item].exists ? app.buttons[item] : app.staticTexts[item]
        element.firstMatch.tap()
    }

    /// Compact `DatePicker` → month grid popover → step back to the target
    /// month → tap the day. The fallback wedding sits 180 days out, so the
    /// target is always in an earlier month.
    private func pickWeddingDate(_ app: XCUIApplication, daysFromNow: Int) throws {
        let calendar = Calendar(identifier: .gregorian)
        let current = calendar.date(byAdding: .day, value: 180, to: Date())!
        let target = calendar.date(byAdding: .day, value: daysFromNow, to: Date())!
        let monthsBack = calendar.dateComponents([.month],
                                                 from: calendar.date(from: calendar.dateComponents([.year, .month], from: target))!,
                                                 to: calendar.date(from: calendar.dateComponents([.year, .month], from: current))!).month ?? 0

        let picker = app.datePickers.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "wedding date picker missing")
        picker.buttons.firstMatch.tap()

        let previous = app.buttons["Previous Month"]
        XCTAssertTrue(previous.waitForExistence(timeout: 5), "month grid did not open")
        for _ in 0..<monthsBack { previous.tap() }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d"
        let dayLabel = formatter.string(from: target)
        let day = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", dayLabel)).firstMatch
        XCTAssertTrue(day.waitForExistence(timeout: 5), "day '\(dayLabel)' not in month grid")
        day.tap()

        // Close the popover; the dismiss region is a real element on iPhone.
        if app.buttons["PopoverDismissRegion"].exists {
            app.buttons["PopoverDismissRegion"].tap()
        } else {
            app.navigationBars["Settings"].tap()
        }
    }

    /// Momentum-free scroll: swipes overshoot, drags move a fixed distance.
    private func scroll(_ app: XCUIApplication, by points: CGFloat) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = start.withOffset(CGVector(dx: 0, dy: -points))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
}
