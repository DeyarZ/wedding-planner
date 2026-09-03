import SwiftUI

// MARK: - 18. Building the plan

/// The "we are doing work for you" beat. It is short, it is honest about what
/// it is assembling, and it auto-advances — no button to hunt for.
struct OnboardingBuildingPlanScreen: View {
    @EnvironmentObject var data: OnboardingData
    /// A paged TabView builds its neighbours ahead of time and fires their
    /// `onAppear`. Without this the progress bar would run — and finish — while
    /// the screen is still offscreen, leaving the user stranded on a completed
    /// bar that never advances.
    let isCurrent: Bool
    let onContinue: () -> Void

    @State private var progress: CGFloat = 0
    @State private var stepIndex = 0
    @State private var shown = false
    @State private var timer: Timer?

    private var steps: [String] {
        [
            String(localized: "Reading your date…"),
            String(localized: "Laying out your checklist…"),
            String(localized: "Splitting \(data.formattedBudget) across 12 categories…"),
            String(localized: "Preparing your guest list…"),
            String(localized: "Almost ready…")
        ]
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(OnboardingStyle.accent.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .scaleEffect(1 + progress * 0.12)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(OnboardingStyle.accent)
                }
                .onboardingAppear(shown, delay: 0.05, offset: 0)

                Spacer().frame(height: 40)

                Text("BUILDING YOUR PLAN")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .onboardingAppear(shown, delay: 0.15)

                Spacer().frame(height: 34)

                // Progress track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(OnboardingStyle.accent.opacity(0.16))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [OnboardingStyle.accent, OnboardingStyle.blush],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 44)

                Spacer().frame(height: 18)

                Text(steps[min(stepIndex, steps.count - 1)])
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .id(stepIndex)
                    .transition(.opacity)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(OnboardingStyle.inkFaint)
                    .monospacedDigit()
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            shown = true
            if isCurrent { start() }
        }
        .onChange(of: isCurrent) { _, current in
            if current { start() }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func start() {
        guard timer == nil else { return }
        let total = 3.2
        let tick = 0.05
        var elapsed: Double = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { current in
            elapsed += tick
            let t = min(1, elapsed / total)
            progress = CGFloat(1 - pow(1 - t, 2))

            let newStep = min(steps.count - 1, Int(t * Double(steps.count)))
            if newStep != stepIndex {
                withAnimation(.easeInOut(duration: 0.25)) { stepIndex = newStep }
            }

            if t >= 1 {
                current.invalidate()
                timer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onContinue() }
            }
        }
    }
}

// MARK: - 19. Plan reveal

/// The moment the wedding actually exists in SwiftData. Everything shown here
/// is read back from what was just created — nothing is decorative.
struct OnboardingPlanRevealScreen: View {
    @EnvironmentObject var data: OnboardingData
    @EnvironmentObject var dataManager: DataManager
    let onContinue: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 66)

                Text("YOUR PLAN IS READY")
                    .font(.system(size: 27, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .onboardingAppear(shown, delay: 0.05)

                Spacer().frame(height: 8)

                Text(data.coupleNames)
                    .font(.system(size: 19, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
                    .onboardingAppear(shown, delay: 0.12)

                Spacer().frame(height: 26)

                VStack(spacing: 12) {
                    row(icon: "checklist", index: 0,
                        title: String(localized: "\(data.taskCount) tasks on your checklist"),
                        detail: String(localized: "Dated backwards from your wedding day"))

                    row(icon: "chart.pie.fill", index: 1,
                        title: String(localized: "\(data.formattedBudget) split across 12 categories"),
                        detail: String(localized: "Weighted towards what matters most to you"))

                    row(icon: "person.3.fill", index: 2,
                        title: String(localized: "Guest list ready for \(data.guestCount)"),
                        detail: String(localized: "RSVPs, plus-ones and dietary notes included"))

                    row(icon: "calendar.badge.clock", index: 3,
                        title: data.hasDate
                            ? String(localized: "\(data.daysUntilWedding) days to go")
                            : String(localized: "A flexible twelve-month plan"),
                        detail: data.hasDate ? data.formattedDate : String(localized: "Set your date any time"))
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Show me", action: onContinue)
                    .onboardingAppear(shown, delay: 0.75, offset: 28)

                Spacer().frame(height: 50)
            }
            .onboardingScreenScroll()
        }
        .onAppear {
            // The wedding, its budget categories and the full checklist are
            // created here — one call, the same DataManager entry point the
            // previous onboarding used.
            data.createWeddingWithData(using: dataManager)
            shown = true
        }
    }

    private func row(icon: String, index: Int, title: String, detail: String) -> some View {
        OnboardingCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(OnboardingStyle.accent.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(OnboardingStyle.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(OnboardingStyle.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundColor(OnboardingStyle.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .onboardingAppear(shown, delay: 0.2 + Double(index) * 0.11, offset: 24)
    }
}

// MARK: - 20–22. Feature previews

/// Three previews of the app the user just filled with their own data. Same
/// layout, different payload — checklist, budget, guests.
struct OnboardingFeaturePreviewScreen: View {
    enum Kind { case checklist, budget, guests }

    @EnvironmentObject var data: OnboardingData
    let kind: Kind
    let onContinue: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 62)

                OnboardingTitle(kicker: kicker, title: title, subtitle: subtitle, titleSize: 26)
                    .onboardingAppear(shown, delay: 0.05)

                Spacer().frame(height: 26)

                preview
                    .padding(.horizontal, 24)
                    .onboardingAppear(shown, delay: 0.25, offset: 26)

                Spacer()

                OnboardingPrimaryButton(title: "Continue", action: onContinue)
                    .onboardingAppear(shown, delay: 0.55, offset: 28)

                Spacer().frame(height: 48)
            }
            .onboardingScreenScroll()
        }
        .onAppear { shown = true }
    }

    // MARK: Copy

    private var kicker: LocalizedStringKey {
        switch kind {
        case .checklist: return "Your checklist"
        case .budget:    return "Your budget"
        case .guests:    return "Your guests"
        }
    }

    private var title: LocalizedStringKey {
        switch kind {
        case .checklist: return "NOTHING GETS FORGOTTEN"
        case .budget:    return "EVERY COST IN ONE PLACE"
        case .guests:    return "ONE LIST, ALWAYS CURRENT"
        }
    }

    private var subtitle: LocalizedStringKey? {
        switch kind {
        case .checklist: return "Your next steps, already in order."
        case .budget:    return "Split for you, adjustable at any time."
        case .guests:    return "RSVPs, plus-ones and seating in one place."
        }
    }

    // MARK: Payload

    @ViewBuilder
    private var preview: some View {
        switch kind {
        case .checklist: checklistPreview
        case .budget:    budgetPreview
        case .guests:    guestPreview
        }
    }

    private var checklistPreview: some View {
        OnboardingCard {
            VStack(spacing: 0) {
                ForEach(Array(data.tasks.prefix(4).enumerated()), id: \.element.id) { index, task in
                    HStack(spacing: 14) {
                        Image(systemName: "circle")
                            .font(.system(size: 19, weight: .light))
                            .foregroundColor(OnboardingStyle.accent.opacity(0.6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(OnboardingStyle.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(dueLabel(task))
                                .font(.system(size: 12, weight: .regular, design: .serif))
                                .foregroundColor(OnboardingStyle.inkFaint)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)

                    if index < min(3, data.tasks.count - 1) {
                        Rectangle()
                            .fill(OnboardingStyle.hairline)
                            .frame(height: 1)
                    }
                }

                if data.taskCount > 4 {
                    Text(String(localized: "+ \(data.taskCount - 4) more, already scheduled"))
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(OnboardingStyle.accent)
                        .padding(.top, 14)
                }
            }
        }
    }

    private var budgetPreview: some View {
        OnboardingCard {
            VStack(spacing: 14) {
                Text(data.formattedBudget)
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)

                ForEach(Array(budgetSlices.enumerated()), id: \.offset) { _, slice in
                    VStack(spacing: 5) {
                        HStack {
                            Text(slice.name)
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(OnboardingStyle.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text(OnboardingCurrency.format(data.budget * slice.share))
                                .font(.system(size: 14, weight: .regular, design: .serif))
                                .foregroundColor(OnboardingStyle.inkSoft)
                                // The money never truncates — a long category
                                // name gives way instead.
                                .fixedSize()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(OnboardingStyle.hairline)
                                Capsule()
                                    .fill(OnboardingStyle.accent)
                                    .frame(width: geo.size.width * CGFloat(slice.share / 0.45))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    private var guestPreview: some View {
        OnboardingCard {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    stat(value: "\(data.guestCount)", label: String(localized: "Invited"))
                    Rectangle().fill(OnboardingStyle.hairline).frame(width: 1, height: 40)
                    stat(value: "0", label: String(localized: "Confirmed"))
                    Rectangle().fill(OnboardingStyle.hairline).frame(width: 1, height: 40)
                    stat(value: "\(max(1, data.guestCount / 10))", label: String(localized: "Tables"))
                }

                Rectangle().fill(OnboardingStyle.hairline).frame(height: 1)

                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(OnboardingStyle.accent.opacity(0.15))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(OnboardingStyle.accent)
                                )
                            RoundedRectangle(cornerRadius: 4)
                                .fill(OnboardingStyle.hairline)
                                .frame(width: CGFloat(110 - index * 18), height: 9)
                            Spacer()
                            Text("RSVP")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(OnboardingStyle.inkFaint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "F4F1EC")))
                        }
                    }
                }
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(OnboardingStyle.ink)
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundColor(OnboardingStyle.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    /// The three biggest slices, boosted by whatever the couple said matters.
    private var budgetSlices: [(name: String, share: Double)] {
        var slices: [(String, Double)] = [
            (String(localized: "Venue & catering"), 0.40),
            (String(localized: "Photography"), 0.12),
            (String(localized: "Attire & beauty"), 0.10)
        ]
        if data.priorities.contains("photography") { slices[1].1 = 0.16 }
        if data.priorities.contains("attire") { slices[2].1 = 0.14 }
        if data.priorities.contains("venue") || data.priorities.contains("food") { slices[0].1 = 0.45 }
        return slices.map { (name: $0.0, share: $0.1) }
    }

    private func dueLabel(_ task: InitialTaskData) -> String {
        let days = task.daysFromNow ?? 7
        if days <= 1 { return String(localized: "Due tomorrow") }
        if days <= 7 { return String(localized: "Due this week") }
        if days <= 31 { return String(localized: "Due this month") }
        let months = max(1, days / 30)
        return String(localized: "In about \(months) months")
    }
}
