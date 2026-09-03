import SwiftUI
import AppTrackingTransparency
import RevenueCat

// MARK: - 23. Hold to commit

/// A commitment device, not a button. Physically holding for a second and a
/// half is a small investment — and it happens immediately before the price.
struct OnboardingCommitScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var shown = false
    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var completed = false
    @State private var timer: Timer?

    private let holdDuration: Double = 1.5

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                Text("ONE PROMISE")
                    .font(.system(size: 27, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .onboardingAppear(shown, delay: 0.05)

                Spacer().frame(height: 16)

                Text(promiseText)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
                    .onboardingAppear(shown, delay: 0.2)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(OnboardingStyle.accent.opacity(0.16), lineWidth: 8)
                        .frame(width: 190, height: 190)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [OnboardingStyle.accent, OnboardingStyle.blush],
                                startPoint: .top, endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 190, height: 190)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .fill(Color.white)
                        .frame(width: 158, height: 158)
                        .shadow(color: Color.black.opacity(isHolding ? 0.16 : 0.08),
                                radius: isHolding ? 18 : 10, x: 0, y: 6)

                    VStack(spacing: 8) {
                        Image(systemName: completed ? "checkmark" : "heart.fill")
                            .font(.system(size: completed ? 32 : 30, weight: .light))
                            .foregroundColor(completed ? OnboardingStyle.sage : OnboardingStyle.blush)
                        Text(completed ? "We're in this together" : "Hold to promise")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundColor(OnboardingStyle.inkSoft)
                            .multilineTextAlignment(.center)
                            // The label lives inside a 158pt circle, so a longer
                            // translation shrinks rather than spilling over the rim.
                            .lineLimit(3)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 20)
                    }
                }
                .scaleEffect(isHolding ? 1.04 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHolding)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in beginHold() }
                        .onEnded { _ in endHold() }
                )
                .onboardingAppear(shown, delay: 0.35, offset: 0)

                Spacer()

                Text("We'll plan this together, one week at a time.")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkFaint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .onboardingAppear(shown, delay: 0.5)

                Spacer().frame(height: 70)
            }
        }
        .onAppear { shown = true }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var promiseText: String {
        String(localized: "Hold the circle to promise \(promiseName) that you'll plan this together — no last-minute panic, no forgotten deadlines.")
    }

    private var promiseName: String {
        let partner = data.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return partner.isEmpty ? String(localized: "each other") : partner
    }

    private func beginHold() {
        guard !isHolding, !completed else { return }
        isHolding = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        let tick = 0.02
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { current in
            progress = min(1, progress + CGFloat(tick / holdDuration))
            if progress >= 1 {
                current.invalidate()
                finish()
            }
        }
    }

    private func endHold() {
        guard !completed else { return }
        isHolding = false
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 0.35)) { progress = 0 }
    }

    private func finish() {
        completed = true
        isHolding = false
        data.didCommit = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { onContinue() }
    }
}

// MARK: - 24. Notification priming

/// The one and only place the app asks iOS for notification permission. The
/// screen is the primer; the system dialog follows immediately.
struct OnboardingNotificationScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 76)

                Text("NEVER MISS A DEADLINE")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .onboardingAppear(shown, delay: 0.05)

                Spacer().frame(height: 14)

                Text(primerText)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
                    .onboardingAppear(shown, delay: 0.2)

                Spacer()

                OnboardingBellMark()
                    .frame(height: 170)
                    .onboardingAppear(shown, delay: 0.3, offset: 0)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(OnboardingStyle.sage)
                    Text("No payment due now")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(OnboardingStyle.inkSoft)
                }
                .onboardingAppear(shown, delay: 0.45)

                Spacer().frame(height: 16)

                OnboardingPrimaryButton(title: "Remind me", action: requestPermissionAndSchedule)
                    .onboardingAppear(shown, delay: 0.55, offset: 28)

                Spacer().frame(height: 60)
            }
            .onboardingScreenScroll()
        }
        .onAppear { shown = true }
    }

    private var primerText: String {
        data.hasDate
            ? String(localized: "We'll nudge you before something is due — and once before any free trial ends. \(data.daysUntilWedding) days is not as long as it sounds.")
            : String(localized: "We'll nudge you before something is due — and once before any free trial ends. Nothing noisy, nothing daily.")
    }

    private func requestPermissionAndSchedule() {
        // Deliberately the nil-able variant: when the current offering has no
        // introductory offer there is no trial to remind anyone about, and
        // scheduling "your free trial ends tomorrow" would contradict the App
        // Store. The fallback-bearing `trialDurationDays` must not be used here.
        let trialDays = SubscriptionManager.shared.trialDurationDaysIfAny
        let advance = onContinue

        NotificationManager.shared.requestPermission { granted in
            if granted {
                if let trialDays {
                    TrialNotificationManager.shared.scheduleSmartTrialNotifications(trialDays: trialDays)
                } else {
                    TrialNotificationManager.shared.scheduleEngagementOnlyNotifications()
                }
            }
            advance()
        }
    }
}

// MARK: - 25. Trial timeline (paywall page A)

/// The Blinkist pattern: show exactly when money moves. Reads the real trial
/// length from the current RevenueCat offering, and renders a no-trial variant
/// when the offering has no introductory period — the trial-vs-no-trial test
/// swaps the offering, never the build.
struct OnboardingTrialTimelineScreen: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let onContinue: () -> Void
    @State private var shown = false

    private var trialDays: Int? { subscriptionManager.trialDurationDaysIfAny }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 74)

                OnboardingIconBadge(systemName: trialDays == nil ? "lock.open.fill" : "gift.fill", size: 84)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(shown ? 1 : 0.85)
                    .animation(.spring(response: 0.75, dampingFraction: 0.7).delay(0.05), value: shown)

                Spacer().frame(height: 24)

                Text(titleText)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .onboardingAppear(shown, delay: 0.15)

                Spacer().frame(height: 30)

                VStack(spacing: 20) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        OnboardingTimelineRow(
                            icon: row.icon,
                            iconColor: row.color,
                            title: row.title,
                            detail: row.detail,
                            isLast: index == rows.count - 1
                        )
                        .onboardingAppear(shown, delay: 0.28 + Double(index) * 0.1, offset: 22)
                    }
                }
                .padding(.horizontal, 34)

                Spacer()

                OnboardingPrimaryButton(title: "Continue", action: onContinue)
                    .onboardingAppear(shown, delay: 0.65, offset: 28)

                Spacer().frame(height: 46)
            }
            .onboardingScreenScroll()
        }
        .onAppear { shown = true }
    }

    private var titleText: String {
        if let days = trialDays {
            return String(localized: "How your \(days)-day free trial works")
        }
        return String(localized: "Unlock your full plan")
    }

    private struct TimelineRowModel {
        let icon: String
        let color: Color
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
    }

    private var rows: [TimelineRowModel] {
        guard let days = trialDays else {
            return [
                TimelineRowModel(icon: "lock.open.fill", color: OnboardingStyle.sage,
                                 title: "Everything, right now",
                                 detail: "Your full checklist, the complete budget tracker, unlimited guests and vendors."),
                TimelineRowModel(icon: "arrow.counterclockwise", color: OnboardingStyle.gold,
                                 title: "Cancel whenever you like",
                                 detail: "One tap in your App Store settings. No email, no phone call."),
                TimelineRowModel(icon: "heart.fill", color: OnboardingStyle.accent,
                                 title: "Yours until the big day",
                                 detail: "And beyond — your plan stays as the record of how it all came together.")
            ]
        }

        // Remind one day before the trial ends, or on the middle day of a
        // longer one — mirrors what TrialNotificationManager actually schedules.
        let reminderDay = max(1, days - 1)

        return [
            TimelineRowModel(icon: "lock.open.fill", color: OnboardingStyle.sage,
                             title: "Today: full access",
                             detail: "Your complete checklist, budget tracker, guest list and vendors unlock immediately."),
            TimelineRowModel(icon: "bell.fill", color: OnboardingStyle.gold,
                             title: LocalizedStringKey("Day \(reminderDay): a reminder"),
                             detail: "We'll tell you before the trial ends, so nothing is a surprise."),
            TimelineRowModel(icon: "checkmark.circle.fill", color: OnboardingStyle.accent,
                             title: LocalizedStringKey("Day \(days): trial ends"),
                             detail: "Only then does anything get charged — and you can cancel before that at any point.")
        ]
    }
}

// MARK: - 26. Value recap (paywall page B)

/// The last screen before the price. Repeats what was built, in the couple's
/// own words, and hosts the ATT primer so tracking consent is asked once, late,
/// and in context.
struct OnboardingValueRecapScreen: View {
    @EnvironmentObject var data: OnboardingData
    /// The ATT prompt must only be raised once this screen is genuinely on
    /// screen — a paged TabView appears its neighbours early, and a system
    /// dialog over the previous screen would burn the one-shot prompt.
    let isCurrent: Bool
    let onContinue: () -> Void

    @State private var shown = false
    @State private var showTrackingPriming = false
    @State private var didSchedulePrimer = false
    /// Whether the ATT primer has been answered. The primer is this app's only
    /// tracking-authorization request point, so leaving the screen before it
    /// resolves loses the prompt for the whole install.
    @State private var didResolvePrimer = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                Text(headlineText)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)
                    .onboardingAppear(shown, delay: 0.05)

                Spacer().frame(height: 10)

                Text(subheadText)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
                    .onboardingAppear(shown, delay: 0.15)

                Spacer().frame(height: 26)

                OnboardingCard {
                    VStack(spacing: 14) {
                        ForEach(Array(recapRows.enumerated()), id: \.offset) { _, row in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(OnboardingStyle.sage)
                                Text(row)
                                    .font(.system(size: 15, weight: .regular, design: .serif))
                                    .foregroundColor(OnboardingStyle.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .onboardingAppear(shown, delay: 0.3, offset: 26)

                Spacer()

                OnboardingPrimaryButton(title: "See my options") {
                    // The primer animates in shortly after the screen does. A
                    // fast tap used to leave before it appeared, silently
                    // skipping ATT forever — so an early tap raises the primer
                    // instead of advancing.
                    if didResolvePrimer {
                        onContinue()
                    } else {
                        withAnimation(.easeIn(duration: 0.2)) { showTrackingPriming = true }
                    }
                }
                .onboardingAppear(shown, delay: 0.55, offset: 28)

                Spacer().frame(height: 50)
            }
            .onboardingScreenScroll()
        }
        .overlay {
            if showTrackingPriming {
                TrackingPrimingView(onContinue: {
                    didResolvePrimer = true
                    withAnimation(.easeOut(duration: 0.25)) { showTrackingPriming = false }
                    requestTrackingAuthorization()
                })
                .transition(.opacity)
            }
        }
        .onAppear {
            shown = true
            if isCurrent { scheduleTrackingPrimer() }
        }
        .onChange(of: isCurrent) { _, current in
            if current { scheduleTrackingPrimer() }
        }
    }

    private var headlineText: String {
        String(localized: "Everything for \(data.coupleNames)")
    }

    private var subheadText: String {
        data.hasDate
            ? String(localized: "Your plan for \(data.formattedDate) is built and waiting.")
            : String(localized: "Your plan is built and waiting for a date.")
    }

    private var recapRows: [String] {
        var rows = [
            String(localized: "\(data.taskCount) tasks, dated and in order"),
            String(localized: "\(data.formattedBudget) tracked across 12 categories"),
            String(localized: "Guest list, RSVPs and plus-ones for \(data.guestCount)"),
            String(localized: "Vendors, quotes, contracts and payments in one place")
        ]
        if let stressor = data.primaryStressor {
            rows.append(stressorLine(stressor))
        }
        return rows
    }

    private func stressorLine(_ stressor: Stressor) -> String {
        switch stressor {
        case .budget:    return String(localized: "Budget alerts before you overspend")
        case .guestList: return String(localized: "One guest list that never goes out of sync")
        case .vendors:   return String(localized: "Every vendor conversation documented")
        case .timeline:  return String(localized: "Reminders before a deadline, not after")
        case .family:    return String(localized: "Seating and dietary notes, decided once")
        case .time:      return String(localized: "Only this week's tasks, never the whole list")
        }
    }

    private func scheduleTrackingPrimer() {
        guard !didSchedulePrimer else { return }
        didSchedulePrimer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) { showTrackingPriming = true }
        }
    }

    private func requestTrackingAuthorization() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                Task { @MainActor in
                    Purchases.shared.attribution.collectDeviceIdentifiers()
                }
            }
        }
    }
}
