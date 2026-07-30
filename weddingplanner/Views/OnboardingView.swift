import SwiftUI
import Singular
import FacebookCore

/// The first-run flow.
///
/// Twenty-six screens, in three movements: a warm open, a personalisation block
/// where every question is answered with a payoff that quotes the user back to
/// themselves, and a value/commitment run-up that ends in the paywall. The
/// screens themselves live in `Views/Onboarding/`; this type only owns the
/// order, the progress bar and the funnel event.
struct OnboardingView: View {
    @State private var step: OnboardingStep = .welcome
    @StateObject private var data = OnboardingData()

    var onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    static var screenCount: Int { OnboardingStep.allCases.count }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $step) {
                ForEach(OnboardingStep.allCases, id: \.self) { screen in
                    view(for: screen)
                        .tag(screen)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.all)

            if step.showsProgress {
                OnboardingProgressBar(progress: step.progress)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .environmentObject(data)
        .onAppear { track(.welcome) }
        .onChange(of: step) { _, newStep in track(newStep) }
    }

    // MARK: - Screens

    @ViewBuilder
    private func view(for screen: OnboardingStep) -> some View {
        switch screen {

        // Warm open
        case .welcome:
            OnboardingWelcomeScreen(onContinue: { advance(from: .welcome) })
        case .socialProof:
            OnboardingSocialProofScreen(onContinue: { advance(from: .socialProof) })

        // Personalisation
        case .partnerNames:
            OnboardingNamesScreen(onContinue: { advance(from: .partnerNames) })
        case .namesPayoff:
            OnboardingPayoffScreen(
                icon: "hands.sparkles.fill",
                headline: String(localized: "Lovely to meet you, \(data.coupleNames)"),
                message: String(localized: "From here on, this is your plan — we'll use your names on your checklist, your budget and your guest list."),
                cta: "Continue",
                onContinue: { advance(from: .namesPayoff) }
            )
        case .weddingDate:
            OnboardingDateScreen(onContinue: { advance(from: .weddingDate) })
        case .datePayoff:
            OnboardingCountdownScreen(isCurrent: step == .datePayoff, onContinue: { advance(from: .datePayoff) })
        case .planningStage:
            OnboardingStageScreen(onContinue: { advance(from: .planningStage) })
        case .stagePayoff:
            OnboardingPayoffScreen(
                icon: "checklist",
                headline: String(localized: "\(data.taskCount) things still need doing"),
                message: String(localized: "That's normal at your stage — and every single one of them is already on your list, in the right order, with a date."),
                footnote: String(localized: "You'll never have to remember what's next"),
                cta: "Good to know",
                onContinue: { advance(from: .stagePayoff) }
            )
        case .guestCount:
            OnboardingGuestScreen(onContinue: { advance(from: .guestCount) })
        case .guestPayoff:
            OnboardingPayoffScreen(
                icon: "person.3.sequence.fill",
                headline: String(localized: "Room for \(data.guestCount) guests"),
                message: String(localized: "Invitations, RSVPs, plus-ones, dietary notes and seating all hang off this one number — change it any time and everything follows."),
                cta: "Continue",
                onContinue: { advance(from: .guestPayoff) }
            )
        case .budgetRange:
            OnboardingBudgetScreen(onContinue: { advance(from: .budgetRange) })
        case .budgetPayoff:
            OnboardingPayoffScreen(
                icon: "chart.pie.fill",
                headline: String(localized: "\(data.formattedBudget), fully accounted for"),
                message: String(localized: "We'll split it across the twelve categories a wedding really has, then track every quote and payment against it — so you always know what's left."),
                footnote: String(localized: "Weighted towards what matters most to you"),
                cta: "Continue",
                onContinue: { advance(from: .budgetPayoff) }
            )
        case .venue:
            OnboardingVenueScreen(onContinue: { advance(from: .venue) })
        case .stressors:
            OnboardingStressorScreen(onContinue: { advance(from: .stressors) })
        case .stressorPayoff:
            OnboardingPayoffScreen(
                icon: "heart.text.square.fill",
                headline: String(localized: "We've got that part"),
                message: stressorMessage,
                cta: "Continue",
                onContinue: { advance(from: .stressorPayoff) }
            )
        case .priorities:
            OnboardingPrioritiesScreen(onContinue: { advance(from: .priorities) })
        case .planningParty:
            OnboardingPartyScreen(onContinue: { advance(from: .planningParty) })

        // Value preview
        case .buildingPlan:
            OnboardingBuildingPlanScreen(isCurrent: step == .buildingPlan, onContinue: { advance(from: .buildingPlan) })
        case .planReveal:
            OnboardingPlanRevealScreen(onContinue: { advance(from: .planReveal) })
        case .previewChecklist:
            OnboardingFeaturePreviewScreen(kind: .checklist, onContinue: { advance(from: .previewChecklist) })
        case .previewBudget:
            OnboardingFeaturePreviewScreen(kind: .budget, onContinue: { advance(from: .previewBudget) })
        case .previewGuests:
            OnboardingFeaturePreviewScreen(kind: .guests, onContinue: { advance(from: .previewGuests) })

        // Commitment → permission → pre-paywall
        case .commit:
            OnboardingCommitScreen(onContinue: { advance(from: .commit) })
        case .notifications:
            OnboardingNotificationScreen(onContinue: { advance(from: .notifications) })
        case .trialTimeline:
            OnboardingTrialTimelineScreen(onContinue: { advance(from: .trialTimeline) })
        case .valueRecap:
            OnboardingValueRecapScreen(isCurrent: step == .valueRecap, onContinue: finish)
        }
    }

    private var stressorMessage: String {
        data.primaryStressor?.reassurance
            ?? String(localized: "Whatever is worrying you, it is already a task, a category or a reminder in your plan.")
    }

    // MARK: - Navigation

    private func advance(from screen: OnboardingStep) {
        // Guard against a stale callback from a neighbouring page in the
        // TabView firing after the user already moved on.
        guard step == screen, let next = screen.next else { return }
        withAnimation(.easeInOut(duration: 0.3)) { step = next }
    }

    private func finish() {
        Singular.event(EVENT_SNG_TUTORIAL_COMPLETE)
        AppEvents.shared.logEvent(.completedTutorial)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete?()
    }

    private func track(_ screen: OnboardingStep) {
        Analytics.onboardingStep(screen.rawValue, screen.slug)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager())
        .environmentObject(SubscriptionManager.shared)
}
