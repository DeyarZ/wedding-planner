import Foundation

// Feedback / feature-request prompt manager.
// UserDefaults-backed engagement tracking that decides when to surface the
// in-app feedback sheet (sent via the native Mail composer, no backend).
@MainActor
final class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    private let defaults = UserDefaults.standard

    // MARK: - UserDefaults keys
    private enum Keys {
        static let appOpenCount = "fb_appOpenCount"
        static let hasSubmittedFeedback = "fb_hasSubmittedFeedback"
        static let didCompleteFirstTask = "fb_didCompleteFirstTask"
        static let lastPromptDate = "fb_lastPromptDate"
    }

    // ~30 days between automatic prompts.
    private let minSecondsBetweenPrompts: TimeInterval = 30 * 24 * 60 * 60

    // MARK: - Published state
    @Published var isPresented: Bool = false

    private init() {}

    // MARK: - Persisted properties
    var appOpenCount: Int {
        get { defaults.integer(forKey: Keys.appOpenCount) }
        set { defaults.set(newValue, forKey: Keys.appOpenCount) }
    }

    var hasSubmittedFeedback: Bool {
        get { defaults.bool(forKey: Keys.hasSubmittedFeedback) }
        set { defaults.set(newValue, forKey: Keys.hasSubmittedFeedback) }
    }

    var didCompleteFirstTask: Bool {
        get { defaults.bool(forKey: Keys.didCompleteFirstTask) }
        set { defaults.set(newValue, forKey: Keys.didCompleteFirstTask) }
    }

    var lastPromptDate: Date? {
        get { defaults.object(forKey: Keys.lastPromptDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastPromptDate) }
    }

    // MARK: - Engagement tracking
    func registerAppOpen() {
        appOpenCount += 1
    }

    func recordTaskCompleted() {
        didCompleteFirstTask = true
    }

    // MARK: - Prompt eligibility

    /// Returns true at most once per ~30 days when the user is engaged
    /// (completed their first task OR opened the app at least 4 times)
    /// and has not yet submitted feedback.
    func shouldAutoPrompt() -> Bool {
        guard !hasSubmittedFeedback else { return false }

        if let lastPrompt = lastPromptDate,
           Date().timeIntervalSince(lastPrompt) < minSecondsBetweenPrompts {
            return false
        }

        return didCompleteFirstTask || appOpenCount >= 4
    }

    func markPrompted() {
        lastPromptDate = Date()
    }

    func markSubmitted() {
        hasSubmittedFeedback = true
    }

    /// Presents the feedback sheet. Used for both the automatic prompt and
    /// the manual entry point in the header.
    func requestFeedback() {
        isPresented = true
        markPrompted()
    }
}
