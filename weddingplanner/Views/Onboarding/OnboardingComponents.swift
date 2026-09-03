import SwiftUI

// MARK: - Design tokens
//
// The onboarding flow keeps the app's existing language: a warm cream gradient,
// serif type, soft white cards on generous whitespace, and the dusty-rose accent
// used across the dashboard.

enum OnboardingStyle {
    static let backgroundTop = Color(hex: "F8F4F0")
    static let backgroundBottom = Color(hex: "F5EFE7")
    static let ink = Color(hex: "2C2C2C")
    static let inkSoft = Color(hex: "6B6B6B")
    static let inkFaint = Color(hex: "9B9B9B")
    static let accent = Color(hex: "D4B5A9")
    static let blush = Color(hex: "FFB6C1")
    static let gold = Color(hex: "FFD700")
    static let sage = Color(hex: "C8D4C8")
    static let hairline = Color(hex: "E8E8E8")
}

// MARK: - Background

struct OnboardingBackground: View {
    var body: some View {
        LinearGradient(
            colors: [OnboardingStyle.backgroundTop, OnboardingStyle.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)
    }
}

// MARK: - Progress

/// A hairline progress bar. Deliberately no "step 4 of 26" label — the number
/// of screens left is exactly the thing that makes people quit.
struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OnboardingStyle.accent.opacity(0.18))
                Capsule()
                    .fill(OnboardingStyle.accent)
                    .frame(width: max(6, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 28)
    }
}

// MARK: - Entry animation

/// Standard entry: invisible + 20pt low, easing up, staggered by `delay`.
struct OnboardingAppear: ViewModifier {
    let shown: Bool
    var delay: Double = 0
    var offset: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : offset)
            .animation(.easeOut(duration: 0.7).delay(delay), value: shown)
    }
}

extension View {
    func onboardingAppear(_ shown: Bool, delay: Double = 0, offset: CGFloat = 20) -> some View {
        modifier(OnboardingAppear(shown: shown, delay: delay, offset: offset))
    }
}

// MARK: - Long-translation safety

/// Keeps a fixed-height screen usable when a translation runs long.
///
/// The screens in this flow are laid out with hard spacers and no scroll view,
/// which is right in English and breaks in German, Hungarian or Polish: two extra
/// lines in a headline plus three cards that each gain a line push the primary
/// button past the bottom of an iPhone SE, where it cannot be tapped. Wrapping the
/// stack in a scroll view that is never shorter than the screen leaves the English
/// layout untouched — the flexible spacers get exactly the same slack — and only
/// starts scrolling once the content genuinely does not fit.
struct OnboardingScreenScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                content
                    .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

extension View {
    /// Wraps a whole screen body so a long translation scrolls instead of
    /// pushing the call to action off-screen. See `OnboardingScreenScroll`.
    func onboardingScreenScroll() -> some View {
        OnboardingScreenScroll { self }
    }
}

// MARK: - Header

struct OnboardingIconBadge: View {
    let systemName: String
    var tint: Color = OnboardingStyle.accent
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)

            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .light))
                .foregroundColor(tint)
        }
    }
}

/// Light intro line above a heavy, uppercase headline — the pattern the app
/// already uses on its setup screens.
struct OnboardingTitle: View {
    let kicker: LocalizedStringKey?
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var titleSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 10) {
            if let kicker {
                Text(kicker)
                    .font(.system(size: 21, weight: .light, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(title)
                .font(.system(size: titleSize, weight: .bold, design: .serif))
                .foregroundColor(OnboardingStyle.ink)
                .lineSpacing(2)
                // A translated headline routinely needs a third line; let it
                // take the height instead of being squeezed into two.
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30)
    }
}

// MARK: - Buttons

struct OnboardingPrimaryButton: View {
    let title: LocalizedStringKey
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(enabled ? OnboardingStyle.ink : OnboardingStyle.inkFaint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                // Keeps a long translated label off the capsule's rounded ends.
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    Capsule()
                        .fill(enabled ? Color.white : Color(hex: "F0F0F0"))
                        .shadow(color: Color.black.opacity(enabled ? 0.1 : 0.04), radius: 8, x: 0, y: 4)
                )
        }
        .disabled(!enabled)
        .padding(.horizontal, 20)
    }
}

struct OnboardingTextButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(OnboardingStyle.inkFaint)
                .underline()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Option rows

/// A single answer. Question screens advance the moment one is tapped — the
/// extra Continue button on a one-choice question is pure drop-off.
struct OnboardingOptionRow: View {
    let icon: String?
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 16) {
                if let icon {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.25) : OnboardingStyle.accent.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(isSelected ? .white : OnboardingStyle.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Answer labels are the copy most likely to double in length;
                    // fixedSize makes the row grow rather than truncate.
                    Text(title)
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .foregroundColor(isSelected ? .white : OnboardingStyle.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .foregroundColor(isSelected ? Color.white.opacity(0.9) : OnboardingStyle.inkSoft)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? OnboardingStyle.accent : Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0.14 : 0.07),
                            radius: isSelected ? 12 : 8, x: 0, y: 4)
            )
            .scaleEffect(isSelected ? 1.015 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

/// White card used by the payoff and preview screens.
struct OnboardingCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
            )
    }
}

// MARK: - Text field

struct OnboardingTextField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var icon: String?

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(OnboardingStyle.accent)
            }
            TextField(placeholder, text: $text)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "1A1A1A"))
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(OnboardingStyle.hairline, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Reusable animations

/// Beating heart used on the opening screen.
struct OnboardingHeartMark: View {
    @State private var beat: CGFloat = 0.9
    @State private var glow: Double = 0.25
    @State private var halo: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [OnboardingStyle.blush.opacity(glow), Color.clear],
                        center: .center, startRadius: 20, endRadius: 85
                    )
                )
                .frame(width: 170, height: 170)
                .blur(radius: 18)
                .scaleEffect(halo)

            Image(systemName: "heart.fill")
                .font(.system(size: 78, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [OnboardingStyle.blush, Color(hex: "FFC0CB"), Color(hex: "DDA0DD")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(beat)
                .shadow(color: OnboardingStyle.blush.opacity(0.45), radius: 15, x: 0, y: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                beat = 1.08
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                halo = 1.25
                glow = 0.55
            }
        }
    }
}

/// Ringing bell used by the notification primer.
struct OnboardingBellMark: View {
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    @State private var showDot = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [OnboardingStyle.gold.opacity(0.28), Color.clear],
                        center: .center, startRadius: 28, endRadius: 82
                    )
                )
                .frame(width: 165, height: 165)
                .blur(radius: 8)
                .scaleEffect(pulse)

            Image(systemName: "bell.fill")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [OnboardingStyle.gold, Color(hex: "FFA500")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(rotation))
                .shadow(color: OnboardingStyle.gold.opacity(0.4), radius: 12, x: 0, y: 6)

            if showDot {
                Circle()
                    .fill(Color(hex: "FF4444"))
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: 24, y: -24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) { showDot = true }
            withAnimation(.easeInOut(duration: 0.16).repeatForever(autoreverses: true).delay(0.8)) {
                rotation = 14
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
                pulse = 1.18
            }
        }
    }
}

/// One row of the trial timeline (also reused by the value recap).
struct OnboardingTimelineRow: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(OnboardingStyle.hairline)
                        .frame(width: 2, height: 30)
                        .padding(.top, 6)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(OnboardingStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(OnboardingStyle.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                if !isLast { Spacer().frame(height: 18) }
            }

            Spacer(minLength: 0)
        }
    }
}
