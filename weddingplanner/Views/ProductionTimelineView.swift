import SwiftUI
import SwiftData
import UIKit

// MARK: - Main Production Timeline View
struct ProductionTimelineView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext

    // View States
    @State private var selectedPhase: WeddingPhase? = nil
    @State private var showingCalendar = false
    @State private var showingDaySchedule = false
    @State private var showingAddTask = false
    @State private var editingTask: WeddingTask? = nil
    @State private var currentMicroCopy = 0
    @State private var animateIn = false
    @State private var sparkleAnimation = false
    @State private var searchText = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingSearch = false

    // Haptic feedback generator
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Micro-copy messages that rotate
    private let microCopyMessages = [
        "Every great love deserves a great plan",
        "You're further ahead than you think",
        "One task at a time, love",
        "Your perfect day is coming together",
        "Trust the journey, enjoy the process",
        "Small steps, big dreams",
        "This is your moment to shine",
        "Creating memories, one detail at a time"
    ]

    // Timer for micro-copy rotation
    let microCopyTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case overdue = "Overdue"
        case completed = "Completed"

        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "sun.max"
            case .thisWeek: return "calendar"
            case .overdue: return "exclamationmark.circle"
            case .completed: return "checkmark.circle"
            }
        }
    }

    var body: some View {
        ZStack {
            // Enhanced gradient background for better contrast
            LinearGradient(
                colors: [
                    Color(hex: "F2EFE9"),  // Light warm gray
                    Color(hex: "F8F5F0")   // Soft off-white
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

                // Search bar (hidden by default)
                if showingSearch {
                    searchBar
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Planning Timeline (Phases)
                        planningTimeline
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)

                        // Task Filters
                        taskFilters
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateIn)

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

            // Floating action buttons
            VStack {
                HStack {
                    Spacer()

                    // Search button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingSearch.toggle()
                            if !showingSearch {
                                searchText = ""
                            }
                        }
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 24)
                }

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
            ProductionWeddingDayScheduleView(dataManager: dataManager)
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
            impactFeedback.prepare()
            selectionFeedback.prepare()
            notificationFeedback.prepare()
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
                    SparkleEffect()
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
            Text(LocalizedStringKey(microCopyMessages[currentMicroCopy]))
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

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "9B9B9B"))

            TextField("Search tasks...", text: $searchText)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color(hex: "2C2C2C"))

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "C4C4C4"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Task Filters
    private var taskFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    ProductionFilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getTaskCount(for: filter),
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedFilter = filter
                                selectionFeedback.selectionChanged()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
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
                            onTap: {
                                selectedPhase = phase
                                impactFeedback.impactOccurred()
                            }
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
                ForEach(filteredTasks) { task in
                    ProductionTaskCard(
                        task: task,
                        onToggle: {
                            toggleTask(task)
                        },
                        onEdit: {
                            editingTask = task
                            impactFeedback.impactOccurred()
                        },
                        onReschedule: {
                            rescheduleTask(task)
                            impactFeedback.impactOccurred()
                        }
                    )
                    .padding(.horizontal, 24)
                }

                if filteredTasks.isEmpty {
                    EmptyTaskState(filter: selectedFilter)
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
                title: String(localized: "Wedding Day Schedule"),
                subtitle: String(localized: "Plan your perfect day timeline"),
                color: Color(hex: "E8C4B8"),
                action: {
                    showingDaySchedule = true
                    impactFeedback.impactOccurred()
                }
            )

            TimelineQuickActionButton(
                icon: "calendar",
                title: String(localized: "Calendar View"),
                subtitle: String(localized: "See all events at a glance"),
                color: Color(hex: "C8D4E8"),
                action: {
                    showingCalendar = true
                    impactFeedback.impactOccurred()
                }
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Floating Add Button
    private var addTaskButton: some View {
        Button(action: {
            if dataManager.canAddTask() {
                showingAddTask = true
                impactFeedback.impactOccurred()
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
                    .rotationEffect(.degrees(showingAddTask ? 45 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAddTask)
            }
        }
    }

    // MARK: - Helper Methods
    private var filteredTasks: [WeddingTask] {
        guard let tasks = dataManager.wedding?.tasks else { return [] }

        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        // Apply search filter
        var filtered = tasks.filter { task in
            searchText.isEmpty ||
            task.title.localizedCaseInsensitiveContains(searchText) ||
            (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }

        // Apply task filter
        switch selectedFilter {
        case .all:
            filtered = filtered.filter { !$0.isCompleted }
        case .today:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDateInToday(dueDate) && !task.isCompleted
            }
        case .thisWeek:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate <= weekFromNow && !task.isCompleted
            }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue && !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        }

        return filtered
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
            .prefix(selectedFilter == .all ? 10 : 50)
            .map { $0 }
    }

    private func getTaskCount(for filter: TaskFilter) -> Int {
        guard let tasks = dataManager.wedding?.tasks else { return 0 }

        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        switch filter {
        case .all:
            return tasks.filter { !$0.isCompleted }.count
        case .today:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDateInToday(dueDate) && !task.isCompleted
            }.count
        case .thisWeek:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate <= weekFromNow && !task.isCompleted
            }.count
        case .overdue:
            return tasks.filter { $0.isOverdue && !$0.isCompleted }.count
        case .completed:
            return tasks.filter { $0.isCompleted }.count
        }
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
                return String(localized: "📷 Most couples book their photographer 6-8 months out. Ready to start looking?")
            }
        }

        if daysLeft < 90 && daysLeft > 60 {
            if dataManager.wedding?.guests?.filter({ $0.invitationSent }).isEmpty ?? true {
                return String(localized: "✉️ Time to send those invitations! Most go out 2-3 months before.")
            }
        }

        if overdueTasksCount ?? 0 > 3 {
            return String(localized: "💝 You have a few tasks that need attention. Take them one at a time - you've got this!")
        }

        // Positive reinforcement
        if let completed = dataManager.wedding?.tasks?.filter({ $0.isCompleted }).count,
           let total = dataManager.wedding?.tasks?.count,
           total > 0 {
            let percentage = Double(completed) / Double(total)
            if percentage > 0.7 {
                return String(localized: "🌟 You're doing amazing! Over 70% of your tasks are complete.")
            }
        }

        return nil
    }

    private func checkMilestones() {
        let days = dataManager.daysUntilWedding

        // Trigger sparkle animation for milestones
        if days == 100 || days == 60 || days == 30 || days == 7 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sparkleAnimation = true
            }

            notificationFeedback.notificationOccurred(.success)

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
            // Trigger celebration
            notificationFeedback.notificationOccurred(.success)
            sparkleAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                sparkleAnimation = false
            }
        } else {
            selectionFeedback.selectionChanged()
        }
    }

    private func rescheduleTask(_ task: WeddingTask) {
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

struct SparkleEffect: View {
    @State private var sparkles: [SparkleItem] = []

    struct SparkleItem: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
    }

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(Color(hex: "E8C4B8").opacity(0.8))
                    .offset(x: sparkle.x, y: sparkle.y)
                    .scaleEffect(0)
                    .opacity(0)
                    .animation(
                        .easeOut(duration: 1.5)
                        .delay(sparkle.delay),
                        value: sparkles.count
                    )
            }
        }
        .onAppear {
            sparkles = (0..<12).map { index in
                SparkleItem(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: -40...40),
                    size: CGFloat.random(in: 8...16),
                    delay: Double(index) * 0.1
                )
            }
        }
    }
}

struct ProductionFilterChip: View {
    let filter: ProductionTimelineView.TaskFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .regular))

                Text(LocalizedStringKey(filter.rawValue))
                    .font(.system(size: 12, weight: .regular))

                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 11, weight: .regular))
                }
            }
            .foregroundColor(isSelected ? .white : Color(hex: "9B9B9B"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "B89B91") : Color(hex: "F0F0F0"))
            )
        }
    }
}

struct ProductionTaskCard: View {
    let task: WeddingTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onReschedule: () -> Void

    @State private var isPressed = false
    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

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
        guard let dueDate = task.dueDate else { return String(localized: "No deadline") }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        if task.isOverdue {
            return String(localized: "Overdue")
        } else {
            return formatter.localizedString(for: dueDate, relativeTo: Date())
        }
    }

    var body: some View {
        ZStack {
            // Background actions
            HStack(spacing: 0) {
                // Edit action
                Button(action: {
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                    onEdit()
                }) {
                    VStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 20, weight: .light))
                        Text("Edit")
                            .font(.system(size: 10, weight: .regular))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(Color(hex: "B89B91"))
                }

                Spacer()

                // Reschedule action
                Button(action: {
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                    onReschedule()
                }) {
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
                Button(action: {
                    onToggle()
                    impactFeedback.impactOccurred()
                }) {
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

                // Drag indicator
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(hex: "E0E0E0"))
                    .opacity(isDragging ? 0.5 : 1)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .offset(x: offset.width)
            .scaleEffect(isDragging ? 0.95 : 1)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        if abs(value.translation.width) < 160 {
                            offset = value.translation
                        }

                        // Haptic feedback at thresholds
                        if abs(value.translation.width) == 80 {
                            impactFeedback.impactOccurred()
                        }
                    }
                    .onEnded { value in
                        isDragging = false

                        if value.translation.width < -80 {
                            // Swipe left - show reschedule
                            withAnimation(.spring()) {
                                offset = CGSize(width: -80, height: 0)
                            }
                        } else if value.translation.width > 80 {
                            // Swipe right - show edit
                            withAnimation(.spring()) {
                                offset = CGSize(width: 80, height: 0)
                            }
                        } else {
                            // Reset
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
            )
        }
    }
}

struct EmptyTaskState: View {
    let filter: ProductionTimelineView.TaskFilter

    private var message: (title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String) {
        switch filter {
        case .all:
            return ("You're all caught up!", "Take a moment to breathe. You're doing amazing.", "checkmark.seal")
        case .today:
            return ("No tasks for today", "Enjoy this peaceful moment.", "sun.max")
        case .thisWeek:
            return ("Clear week ahead", "Perfect time to plan ahead.", "calendar")
        case .overdue:
            return ("No overdue tasks!", "You're right on schedule.", "clock.badge.checkmark")
        case .completed:
            return ("No completed tasks yet", "Start checking things off!", "checklist")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: message.icon)
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4B5A9"))

            Text(message.title)
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            Text(message.subtitle)
                .font(.system(size: 13, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}