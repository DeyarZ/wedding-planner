import SwiftUI

// MARK: - Generic payoff

/// Every question the flow asks gets something back on the very next screen.
/// The payoff always quotes the user's own answer — that is what makes the
/// questions feel like progress instead of a form.
struct OnboardingPayoffScreen: View {
    let icon: String
    var tint: Color = OnboardingStyle.accent
    /// Already-localised copy: these strings interpolate the user's answers.
    let headline: String
    let message: String
    var footnote: String?
    var cta: LocalizedStringKey = "Continue"
    let onContinue: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                OnboardingIconBadge(systemName: icon, tint: tint, size: 92)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(shown ? 1 : 0.8)
                    .animation(.spring(response: 0.75, dampingFraction: 0.65).delay(0.1), value: shown)

                Spacer().frame(height: 34)

                Text(headline)
                    .font(.system(size: 27, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
                    .onboardingAppear(shown, delay: 0.3)

                Spacer().frame(height: 18)

                Text(message)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 34)
                    .onboardingAppear(shown, delay: 0.45)

                if let footnote {
                    Spacer().frame(height: 22)
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(OnboardingStyle.sage)
                        Text(footnote)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundColor(OnboardingStyle.inkSoft)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.8)))
                    .onboardingAppear(shown, delay: 0.6)
                }

                Spacer()

                OnboardingPrimaryButton(title: cta, action: onContinue)
                    .onboardingAppear(shown, delay: 0.7, offset: 28)

                Spacer().frame(height: 56)
            }
        }
        .onAppear { shown = true }
    }
}

// MARK: - Countdown reveal

/// The single strongest moment in the flow: the user gives a date and instantly
/// gets the number that will drive the rest of their planning.
struct OnboardingCountdownScreen: View {
    @EnvironmentObject var data: OnboardingData
    /// The count-up must not play while the screen is still an offscreen
    /// neighbour in the paged TabView — this is the flow's strongest moment.
    let isCurrent: Bool
    let onContinue: () -> Void

    @State private var shown = false
    @State private var displayedDays = 0
    @State private var ringProgress: CGFloat = 0
    @State private var timer: Timer?

    private var targetDays: Int { data.daysUntilWedding }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(OnboardingStyle.accent.opacity(0.16), lineWidth: 10)
                        .frame(width: 210, height: 210)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [OnboardingStyle.accent, OnboardingStyle.blush],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 210, height: 210)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(displayedDays)")
                            .font(.system(size: 66, weight: .light, design: .serif))
                            .foregroundColor(OnboardingStyle.ink)
                            .monospacedDigit()
                        Text("days")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(OnboardingStyle.inkSoft)
                    }
                }
                .opacity(shown ? 1 : 0)
                .scaleEffect(shown ? 1 : 0.85)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: shown)

                Spacer().frame(height: 40)

                Text(headlineText)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
                    .onboardingAppear(shown, delay: 0.6)

                Spacer().frame(height: 16)

                Text(bodyText)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 34)
                    .onboardingAppear(shown, delay: 0.75)

                Spacer()

                OnboardingPrimaryButton(title: "Keep going", action: onContinue)
                    .onboardingAppear(shown, delay: 0.95, offset: 28)

                Spacer().frame(height: 56)
            }
        }
        .onAppear {
            shown = true
            if isCurrent { startCount() }
        }
        .onChange(of: isCurrent) { _, current in
            if current { startCount() }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var headlineText: String {
        data.hasDate
            ? String(localized: "\(targetDays) days until your big day")
            : String(localized: "We'll plan for about a year out")
    }

    private var bodyText: String {
        data.hasDate
            ? String(localized: "Every deadline in your plan is counted backwards from \(data.formattedDate) — so you always know what needs to happen this week.")
            : String(localized: "No date yet is completely normal. We'll build a flexible twelve-month plan and reschedule everything the moment you set one.")
    }

    /// Counts up to the real number with an ease-out curve instead of snapping.
    private func startCount() {
        guard timer == nil else { return }
        let steps = 45
        let duration = 1.3
        var step = 0
        ringProgress = 0
        withAnimation(.easeOut(duration: duration)) { ringProgress = 1 }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { current in
            step += 1
            let t = Double(step) / Double(steps)
            let eased = 1 - pow(1 - t, 3)
            displayedDays = Int((Double(targetDays) * eased).rounded())
            if step >= steps {
                displayedDays = targetDays
                current.invalidate()
                timer = nil
            }
        }
    }
}
