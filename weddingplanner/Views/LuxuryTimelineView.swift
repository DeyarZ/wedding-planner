import SwiftUI
import SwiftData

struct LuxuryTimelineView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhase: WeddingPhase? = nil
    @State private var showingCalendar = false
    @State private var showingDaySchedule = false
    @State private var showingAddTask = false
    @State private var editingTask: WeddingTask? = nil
    @State private var currentMicroCopy = 0
    @State private var animateIn = false
    @State private var sparkleAnimation = false

    // Micro-copy messages that rotate
    private let microCopyMessages = [
        "Every great love deserves a great plan",
        "You're further ahead than you think",
        "One task at a time, love",
        "Your perfect day is coming together",
        "Trust the journey, enjoy the process",
        "Small steps, big dreams"
    ]

    // Timer for micro-copy rotation
    let microCopyTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                colors: [
                    Color(hex: "FDFBF7"),  // Warm white
                    Color(hex: "FAF8F3")   // Soft beige
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header with countdown
                countdownHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .background(
                        Color(hex: "FDFBF7")
                            .shadow(color: Color.black.opacity(0.02), radius: 10, y: 5)
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : -20)
                    .animation(.easeOut(duration: 0.8), value: animateIn)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Planning Timeline (Phases)
                        planningTimeline
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)

                        // Dynamic Task List
                        taskSection
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: animateIn)

                        // Quick Actions
                        quickActions
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: animateIn)
                    }
                    .padding(.bottom, 100)
                }
            }

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addTaskButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingDaySchedule) {
            WeddingDayScheduleView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(dataManager: dataManager)
        }
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task, dataManager: dataManager)
        }
        .sheet(item: $selectedPhase) { phase in
            PhaseDetailView(phase: phase, dataManager: dataManager)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            checkMilestones()
        }
        .onReceive(microCopyTimer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentMicroCopy = (currentMicroCopy + 1) % microCopyMessages.count
            }
        }
    }

    // MARK: - Countdown Header
    private var countdownHeader: some View {
        VStack(spacing: 16) {
            // Days countdown with sparkle
            ZStack {
                if sparkleAnimation {
                    // Sparkle effect for milestones
                    ForEach(0..<8) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "E8C4B8").opacity(0.6))
                            .offset(
                                x: CGFloat.random(in: -40...40),
                                y: CGFloat.random(in: -30...30)
                            )
                            .scaleEffect(sparkleAnimation ? 0 : 1)
                            .opacity(sparkleAnimation ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.1),
                                value: sparkleAnimation
                            )
                    }
                }

                VStack(spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(dataManager.daysUntilWedding)")
                            .font(.system(size: 56, weight: .ultraLight, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        VStack(alignment: .leading, spacing: 0) {
                            Text("days")
                                .font(.system(size: 16, weight: .thin, design: .serif))
                                .foregroundColor(Color(hex: "7A7A7A"))
                            Text("to go")
                                .font(.system(size: 14, weight: .thin, design: .serif))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }
                        .offset(y: 16)
                    }
                }
            }

            // Rotating micro-copy
            Text(microCopyMessages[currentMicroCopy])
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "B89B91"), Color(hex: "D4B5A9")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .italic()
                .multilineTextAlignment(.center)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .id(currentMicroCopy)
        }
    }

    // MARK: - Planning Timeline
    private var planningTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Planning Journey")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Text("\(completedPhasesCount)/\(weddingPhases.count) phases")
                    .font(.system(size: 12, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(weddingPhases) { phase in
                        PhaseCard(
                            phase: phase,
                            progress: phaseProgress(phase),
                            isActive: isPhaseActive(phase),
                            onTap: { selectedPhase = phase }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Task Section
    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                if let overdueTasks = overdueTasksCount, overdueTasks > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "F4B5A0"))
                            .frame(width: 6, height: 6)
                        Text("\(overdueTasks) need attention")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "C89B8F"))
                    }
                }
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                // Smart suggestions if needed
                if let suggestion = getSmartSuggestion() {
                    SmartSuggestionCard(suggestion: suggestion)
                        .padding(.horizontal, 24)
                }

                // Task list
                ForEach(upcomingTasks) { task in
                    TaskCard(
                        task: task,
                        onToggle: { toggleTask(task) },
                        onEdit: { editingTask = task },
                        onReschedule: { rescheduleTask(task) }
                    )
                    .padding(.horizontal, 24)
                }

                if upcomingTasks.isEmpty {
                    LuxuryEmptyTaskState()
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(spacing: 16) {
            TimelineQuickActionButton(
                icon: "calendar.day.timeline.left",
                title: "Wedding Day Schedule",
                subtitle: "Plan your perfect day timeline",
                color: Color(hex: "E8C4B8"),
                action: { showingDaySchedule = true }
            )

            TimelineQuickActionButton(
                icon: "calendar",
                title: "Calendar View",
                subtitle: "See all events at a glance",
                color: Color(hex: "C8D4E8"),
                action: { showingCalendar = true }
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Floating Add Button
    private var addTaskButton: some View {
        Button(action: {
            if dataManager.canAddTask() {
                showingAddTask = true
            } else {
                dataManager.showPaywallIfNeeded(for: "task")
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: "B89B91").opacity(0.3), radius: 12, y: 6)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Helper Methods
    private var upcomingTasks: [WeddingTask] {
        guard let tasks = dataManager.wedding?.tasks else { return [] }

        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return tasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let dueDate = task.dueDate else { return true }
                return dueDate <= weekFromNow
            }
            .sorted { task1, task2 in
                // Sort by urgency: overdue first, then by date
                if task1.isOverdue != task2.isOverdue {
                    return task1.isOverdue
                }

                guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                    return task1.priority.sortOrder < task2.priority.sortOrder
                }

                return date1 < date2
            }
            .prefix(5)
            .map { $0 }
    }

    private var overdueTasksCount: Int? {
        guard let tasks = dataManager.wedding?.tasks else { return nil }
        let count = tasks.filter { $0.isOverdue && !$0.isCompleted }.count
        return count > 0 ? count : nil
    }

    private func getSmartSuggestion() -> String? {
        // Check for overdue vendor bookings
        let daysLeft = dataManager.daysUntilWedding

        if daysLeft < 180 && daysLeft > 120 {
            if dataManager.wedding?.vendors?.filter({ $0.category == .photography && $0.isBooked }).isEmpty ?? true {
                return "📷 Most couples book their photographer 6-8 months out. Ready to start looking?"
            }
        }

        if daysLeft < 90 && daysLeft > 60 {
            if dataManager.wedding?.guests?.filter({ $0.invitationSent }).isEmpty ?? true {
                return "✉️ Time to send those invitations! Most go out 2-3 months before."
            }
        }

        if overdueTasksCount ?? 0 > 3 {
            return "💝 You have a few tasks that need attention. Take them one at a time - you've got this!"
        }

        return nil
    }

    private func checkMilestones() {
        let days = dataManager.daysUntilWedding

        // Trigger sparkle animation for milestones
        if days == 100 || days == 60 || days == 30 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sparkleAnimation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                sparkleAnimation = false
            }
        }
    }

    private func toggleTask(_ task: WeddingTask) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            task.isCompleted.toggle()
            task.completedDate = task.isCompleted ? Date() : nil
            task.updatedAt = Date()
            dataManager.updateWedding()
        }

        if task.isCompleted {
            // Trigger celebration animation
            sparkleAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                sparkleAnimation = false
            }
        }
    }

    private func rescheduleTask(_ task: WeddingTask) {
        // Implementation for rescheduling
        editingTask = task
    }

    // Phase helpers
    private var weddingPhases: [WeddingPhase] {
        WeddingPhase.allPhases(for: dataManager.wedding?.date ?? Date())
    }

    private var completedPhasesCount: Int {
        weddingPhases.filter { phaseProgress($0) >= 1.0 }.count
    }

    private func phaseProgress(_ phase: WeddingPhase) -> Double {
        guard let tasks = dataManager.wedding?.tasks else { return 0 }

        let phaseTasks = tasks.filter { task in
            phase.taskCategories.contains(task.category)
        }

        guard !phaseTasks.isEmpty else { return 0 }

        let completed = phaseTasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(phaseTasks.count)
    }

    private func isPhaseActive(_ phase: WeddingPhase) -> Bool {
        let today = Date()
        return today >= phase.startDate && today <= phase.endDate
    }
}

// MARK: - Supporting Views

struct PhaseCard: View {
    let phase: WeddingPhase
    let progress: Double
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and title
                HStack(spacing: 12) {
                    Image(systemName: phase.icon)
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(isActive ? Color(hex: "B89B91") : Color(hex: "9B9B9B"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.title)
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text(phase.timeframe)
                            .font(.system(size: 11, weight: .thin))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }

                // Progress indicator
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "F5F2ED"))
                            .frame(height: 3)
                            .cornerRadius(1.5)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(height: 3)

                // Progress text
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(hex: "B89B91"))
            }
            .padding(16)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.white : Color(hex: "FDFBF7"))
                    .shadow(
                        color: isActive ? Color(hex: "B89B91").opacity(0.1) : Color.black.opacity(0.04),
                        radius: isActive ? 12 : 8,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color(hex: "B89B91").opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskCard: View {
    let task: WeddingTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onReschedule: () -> Void

    @State private var isPressed = false
    @State private var offset: CGSize = .zero
    @State private var showingActions = false

    private var taskColor: Color {
        if task.isOverdue && !task.isCompleted {
            return Color(hex: "F4B5A0")
        } else if task.priority == .urgent {
            return Color(hex: "E8C4B8")
        } else {
            return Color(hex: "C8D4E8")
        }
    }

    private var deadlineText: String {
        guard let dueDate = task.dueDate else { return "No deadline" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        if task.isOverdue {
            return "Overdue"
        } else {
            return formatter.localizedString(for: dueDate, relativeTo: Date())
        }
    }

    var body: some View {
        ZStack {
            // Background actions
            HStack {
                Spacer()

                Button(action: onReschedule) {
                    VStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 20, weight: .light))
                        Text("Reschedule")
                            .font(.system(size: 10, weight: .regular))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(Color(hex: "C8D4E8"))
                }
            }
            .cornerRadius(12)

            // Main task card
            HStack(spacing: 16) {
                // Completion button
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .stroke(taskColor, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if task.isCompleted {
                            Circle()
                                .fill(taskColor)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Task content
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 15, weight: task.isCompleted ? .light : .regular, design: .serif))
                        .foregroundColor(task.isCompleted ? Color(hex: "B8B8B8") : Color(hex: "2C2C2C"))
                        .strikethrough(task.isCompleted, color: Color(hex: "B8B8B8"))

                    HStack(spacing: 12) {
                        // Category tag
                        Label(task.category.rawValue, systemImage: task.category.icon)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))

                        // Deadline
                        if let _ = task.dueDate {
                            Label(deadlineText, systemImage: "clock")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(task.isOverdue ? Color(hex: "F4B5A0") : Color(hex: "9B9B9B"))
                        }
                    }

                    if let notes = task.notes, !notes.isEmpty, !task.isCompleted {
                        Text(notes)
                            .font(.system(size: 12, weight: .thin))
                            .foregroundColor(Color(hex: "B8B8B8"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Menu button
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(action: onReschedule) {
                        Label("Reschedule", systemImage: "calendar")
                    }

                    Button(action: onToggle) {
                        Label(
                            task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                            systemImage: task.isCompleted ? "xmark.circle" : "checkmark.circle"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "C4C4C4"))
                        .padding(8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            )
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 && value.translation.width > -100 {
                            offset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -50 {
                            withAnimation(.spring()) {
                                offset = CGSize(width: -80, height: 0)
                                showingActions = true
                            }
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                                showingActions = false
                            }
                        }
                    }
            )
        }
    }
}

struct SmartSuggestionCard: View {
    let suggestion: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "D4B5A9"))

            Text(suggestion)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(Color(hex: "7A7A7A"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FDF8F3"),
                            Color(hex: "FAF3EC")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "E8C4B8").opacity(0.3), lineWidth: 1)
        )
    }
}

struct LuxuryEmptyTaskState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4B5A9"))

            Text("You're all caught up!")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            Text("Take a moment to breathe. You're doing amazing.")
                .font(.system(size: 13, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
        )
    }
}

struct TimelineQuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(hex: "C4C4C4"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Wedding Phase Model
struct WeddingPhase: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let timeframe: String
    let startDate: Date
    let endDate: Date
    let taskCategories: [TaskCategory]
    let description: String

    static func allPhases(for weddingDate: Date) -> [WeddingPhase] {
        let calendar = Calendar.current

        return [
            WeddingPhase(
                title: "Dream & Discover",
                icon: "sparkles",
                timeframe: "12+ months before",
                startDate: calendar.date(byAdding: .month, value: -12, to: weddingDate) ?? Date(),
                endDate: calendar.date(byAdding: .month, value: -10, to: weddingDate) ?? Date(),
                taskCategories: [.planning],
                description: "Start collecting inspiration and setting your vision"
            ),
            WeddingPhase(
                title: "Book Your Team",
                icon: "person.2",
                timeframe: "10-12 months before",
                startDate: calendar.date(byAdding: .month, value: -10, to: weddingDate) ?? Date(),
                endDate: calendar.date(byAdding: .month, value: -8, to: weddingDate) ?? Date(),
                taskCategories: [.venue, .vendors, .photography, .catering],
                description: "Secure your venue and key vendors"
            ),
            WeddingPhase(
                title: "Design & Style",
                icon: "paintpalette",
                timeframe: "8-10 months before",
                startDate: calendar.date(byAdding: .month, value: -8, to: weddingDate) ?? Date(),
                endDate: calendar.date(byAdding: .month, value: -6, to: weddingDate) ?? Date(),
                taskCategories: [.attire, .decorations, .flowers],
                description: "Choose your dress and design elements"
            ),
            WeddingPhase(
                title: "Guest Planning",
                icon: "envelope",
                timeframe: "6-8 months before",
                startDate: calendar.date(byAdding: .month, value: -6, to: weddingDate) ?? Date(),
                endDate: calendar.date(byAdding: .month, value: -4, to: weddingDate) ?? Date(),
                taskCategories: [.invitations],
                description: "Finalize guest list and send save-the-dates"
            ),
            WeddingPhase(
                title: "Details & Logistics",
                icon: "checklist",
                timeframe: "3-6 months before",
                startDate: calendar.date(byAdding: .month, value: -4, to: weddingDate) ?? Date(),
                endDate: calendar.date(byAdding: .month, value: -2, to: weddingDate) ?? Date(),
                taskCategories: [.entertainment, .transportation, .accommodation],
                description: "Arrange transportation and accommodations"
            ),
            WeddingPhase(
                title: "Final Touches",
                icon: "seal",
                timeframe: "1-3 months before",
                startDate: calendar.date(byAdding: .month, value: -2, to: weddingDate) ?? Date(),
                endDate: calendar.date(byAdding: .month, value: -1, to: weddingDate) ?? Date(),
                taskCategories: [.legal, .other],
                description: "Finalize all details and confirmations"
            ),
            WeddingPhase(
                title: "The Final Countdown",
                icon: "heart",
                timeframe: "Final month",
                startDate: calendar.date(byAdding: .month, value: -1, to: weddingDate) ?? Date(),
                endDate: weddingDate,
                taskCategories: TaskCategory.allCases,
                description: "Last preparations and enjoy the moment"
            )
        ]
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            VStack {
                // Calendar implementation
                Text("Calendar View")
                    .font(.title)

                // This would be a full calendar implementation
                // For now, placeholder
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Wedding Day Schedule View
struct WeddingDayScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: DataManager

    @State private var schedule: [DayEvent] = DayEvent.defaultSchedule()
    @State private var editingEvent: DayEvent? = nil
    @State private var showingAddEvent = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FDFBF7")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Your Perfect Day")
                                .font(.system(size: 24, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text("Plan every beautiful moment")
                                .font(.system(size: 14, weight: .thin))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }
                        .padding(.top, 20)

                        // Timeline
                        VStack(spacing: 0) {
                            ForEach(schedule) { event in
                                DayEventRow(
                                    event: event,
                                    onEdit: { editingEvent = event }
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Add event button
                        Button(action: { showingAddEvent = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Event")
                            }
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "B89B91"))
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Wedding Day Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: exportSchedule) {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }

                        Button(action: shareSchedule) {
                            Label("Share", systemImage: "paperplane")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $editingEvent) { event in
            // Edit event sheet
            Text("Edit Event: \(event.title)")
        }
        .sheet(isPresented: $showingAddEvent) {
            // Add event sheet
            Text("Add New Event")
        }
    }

    private func exportSchedule() {
        // Export to PDF
    }

    private func shareSchedule() {
        // Share via system share sheet
    }
}

struct DayEvent: Identifiable {
    let id = UUID()
    var time: Date
    var title: String
    var duration: Int // in minutes
    var notes: String?
    var location: String?

    static func defaultSchedule() -> [DayEvent] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let baseDate = Date()

        return [
            DayEvent(
                time: formatter.date(from: "08:00") ?? baseDate,
                title: "Hair & Makeup",
                duration: 120,
                location: "Bridal Suite"
            ),
            DayEvent(
                time: formatter.date(from: "10:00") ?? baseDate,
                title: "Getting Ready Photos",
                duration: 60,
                location: "Bridal Suite"
            ),
            DayEvent(
                time: formatter.date(from: "11:30") ?? baseDate,
                title: "First Look",
                duration: 30,
                location: "Garden"
            ),
            DayEvent(
                time: formatter.date(from: "13:00") ?? baseDate,
                title: "Guest Arrival",
                duration: 30,
                location: "Ceremony Space"
            ),
            DayEvent(
                time: formatter.date(from: "13:30") ?? baseDate,
                title: "Ceremony",
                duration: 30,
                location: "Main Hall"
            ),
            DayEvent(
                time: formatter.date(from: "14:00") ?? baseDate,
                title: "Cocktail Hour",
                duration: 90,
                location: "Terrace"
            ),
            DayEvent(
                time: formatter.date(from: "15:30") ?? baseDate,
                title: "Reception",
                duration: 240,
                location: "Ballroom"
            ),
            DayEvent(
                time: formatter.date(from: "19:00") ?? baseDate,
                title: "First Dance",
                duration: 10,
                location: "Dance Floor"
            ),
            DayEvent(
                time: formatter.date(from: "21:00") ?? baseDate,
                title: "Cake Cutting",
                duration: 15,
                location: "Ballroom"
            )
        ]
    }
}

struct DayEventRow: View {
    let event: DayEvent
    let onEdit: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.time)
    }

    private var endTimeString: String {
        let endTime = event.time.addingTimeInterval(TimeInterval(event.duration * 60))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Time column
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text(endTimeString)
                    .font(.system(size: 12, weight: .thin, design: .rounded))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
            .frame(width: 60)

            // Timeline line
            Rectangle()
                .fill(Color(hex: "E8C4B8").opacity(0.3))
                .frame(width: 2)
                .overlay(
                    Circle()
                        .fill(Color(hex: "E8C4B8"))
                        .frame(width: 8, height: 8),
                    alignment: .top
                )

            // Event details
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 10, weight: .light))
                        Text(location)
                            .font(.system(size: 12, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                if let notes = event.notes {
                    Text(notes)
                        .font(.system(size: 12, weight: .thin))
                        .foregroundColor(Color(hex: "B8B8B8"))
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 20)

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(hex: "C4C4C4"))
            }
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var dataManager: DataManager

    @State private var title = ""
    @State private var notes = ""
    @State private var category: TaskCategory = .planning
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var hasDueDate = true

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FDFBF7")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TASK NAME")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            TextField("", text: $title)
                                .font(.system(size: 16, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .padding(.bottom, 8)
                                .overlay(
                                    Rectangle()
                                        .fill(Color(hex: "E0E0E0"))
                                        .frame(height: 0.5),
                                    alignment: .bottom
                                )
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TaskCategory.allCases, id: \.self) { cat in
                                        TaskCategoryOption(
                                            category: cat,
                                            isSelected: category == cat,
                                            action: { category = cat }
                                        )
                                    }
                                }
                            }
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIORITY")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { pri in
                                    TaskPriorityOption(
                                        priority: pri,
                                        isSelected: priority == pri,
                                        action: { priority = pri }
                                    )
                                }
                            }
                        }

                        // Due Date
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("DUE DATE")
                                    .font(.system(size: 10, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundColor(Color(hex: "9B9B9B"))

                                Spacer()

                                Toggle("", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "B89B91")))
                                    .scaleEffect(0.8)
                            }

                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .accentColor(Color(hex: "B89B91"))
                                    .colorScheme(.light)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            TextEditor(text: $notes)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .scrollContentBackground(.hidden)
                                .background(Color(hex: "FAF8F3"))
                                .frame(height: 100)
                                .cornerRadius(8)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "B89B91"))
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let task = WeddingTask(title: title, category: category, priority: priority)
        task.notes = notes.isEmpty ? nil : notes
        task.dueDate = hasDueDate ? dueDate : nil
        task.wedding = dataManager.wedding

        modelContext.insert(task)
        dataManager.updateWedding()
        dismiss()
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let task: WeddingTask
    @ObservedObject var dataManager: DataManager

    @State private var title = ""
    @State private var notes = ""
    @State private var category: TaskCategory = .planning
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = true

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FDFBF7")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Same UI as AddTaskView but pre-filled
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TASK NAME")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            TextField("", text: $title)
                                .font(.system(size: 16, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .padding(.bottom, 8)
                                .overlay(
                                    Rectangle()
                                        .fill(Color(hex: "E0E0E0"))
                                        .frame(height: 0.5),
                                    alignment: .bottom
                                )
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TaskCategory.allCases, id: \.self) { cat in
                                        TaskCategoryOption(
                                            category: cat,
                                            isSelected: category == cat,
                                            action: { category = cat }
                                        )
                                    }
                                }
                            }
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIORITY")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { pri in
                                    TaskPriorityOption(
                                        priority: pri,
                                        isSelected: priority == pri,
                                        action: { priority = pri }
                                    )
                                }
                            }
                        }

                        // Due Date
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("DUE DATE")
                                    .font(.system(size: 10, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundColor(Color(hex: "9B9B9B"))

                                Spacer()

                                Toggle("", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "B89B91")))
                                    .scaleEffect(0.8)
                            }

                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .accentColor(Color(hex: "B89B91"))
                                    .colorScheme(.light)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            TextEditor(text: $notes)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .scrollContentBackground(.hidden)
                                .background(Color(hex: "FAF8F3"))
                                .frame(height: 100)
                                .cornerRadius(8)
                        }

                        // Delete button
                        Button(action: deleteTask) {
                            Text("Delete Task")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "F44336"))
                        }
                        .padding(.top, 20)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTask()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "B89B91"))
                }
            }
        }
        .onAppear {
            title = task.title
            notes = task.notes ?? ""
            category = task.category
            priority = task.priority
            hasDueDate = task.dueDate != nil
            dueDate = task.dueDate ?? Date()
        }
    }

    private func updateTask() {
        task.title = title
        task.notes = notes.isEmpty ? nil : notes
        task.category = category
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.updatedAt = Date()

        dataManager.updateWedding()
        dismiss()
    }

    private func deleteTask() {
        modelContext.delete(task)
        dataManager.updateWedding()
        dismiss()
    }
}

struct TaskCategoryOption: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundColor(isSelected ? Color(hex: "B89B91") : Color(hex: "C4C4C4"))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "B89B91").opacity(0.1) : Color(hex: "F8F8F8"))
                    )

                Text(category.rawValue)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isSelected ? Color(hex: "2C2C2C") : Color(hex: "9B9B9B"))
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
    }
}

struct TaskPriorityOption: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(priority.rawValue)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : Color(hex: priority.color))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: priority.color) : Color(hex: priority.color).opacity(0.1))
                )
        }
    }
}

// MARK: - Phase Detail View
struct PhaseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let phase: WeddingPhase
    @ObservedObject var dataManager: DataManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Phase header
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: phase.icon)
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundColor(Color(hex: "B89B91"))

                        Text(phase.description)
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text(phase.timeframe)
                            .font(.system(size: 14, weight: .thin))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Suggested tasks for this phase
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Suggested Tasks")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .padding(.horizontal, 24)

                        // List of suggested tasks based on phase
                        ForEach(getSuggestedTasks(for: phase), id: \.self) { taskTitle in
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(Color(hex: "C4C4C4"))

                                Text(taskTitle)
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Spacer()

                                Button(action: {
                                    // Add task
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundColor(Color(hex: "B89B91"))
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(hex: "FDFBF7"))
            .navigationTitle(phase.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func getSuggestedTasks(for phase: WeddingPhase) -> [String] {
        switch phase.title {
        case "Dream & Discover":
            return [
                "Create a wedding vision board",
                "Set your budget",
                "Choose your wedding style",
                "Start guest list draft",
                "Research venues"
            ]
        case "Book Your Team":
            return [
                "Book your venue",
                "Hire wedding planner",
                "Book photographer",
                "Book videographer",
                "Secure caterer",
                "Book florist"
            ]
        case "Design & Style":
            return [
                "Shop for wedding dress",
                "Choose bridesmaid dresses",
                "Select color palette",
                "Design invitations",
                "Plan ceremony decor",
                "Choose reception style"
            ]
        case "Guest Planning":
            return [
                "Finalize guest list",
                "Send save-the-dates",
                "Book hotel blocks",
                "Create wedding website",
                "Plan rehearsal dinner"
            ]
        case "Details & Logistics":
            return [
                "Order invitations",
                "Book transportation",
                "Arrange accommodations",
                "Plan honeymoon",
                "Order wedding rings",
                "Schedule hair/makeup trials"
            ]
        case "Final Touches":
            return [
                "Send invitations",
                "Final dress fitting",
                "Finalize ceremony details",
                "Create seating chart",
                "Write vows",
                "Confirm all vendors"
            ]
        case "The Final Countdown":
            return [
                "Final venue walkthrough",
                "Pack for honeymoon",
                "Rehearsal dinner",
                "Prepare payments/tips",
                "Emergency kit",
                "Relax and breathe"
            ]
        default:
            return []
        }
    }
}