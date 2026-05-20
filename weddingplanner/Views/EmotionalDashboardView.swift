import SwiftUI
import UIKit

struct EmotionalDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var animateIn = false
    @State private var showSparkle = false
    @State private var currentAffirmation = 0
    @State private var selectedTab = 0
    @State private var showTaskDetail = false
    @State private var selectedTask: WeddingTask? = nil

    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // Beautiful affirmations that rotate
    private let affirmations = [
        "One step closer to your perfect day",
        "Love is in the details – and you're nailing them",
        "Your love story is unfolding beautifully",
        "Every decision brings you closer to forever",
        "Trust the journey, enjoy the process",
        "You're creating something unforgettable",
        "Breathe. Everything is falling into place",
        "Your wedding is becoming more beautiful each day"
    ]

    // Timer for affirmation rotation
    let affirmationTimer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Serene gradient background with better contrast
            LinearGradient(
                colors: [
                    Color(hex: "F5F2EE"),  // Light warm gray
                    Color(hex: "F9F6F2")   // Off-white with warmth
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    // Hero Section - Countdown & Progress
                    heroSection
                        .padding(.top, 40)

                    // Today's Focus
                    todaysFocusSection

                    // Core Areas Snapshot
                    coreAreasSnapshot

                    // Next Milestone Banner
                    nextMilestoneSection

                    // Emotional Touch
                    emotionalTouchSection
                        .padding(.bottom, 100)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateIn = true
            }
            impactFeedback.prepare()
            selectionFeedback.prepare()
        }
        .onReceive(affirmationTimer) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentAffirmation = (currentAffirmation + 1) % affirmations.count
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task, dataManager: dataManager) {
                // Refresh after task update
                dataManager.objectWillChange.send()
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Days countdown
            VStack(spacing: 12) {
                Text("\(dataManager.daysUntilWedding)")
                    .font(.system(size: 72, weight: .ultraLight, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "D4B5A9"), Color(hex: "C8A89C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateIn)

                Text("days to go")
                    .font(.system(size: 18, weight: .thin, design: .serif))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.1), value: animateIn)
            }

            // Progress indicator
            VStack(spacing: 16) {
                HStack {
                    Text("\(Int(dataManager.taskProgress * 100))% planned")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "7A7A7A"))

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                        Text("\(dataManager.wedding?.completedTasksCount ?? 0) of \(dataManager.wedding?.totalTasksCount ?? 0) tasks")
                            .font(.system(size: 12, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "B89B91"))
                }

                // Elegant progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "F0EDE9"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "E8C4B8"), Color(hex: "D4B5A9")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * dataManager.taskProgress, height: 8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: dataManager.taskProgress)

                        if showSparkle {
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 12, height: 12)
                                .offset(x: geometry.size.width * dataManager.taskProgress - 6)
                                .blur(radius: 2)
                        }
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 4)
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)

            // Rotating affirmation
            Text(LocalizedStringKey(affirmations[currentAffirmation]))
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "9B9B9B"))
                .italic()
                .multilineTextAlignment(.center)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
                .id(currentAffirmation)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: animateIn)
        }
    }

    // MARK: - Today's Focus Section
    private var todaysFocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your focus today")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(spacing: 12) {
                ForEach(getTodaysTasks().prefix(2), id: \.id) { task in
                    TodayFocusCard(
                        task: task,
                        onTap: {
                            selectedTask = task
                            impactFeedback.impactOccurred()
                        },
                        onComplete: {
                            completeTask(task)
                        }
                    )
                }

                if getTodaysTasks().isEmpty {
                    EmptyFocusState()
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateIn)
    }

    // MARK: - Core Areas Snapshot
    private var coreAreasSnapshot: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Time
            CoreAreaCard(
                icon: "clock",
                title: "Time",
                value: String(localized: "\(getUpcomingTasksCount()) tasks"),
                subtitle: "due this week",
                color: Color(hex: "C8D4E8"),
                tabIndex: 1,
                action: {
                    navigateToTab(1)
                }
            )

            // Team
            CoreAreaCard(
                icon: "person.3",
                title: "Team",
                value: String(localized: "\(getBookedVendorsCount()) of \(getTotalVendorsCount())"),
                subtitle: "vendors booked",
                color: Color(hex: "E8D4C8"),
                tabIndex: 2,
                action: {
                    navigateToTab(2)
                }
            )

            // Guests
            CoreAreaCard(
                icon: "person.2",
                title: "Guests",
                value: "\(getConfirmedGuestsCount())",
                subtitle: "confirmed",
                color: Color(hex: "D4C8E8"),
                tabIndex: 3,
                action: {
                    navigateToTab(3)
                }
            )

            // Funds
            CoreAreaCard(
                icon: "creditcard",
                title: "Funds",
                value: formatCurrency(dataManager.spentBudget),
                subtitle: LocalizedStringKey("of \(formatCurrency(dataManager.totalBudget)) spent"),
                color: Color(hex: "C8E8D4"),
                tabIndex: 4,
                action: {
                    navigateToTab(4)
                }
            )
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.5), value: animateIn)
    }

    private func navigateToTab(_ index: Int) {
        impactFeedback.impactOccurred()
        // Find the parent ContentView's selectedTab binding
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let _ = windowScene.windows.first {
            // Post notification to change tab
            NotificationCenter.default.post(name: NSNotification.Name("ChangeTab"), object: nil, userInfo: ["tab": index])
        }
    }

    // MARK: - Next Milestone Section
    private var nextMilestoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next milestone")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "7A7A7A"))

            if let milestone = getNextMilestone() {
                Button(action: {
                    if let task = milestone.task {
                        selectedTask = task
                        impactFeedback.impactOccurred()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(milestone.title)
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text(milestone.timeText)
                                .font(.system(size: 14, weight: .thin))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        Spacer()

                        Image(systemName: milestone.icon)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Color(hex: "D4B5A9"))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FBF9F7"), Color(hex: "F8F5F1")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "D4B5A9").opacity(0.1), radius: 8, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateIn)
    }

    // MARK: - Emotional Touch Section
    private var emotionalTouchSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(hex: "E8C4B8").opacity(0.6))

            VStack(spacing: 12) {
                Text("Remember")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "9B9B9B"))

                Text(LocalizedStringKey(getWeeklyWisdom()))
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "7A7A7A"))
                    .multilineTextAlignment(.center)
                    .italic()
                    .lineSpacing(6)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "FDFBF8").opacity(0.5))
        )
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.7), value: animateIn)
    }

    // MARK: - Helper Methods
    private func getTodaysTasks() -> [WeddingTask] {
        guard let tasks = dataManager.wedding?.tasks else { return [] }
        return tasks
            .filter { task in
                !task.isCompleted && (task.dueDate.map { Calendar.current.isDateInToday($0) } ?? false)
            }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    private func getUpcomingTasksCount() -> Int {
        dataManager.upcomingTasksCount
    }

    private func getBookedVendorsCount() -> Int {
        dataManager.wedding?.vendors?.filter { $0.status == .booked || $0.status == .confirmed }.count ?? 0
    }

    private func getTotalVendorsCount() -> Int {
        dataManager.wedding?.vendors?.count ?? 7
    }

    private func getConfirmedGuestsCount() -> Int {
        dataManager.wedding?.confirmedGuestsCount ?? 0
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func getNextMilestone() -> (title: String, timeText: String, icon: String, task: WeddingTask?)? {
        guard let tasks = dataManager.wedding?.tasks else { return nil }

        let upcoming = tasks
            .filter { !$0.isCompleted && $0.dueDate != nil }
            .sorted { $0.dueDate! < $1.dueDate! }
            .first

        guard let nextTask = upcoming, let dueDate = nextTask.dueDate else { return nil }

        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        let timeText: String
        if daysUntil == 0 {
            timeText = String(localized: "Today")
        } else if daysUntil == 1 {
            timeText = String(localized: "Tomorrow")
        } else {
            timeText = String(localized: "In \(daysUntil) days")
        }

        return (title: nextTask.title, timeText: timeText, icon: nextTask.category.icon, task: nextTask)
    }

    private func completeTask(_ task: WeddingTask) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            task.isCompleted = true
            task.completedDate = Date()
            task.updatedAt = Date()
            dataManager.updateWedding()

            // Celebrate!
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            FeedbackManager.shared.recordTaskCompleted()
            if FeedbackManager.shared.shouldAutoPrompt() {
                NotificationCenter.default.post(name: NSNotification.Name("ShowFeedback"), object: nil)
            }
            showSparkle = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSparkle = false
            }
        }
    }

    private func getWeeklyWisdom() -> String {
        let wisdoms = [
            "Your wedding is not a performance,\nit's a celebration of love",
            "Perfect is not the goal,\njoy is",
            "Every detail doesn't need to be perfect,\njust meaningful to you",
            "This day is about your love story,\nnot anyone else's expectations",
            "Trust your vendors,\nthey want your day to be beautiful too"
        ]
        let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
        return wisdoms[weekOfYear % wisdoms.count]
    }
}

// MARK: - Supporting Components
struct TodayFocusCard: View {
    let task: WeddingTask
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Quick complete button
                Button(action: {
                    onComplete()
                }) {
                    Circle()
                        .stroke(Color(hex: "D4B5A9"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "D4B5A9"))
                                .opacity(task.isCompleted ? 1 : 0)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .strikethrough(task.isCompleted, color: Color(hex: "B8B8B8"))

                    HStack(spacing: 8) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 11))
                        Text(task.category.rawValue)
                            .font(.system(size: 12, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                Spacer()

                if task.priority == .urgent {
                    Text("Urgent")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "F4B5A0"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "F4B5A0").opacity(0.2))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct EmptyFocusState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(Color(hex: "C8D4C8"))

            Text("Nothing urgent today")
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "9B9B9B"))

            Text("Take a breath, enjoy the moment")
                .font(.system(size: 12, weight: .thin))
                .foregroundColor(Color(hex: "B8B8B8"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
}

struct CoreAreaCard: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey
    let color: Color
    let tabIndex: Int
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(color)

                    Spacer()

                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(Color(hex: "C4C4C4"))
                        .rotationEffect(.degrees(isPressed ? 45 : 0))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .lineLimit(1)
                }

                Text(title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "7A7A7A"))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: color.opacity(0.15), radius: 12, x: 0, y: 6)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(isPressed ? 0.15 : 0.08))
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct EmotionalDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionalDashboardView()
            .environmentObject(DataManager())
    }
}