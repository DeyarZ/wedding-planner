import SwiftUI

// MARK: - Shared question layout

/// One question per screen: badge, headline, answers, nothing else.
private struct QuestionScaffold<Content: View, Footer: View>: View {
    let icon: String
    let kicker: LocalizedStringKey?
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    let shown: Bool
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                OnboardingIconBadge(systemName: icon)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(shown ? 1 : 0.85)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.05), value: shown)

                Spacer().frame(height: 22)

                OnboardingTitle(kicker: kicker, title: title, subtitle: subtitle, titleSize: 27)
                    .onboardingAppear(shown, delay: 0.15)

                Spacer().frame(height: 26)

                ScrollView(showsIndicators: false) {
                    content
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onboardingAppear(shown, delay: 0.28, offset: 26)

                footer

                Spacer().frame(height: 34)
            }
        }
    }
}

// MARK: - 3. Partner names

struct OnboardingNamesScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false
    @FocusState private var focused: Bool

    private var canContinue: Bool {
        !data.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        QuestionScaffold(
            icon: "heart.circle.fill",
            kicker: "First things first",
            title: "WHO'S GETTING MARRIED?",
            subtitle: "We'll use your names across your plan.",
            shown: shown
        ) {
            VStack(spacing: 16) {
                OnboardingTextField(placeholder: "Your name", text: $data.firstName, icon: "person.fill")
                    .focused($focused)
                OnboardingTextField(placeholder: "Your partner's name", text: $data.partnerName, icon: "heart.fill")
                    .focused($focused)
            }
        } footer: {
            OnboardingPrimaryButton(title: "Continue", enabled: canContinue) {
                focused = false
                onContinue()
            }
            .onboardingAppear(shown, delay: 0.45, offset: 26)
        }
        .onAppear { shown = true }
        .onTapGesture { focused = false }
    }
}

// MARK: - 5. Wedding date

struct OnboardingDateScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        QuestionScaffold(
            icon: "calendar.circle.fill",
            kicker: "The big one",
            title: "WHEN'S THE BIG DAY?",
            subtitle: "Your whole plan is built backwards from this date.",
            shown: shown
        ) {
            VStack(spacing: 18) {
                DatePicker("", selection: $data.weddingDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(OnboardingStyle.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
                    )
            }
        } footer: {
            VStack(spacing: 14) {
                OnboardingPrimaryButton(title: "That's the date") {
                    data.hasDate = true
                    onContinue()
                }

                OnboardingTextButton(title: "We haven't set a date yet") {
                    data.hasDate = false
                    onContinue()
                }
            }
            .onboardingAppear(shown, delay: 0.45, offset: 26)
        }
        .onAppear { shown = true }
    }
}

// MARK: - 7. Planning stage

struct OnboardingStageScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        QuestionScaffold(
            icon: "flag.circle.fill",
            kicker: "So we start in the right place",
            title: "WHERE ARE YOU RIGHT NOW?",
            shown: shown
        ) {
            VStack(spacing: 12) {
                ForEach(PlanningStage.allCases) { stage in
                    OnboardingOptionRow(
                        icon: stage.icon,
                        title: stage.title,
                        subtitle: stage.subtitle,
                        isSelected: data.stage == stage
                    ) {
                        data.stage = stage
                        advance()
                    }
                }
            }
        } footer: {
            EmptyView()
        }
        .onAppear { shown = true }
    }

    /// Selection is the answer — a beat of feedback, then move on.
    private func advance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onContinue() }
    }
}

// MARK: - 9. Guest count

struct OnboardingGuestScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        QuestionScaffold(
            icon: "person.3.fill",
            kicker: "Roughly is fine",
            title: "HOW MANY GUESTS?",
            subtitle: "You can change this any time — it only sets the starting point.",
            shown: shown
        ) {
            VStack(spacing: 12) {
                ForEach(GuestBand.allCases) { band in
                    OnboardingOptionRow(
                        icon: nil,
                        title: band.title,
                        subtitle: band.subtitle,
                        isSelected: data.guestBand == band
                    ) {
                        data.guestBand = band
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onContinue() }
                    }
                }
            }
        } footer: {
            EmptyView()
        }
        .onAppear { shown = true }
    }
}

// MARK: - 11. Budget

struct OnboardingBudgetScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false
    @State private var bands: [BudgetBand] = BudgetBand.all

    var body: some View {
        QuestionScaffold(
            icon: "chart.pie.fill",
            kicker: "No judgement, ever",
            title: "WHAT'S YOUR BUDGET?",
            subtitle: "We'll split it across the 12 categories a wedding actually has.",
            shown: shown
        ) {
            VStack(spacing: 12) {
                ForEach(bands) { band in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        data.budget = band.value
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onContinue() }
                    } label: {
                        HStack {
                            // The band label is already formatted in the user's
                            // own currency — never a hardcoded dollar sign.
                            Text(band.label)
                                .font(.system(size: 17, weight: .medium, design: .serif))
                                .foregroundColor(data.budget == band.value ? .white : OnboardingStyle.ink)
                            Spacer()
                            if data.budget == band.value {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(data.budget == band.value ? OnboardingStyle.accent : Color.white)
                                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
                        )
                    }
                }
            }
        } footer: {
            EmptyView()
        }
        .onAppear {
            shown = true
            bands = BudgetBand.all
        }
    }
}

// MARK: - 13. Venue

struct OnboardingVenueScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false
    @FocusState private var focused: Bool

    var body: some View {
        QuestionScaffold(
            icon: "building.2.crop.circle.fill",
            kicker: "Almost there",
            title: "WHERE WILL IT HAPPEN?",
            subtitle: "A venue, a city or just an idea — whatever you have.",
            shown: shown
        ) {
            OnboardingTextField(placeholder: "Venue or place", text: $data.venue, icon: "mappin.and.ellipse")
                .focused($focused)
        } footer: {
            VStack(spacing: 14) {
                OnboardingPrimaryButton(title: "Continue") {
                    focused = false
                    onContinue()
                }
                OnboardingTextButton(title: "We haven't decided yet") {
                    focused = false
                    data.venue = ""
                    onContinue()
                }
            }
            .onboardingAppear(shown, delay: 0.45, offset: 26)
        }
        .onAppear { shown = true }
        .onTapGesture { focused = false }
    }
}

// MARK: - 14. Stressors (multi-select)

struct OnboardingStressorScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        QuestionScaffold(
            icon: "exclamationmark.bubble.fill",
            kicker: "Be honest",
            title: "WHAT WORRIES YOU MOST?",
            subtitle: "Pick everything that applies.",
            shown: shown
        ) {
            VStack(spacing: 12) {
                ForEach(Stressor.allCases) { stressor in
                    OnboardingOptionRow(
                        icon: stressor.icon,
                        title: stressor.title,
                        subtitle: nil,
                        isSelected: data.stressors.contains(stressor)
                    ) {
                        if data.stressors.contains(stressor) {
                            data.stressors.remove(stressor)
                        } else {
                            data.stressors.insert(stressor)
                        }
                    }
                }
            }
        } footer: {
            OnboardingPrimaryButton(title: "Continue", enabled: !data.stressors.isEmpty, action: onContinue)
                .onboardingAppear(shown, delay: 0.45, offset: 26)
        }
        .onAppear { shown = true }
    }
}

// MARK: - 16. Priorities (multi-select, drives the budget split)

struct OnboardingPrioritiesScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    private let options: [(id: String, title: LocalizedStringKey, icon: String)] = [
        ("venue", "The venue", "building.2.fill"),
        ("photography", "Photography", "camera.fill"),
        ("food", "Food & drinks", "fork.knife"),
        ("music", "Music & dancing", "music.note"),
        ("flowers", "Flowers & decor", "leaf.fill"),
        ("attire", "Outfits & beauty", "tshirt.fill"),
        ("guest_experience", "The guest experience", "heart.fill"),
        ("budget", "Staying on budget", "creditcard.fill")
    ]

    var body: some View {
        QuestionScaffold(
            icon: "star.circle.fill",
            kicker: "Where the money should go",
            title: "WHAT MATTERS MOST?",
            subtitle: "Choose two to four. We'll weight your budget towards them.",
            shown: shown
        ) {
            VStack(spacing: 12) {
                ForEach(options, id: \.id) { option in
                    OnboardingOptionRow(
                        icon: option.icon,
                        title: option.title,
                        subtitle: nil,
                        isSelected: data.priorities.contains(option.id)
                    ) {
                        if data.priorities.contains(option.id) {
                            data.priorities.remove(option.id)
                        } else if data.priorities.count < 4 {
                            data.priorities.insert(option.id)
                        }
                    }
                }
            }
        } footer: {
            OnboardingPrimaryButton(title: "Continue", enabled: data.priorities.count >= 2, action: onContinue)
                .onboardingAppear(shown, delay: 0.45, offset: 26)
        }
        .onAppear { shown = true }
    }
}

// MARK: - 17. Who is planning

struct OnboardingPartyScreen: View {
    @EnvironmentObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var shown = false

    var body: some View {
        QuestionScaffold(
            icon: "person.2.circle.fill",
            kicker: "Last question",
            title: "WHO'S PLANNING THIS?",
            shown: shown
        ) {
            VStack(spacing: 12) {
                ForEach(PlanningParty.allCases) { party in
                    OnboardingOptionRow(
                        icon: party.icon,
                        title: party.title,
                        subtitle: nil,
                        isSelected: data.party == party
                    ) {
                        data.party = party
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onContinue() }
                    }
                }
            }
        } footer: {
            EmptyView()
        }
        .onAppear { shown = true }
    }
}
