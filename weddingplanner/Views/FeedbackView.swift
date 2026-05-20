import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    enum FeedbackCategory: String, CaseIterable, Identifiable {
        case feature = "Feature Request"
        case bug = "Bug"
        case other = "Other"

        var id: String { rawValue }
    }

    @State private var category: FeedbackCategory = .feature
    @State private var message: String = ""
    @State private var showMailComposer = false
    @State private var showCannotSendAlert = false

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSendDisabled: Bool {
        trimmedMessage.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(FeedbackCategory.allCases) { category in
                            Text(LocalizedStringKey(category.rawValue)).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("What's on your mind?")
                }

                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 160)
                } header: {
                    Text("Your message")
                } footer: {
                    Text("Tell us what you'd love to see, or what went wrong. We read every message.")
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        send()
                    }
                    .disabled(isSendDisabled)
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    recipient: Config.supportEmail,
                    subject: subjectLine,
                    body: composedBody
                ) { result in
                    showMailComposer = false
                    if case .success(let mailResult) = result, mailResult == .sent {
                        FeedbackManager.shared.markSubmitted()
                        dismiss()
                    } else if case .failure = result {
                        // Composer failed to send — leave the sheet open so
                        // the user can retry or cancel.
                    }
                }
            }
            .alert("Email Not Available", isPresented: $showCannotSendAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't open an email composer. Please email us directly at \(Config.supportEmail).")
            }
        }
    }

    // MARK: - Send handling

    private func send() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
            return
        }

        // Fallback: try a mailto: URL.
        if let url = mailtoURL() {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    // We can't observe send completion via mailto:, but the
                    // user reached their mail client — treat as submitted.
                    FeedbackManager.shared.markSubmitted()
                    dismiss()
                } else {
                    showCannotSendAlert = true
                }
            }
        } else {
            showCannotSendAlert = true
        }
    }

    private var subjectLine: String {
        "Wedding Planner Feedback — \(category.rawValue)"
    }

    private var composedBody: String {
        """
        \(trimmedMessage)


        ───────────────
        \(contextBlock)
        """
    }

    private var contextBlock: String {
        let info = Bundle.main.infoDictionary
        let appVersion = (info?["CFBundleShortVersionString"] as? String) ?? "Unknown"
        let build = (info?["CFBundleVersion"] as? String) ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let locale = Locale.current.identifier
        let isSubscribed = SubscriptionManager.shared.isSubscribed

        return """
        App Version: \(appVersion) (\(build))
        iOS: \(iosVersion)
        Device: \(deviceModel)
        Locale: \(locale)
        Subscribed: \(isSubscribed ? "Yes" : "No")
        """
    }

    private func mailtoURL() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Config.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subjectLine),
            URLQueryItem(name: "body", value: composedBody)
        ]
        // URLComponents encodes spaces as "+" in query items for mailto;
        // normalize to %20 so mail clients parse the body correctly.
        let encodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%20")
        components.percentEncodedQuery = encodedQuery
        return components.url
    }
}

// MARK: - MFMailComposeViewController wrapper

private struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    let onFinish: (Result<MFMailComposeResult, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (Result<MFMailComposeResult, Error>) -> Void

        init(onFinish: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            if let error = error {
                onFinish(.failure(error))
            } else {
                onFinish(.success(result))
            }
        }
    }
}
