import Foundation

/// Builds the checklist the app seeds on day one.
///
/// The old onboarding created exactly five tasks (`tasks.prefix(5)`) — the same
/// number as the free-task limit — so a brand new user opened an app that was
/// simultaneously empty and already at its cap. This generates the full,
/// backwards-planned wedding checklist; limiting what a free user may do is the
/// gate's job, not the seed's.
enum OnboardingChecklist {

    /// One row of the master template. `monthsBefore` is measured backwards
    /// from the wedding day, which is how every real wedding checklist works.
    private struct Template {
        let id: String
        let title: String
        let detail: String
        let category: String
        let monthsBefore: Int
        let priority: Int
        let minutes: Int
        /// Seeded even when the wedding is only weeks away.
        let alwaysInclude: Bool
        /// Priority ids (from the priorities question) that make this task
        /// more urgent for this couple.
        let boostedBy: [String]

        init(_ id: String,
             _ title: String,
             _ detail: String,
             category: String,
             monthsBefore: Int,
             priority: Int,
             minutes: Int,
             alwaysInclude: Bool = false,
             boostedBy: [String] = []) {
            self.id = id
            self.title = title
            self.detail = detail
            self.category = category
            self.monthsBefore = monthsBefore
            self.priority = priority
            self.minutes = minutes
            self.alwaysInclude = alwaysInclude
            self.boostedBy = boostedBy
        }
    }

    private static let master: [Template] = [
        // 12+ months out
        Template("budget_review", "Review your budget breakdown",
                 "See how your budget splits across all 12 categories and adjust it",
                 category: "budget", monthsBefore: 12, priority: 1, minutes: 10,
                 alwaysInclude: true, boostedBy: ["budget"]),
        Template("guest_list", "Draft your guest list",
                 "Add everyone you want there — you can refine it any time",
                 category: "guests", monthsBefore: 12, priority: 1, minutes: 25,
                 alwaysInclude: true, boostedBy: ["guest_experience"]),
        Template("wedding_vision", "Agree on your wedding vision",
                 "Style, season and the three things that matter most to you both",
                 category: "planning", monthsBefore: 12, priority: 2, minutes: 20),
        Template("venue_research", "Research venues",
                 "Shortlist places that fit your guest count and your style",
                 category: "venue", monthsBefore: 11, priority: 1, minutes: 30,
                 boostedBy: ["venue"]),
        Template("venue_visits", "Book venue viewings",
                 "See your top three in person before you commit",
                 category: "venue", monthsBefore: 10, priority: 2, minutes: 20,
                 boostedBy: ["venue"]),
        Template("save_dates", "Send save the dates",
                 "Give everyone — especially travelling guests — a heads up",
                 category: "invitations", monthsBefore: 9, priority: 2, minutes: 20),
        Template("photographer", "Find your photographer",
                 "Book early: the good ones go a year ahead",
                 category: "photography", monthsBefore: 9, priority: 2, minutes: 45,
                 boostedBy: ["photography"]),
        Template("catering_style", "Choose your catering style",
                 "Plated dinner, buffet or a relaxed cocktail reception",
                 category: "catering", monthsBefore: 8, priority: 3, minutes: 15,
                 boostedBy: ["food"]),
        Template("attire_shopping", "Start looking for your outfits",
                 "Dresses and suits often need three to six months of fittings",
                 category: "attire", monthsBefore: 8, priority: 2, minutes: 60,
                 boostedBy: ["attire"]),
        Template("music", "Book music or a DJ",
                 "Decide between a band, a DJ or your own playlist",
                 category: "entertainment", monthsBefore: 7, priority: 3, minutes: 30,
                 boostedBy: ["music"]),
        Template("officiant", "Confirm your officiant",
                 "Lock in who will actually marry you and on which date",
                 category: "legal", monthsBefore: 7, priority: 2, minutes: 15),
        Template("florist", "Meet a florist",
                 "Bring photos — flowers are easier to show than to describe",
                 category: "flowers", monthsBefore: 6, priority: 3, minutes: 30,
                 boostedBy: ["flowers"]),
        Template("cake", "Taste and order the cake",
                 "Book the tasting, then confirm flavours and size",
                 category: "catering", monthsBefore: 6, priority: 3, minutes: 45,
                 boostedBy: ["food"]),
        Template("accommodation", "Sort guest accommodation",
                 "Hold a block of rooms for guests travelling in",
                 category: "accommodation", monthsBefore: 6, priority: 3, minutes: 25),
        Template("decor", "Plan the decorations",
                 "Table settings, lighting and the little details people remember",
                 category: "decorations", monthsBefore: 5, priority: 3, minutes: 30,
                 boostedBy: ["flowers"]),
        Template("invitations", "Order the invitations",
                 "Design, proofread and print — allow time for a reprint",
                 category: "invitations", monthsBefore: 4, priority: 2, minutes: 40),
        Template("transport", "Arrange transport",
                 "Getting you, the party and the guests between locations",
                 category: "transportation", monthsBefore: 4, priority: 4, minutes: 20),
        Template("legal_docs", "Collect your marriage paperwork",
                 "Check exactly which documents your registry office needs",
                 category: "legal", monthsBefore: 3, priority: 1, minutes: 30,
                 alwaysInclude: true),
        Template("send_invitations", "Send the invitations",
                 "Set an RSVP deadline about a month before the day",
                 category: "invitations", monthsBefore: 3, priority: 1, minutes: 45,
                 alwaysInclude: true),
        Template("beauty_trial", "Book a hair and make-up trial",
                 "Do it on a day you can photograph the result",
                 category: "attire", monthsBefore: 3, priority: 3, minutes: 90,
                 boostedBy: ["attire"]),
        Template("vendor_payments", "Check your vendor payments",
                 "Confirm what is paid, what is due and when",
                 category: "vendors", monthsBefore: 2, priority: 2, minutes: 20,
                 alwaysInclude: true, boostedBy: ["budget"]),
        Template("rsvp_chase", "Chase the missing RSVPs",
                 "A friendly nudge to everyone who has not replied yet",
                 category: "guests", monthsBefore: 2, priority: 2, minutes: 20,
                 alwaysInclude: true, boostedBy: ["guest_experience"]),
        Template("seating", "Build the seating plan",
                 "Who sits where — with dietary notes and plus-ones in one place",
                 category: "planning", monthsBefore: 1, priority: 2, minutes: 60,
                 alwaysInclude: true, boostedBy: ["guest_experience"]),
        Template("day_schedule", "Write the wedding day schedule",
                 "Hour by hour, from getting ready to the last dance",
                 category: "planning", monthsBefore: 1, priority: 1, minutes: 45,
                 alwaysInclude: true),
        Template("final_headcount", "Give the venue the final headcount",
                 "Most venues need the number about two weeks out",
                 category: "venue", monthsBefore: 1, priority: 1, minutes: 10,
                 alwaysInclude: true),
        Template("vendor_confirm", "Confirm every vendor",
                 "Arrival times, contacts and final balances in writing",
                 category: "vendors", monthsBefore: 0, priority: 1, minutes: 30,
                 alwaysInclude: true),
        Template("pack_day_bag", "Pack your wedding day bag",
                 "Rings, vows, documents, flats and a phone charger",
                 category: "other", monthsBefore: 0, priority: 2, minutes: 20,
                 alwaysInclude: true)
    ]

    /// The seeded checklist for one couple, sorted by due date.
    static func tasks(daysUntilWedding: Int,
                      stage: PlanningStage,
                      priorities: Set<String>,
                      stressors: Set<Stressor>) -> [InitialTaskData] {

        let monthsLeft = max(0, daysUntilWedding / 30)

        // Anything scheduled for a window that has already closed is dropped —
        // a couple three weeks out does not need "research venues".
        let relevant = master.filter { template in
            template.alwaysInclude || template.monthsBefore <= monthsLeft + 1
        }

        // Couples who already booked the venue do not want it on their list.
        let stageFiltered = relevant.filter { template in
            switch stage {
            case .venueBooked, .finalStretch:
                return !["venue_research", "venue_visits", "wedding_vision"].contains(template.id)
            case .earlyPlanning:
                return template.id != "wedding_vision"
            case .justEngaged:
                return true
            }
        }

        return stageFiltered.map { template -> InitialTaskData in
            // Ideal lead time, clamped into the window that is actually left.
            let ideal = daysUntilWedding - (template.monthsBefore * 30)
            let days = min(max(1, ideal), max(1, daysUntilWedding))

            var priority = template.priority
            if !template.boostedBy.isEmpty,
               template.boostedBy.contains(where: { priorities.contains($0) }) {
                priority = max(1, priority - 1)
            }
            if stressorBoost(template, stressors) {
                priority = max(1, priority - 1)
            }

            return InitialTaskData(
                id: template.id,
                // Runtime keys: the copy lives in Localizable.xcstrings and is
                // resolved by key, because the template is data, not literals.
                title: NSLocalizedString(template.title, comment: "Seeded checklist task title"),
                description: NSLocalizedString(template.detail, comment: "Seeded checklist task detail"),
                category: template.category,
                priority: priority,
                estimatedTime: estimatedTime(template.minutes),
                daysFromNow: days
            )
        }
        .sorted { ($0.daysFromNow ?? 0) < ($1.daysFromNow ?? 0) }
    }

    private static func stressorBoost(_ template: Template, _ stressors: Set<Stressor>) -> Bool {
        for stressor in stressors {
            switch stressor {
            case .budget where template.category == "budget" || template.category == "vendors": return true
            case .guestList where template.category == "guests": return true
            case .vendors where template.category == "vendors": return true
            case .timeline where template.category == "planning": return true
            default: continue
            }
        }
        return false
    }

    private static func estimatedTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            return String(localized: "\(hours) h")
        }
        return String(localized: "\(minutes) min")
    }
}
