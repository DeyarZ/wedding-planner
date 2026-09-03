import SwiftUI

// MARK: - 1. Warm open

/// Emotional hook. No question, no form — the first screen only has to make the
/// promise: this will not be stressful.
struct OnboardingWelcomeScreen: View {
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                OnboardingHeartMark()
                    .frame(height: 170)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(shown ? 1 : 0.85)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15), value: shown)

                Spacer().frame(height: 44)

                Text("YOUR DREAM WEDDING,\nSTRESS-FREE")
                    .font(.system(size: 29, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
                    .onboardingAppear(shown, delay: 0.35)

                Spacer().frame(height: 20)

                Text("Answer a few questions and we'll build your complete wedding plan — checklist, budget and guest list, all in one place.")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 36)
                    .onboardingAppear(shown, delay: 0.5)

                Spacer()

                OnboardingPrimaryButton(title: "Let's begin", action: onContinue)
                    .onboardingAppear(shown, delay: 0.7, offset: 30)

                Spacer().frame(height: 60)
            }
        }
        .onAppear { shown = true }
    }
}

// MARK: - 2. Social proof

/// Authority before the first question. No invented review counts or star
/// averages — only claims the product can stand behind.
struct OnboardingSocialProofScreen: View {
    let onContinue: () -> Void
    @State private var shown = false
    @State private var starsShown = 0

    /// Capability claims the product actually delivers — deliberately not
    /// attributed quotes. We do not put words in couples' mouths, and invented
    /// review counts are both dishonest and an App Review risk.
    private let proofPoints: [(icon: String, title: LocalizedStringKey, detail: LocalizedStringKey)] = [
        ("checkmark.seal.fill", "One plan, not six notes apps",
         "Checklist, budget, guests and vendors in a single place."),
        ("chart.pie.fill", "Every cost accounted for",
         "Twelve budget categories, split for you and tracked to the last payment."),
        ("bell.badge.fill", "Nothing slips through",
         "Deadlines are dated backwards from your wedding day and remind you in time.")
    ]

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 70)

                // Laurel wreath framing the promise
                HStack(spacing: 10) {
                    Image(systemName: "laurel.leading")
                        .font(.system(size: 46, weight: .light))
                        .foregroundColor(OnboardingStyle.accent)

                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(OnboardingStyle.gold)
                                    .scaleEffect(index < starsShown ? 1 : 0.3)
                                    .opacity(index < starsShown ? 1 : 0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: starsShown)
                            }
                        }
                        Text("Loved by couples")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundColor(OnboardingStyle.inkSoft)
                    }

                    Image(systemName: "laurel.trailing")
                        .font(.system(size: 46, weight: .light))
                        .foregroundColor(OnboardingStyle.accent)
                }
                .onboardingAppear(shown, delay: 0.1)

                Spacer().frame(height: 34)

                Text("YOU'RE IN\nGOOD COMPANY")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .onboardingAppear(shown, delay: 0.25)

                Spacer().frame(height: 28)

                VStack(spacing: 14) {
                    ForEach(Array(proofPoints.enumerated()), id: \.offset) { index, item in
                        OnboardingCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(OnboardingStyle.accent.opacity(0.14))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: item.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(OnboardingStyle.accent)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 16, weight: .medium, design: .serif))
                                        .foregroundColor(OnboardingStyle.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(item.detail)
                                        .font(.system(size: 13, weight: .regular, design: .serif))
                                        .foregroundColor(OnboardingStyle.inkSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                        }
                        .onboardingAppear(shown, delay: 0.35 + Double(index) * 0.12)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Start my plan", action: onContinue)
                    .onboardingAppear(shown, delay: 0.8, offset: 30)

                Spacer().frame(height: 50)
            }
            .onboardingScreenScroll()
        }
        .onAppear {
            shown = true
            for index in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(index) * 0.09) {
                    starsShown = index + 1
                }
            }
        }
    }
}
