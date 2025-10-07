import SwiftUI
import SwiftData

struct LuxuryDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeddingTask.dueDate) private var allTasks: [WeddingTask]
    @Query private var budgetItems: [BudgetItem]
    @Query private var guests: [Guest]
    @State private var animateIn = false
    @State private var progressAnimation = false
    @State private var showAffirmation = true

    // Calculate progress
    private var planningProgress: Double {
        let completedTasks = allTasks.filter { $0.isCompleted }.count
        let totalTasks = max(allTasks.count, 1)
        return Double(completedTasks) / Double(totalTasks)
    }

    // Today's tasks
    private var todayTasks: [WeddingTask] {
        let calendar = Calendar.current
        let today = Date()
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today) && !task.isCompleted
        }.prefix(2).map { $0 }
    }

    // Next milestone
    private var nextMilestone: WeddingTask? {
        let future = allTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate > Date()
        }.first
        return future
    }

    // Budget calculations
    private var totalBudget: Double {
        dataManager.wedding?.totalBudget ?? 0
    }

    private var allocatedBudget: Double {
        budgetItems.reduce(0) { $0 + $1.estimatedAmount }
    }

    // Guest calculations
    private var confirmedGuests: Int {
        guests.filter { $0.rsvpStatus == .confirmed }.count
    }

    private var pendingGuests: Int {
        guests.filter { $0.rsvpStatus == .pending }.count
    }

    // Vendor status
    private var bookedVendors: Int {
        dataManager.wedding?.vendors?.filter { $0.isBooked }.count ?? 0
    }

    private var totalVendors: Int {
        dataManager.wedding?.vendors?.count ?? 0
    }

    // Tasks due this week
    private var tasksThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()

        return allTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate >= startOfWeek && dueDate <= endOfWeek
        }.count
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero Section - Countdown & Progress
                heroSection
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                // Today's Focus
                if !todayTasks.isEmpty {
                    todaysFocusSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }

                // Snapshot Grid
                snapshotGrid
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                // Next Milestone
                if nextMilestone != nil {
                    nextMilestoneSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }

                // Emotional Touch
                emotionalTouchSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "FDFBF7"),
                    Color(hex: "FBF8F4")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                progressAnimation = true
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Large elegant countdown
            VStack(spacing: 8) {
                Text("\(dataManager.daysUntilWedding)")
                    .font(.system(size: 64, weight: .ultraLight, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateIn)

                Text("days to go")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "7A7A7A"))
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
            }

            // Progress indicator
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "F0E8E4"))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "D4A76A"),
                                        Color(hex: "B89B91")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressAnimation ? geometry.size.width * planningProgress : 0, height: 8)
                            .animation(.spring(response: 1.2, dampingFraction: 0.8), value: progressAnimation)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 60)

                Text("\(Int(planningProgress * 100))% of planning completed")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
            }

            // Motivational microcopy
            Text(getMotivationalMessage())
                .font(.system(size: 14, weight: .light, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "B89B91"),
                            Color(hex: "D4A76A")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: animateIn)
        }
    }

    // MARK: - Today's Focus Section
    private var todaysFocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Your focus today")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            // Task cards
            VStack(spacing: 12) {
                ForEach(todayTasks, id: \.id) { task in
                    HStack {
                        // Priority indicator
                        Circle()
                            .fill(Color(hex: "D4A76A").opacity(0.3))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            if let time = task.dueDate {
                                Text(formatTime(time))
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "D4D4D4"))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.3), value: animateIn)
    }

    // MARK: - Snapshot Grid
    private var snapshotGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Time card
            SnapshotCard(
                icon: "clock",
                title: "Time",
                value: "\(tasksThisWeek)",
                subtitle: "tasks this week",
                color: Color(hex: "E8F2E8")
            )
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateIn)

            // Team card
            SnapshotCard(
                icon: "person.2",
                title: "Team",
                value: "\(bookedVendors) of \(totalVendors)",
                subtitle: "vendors booked",
                color: Color(hex: "E8E8F2")
            )
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateIn)

            // Guests card
            SnapshotCard(
                icon: "envelope",
                title: "Guests",
                value: "\(confirmedGuests)",
                subtitle: "\(pendingGuests) pending",
                color: Color(hex: "F2E8E8")
            )
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateIn)

            // Funds card
            SnapshotCard(
                icon: "dollarsign.circle",
                title: "Funds",
                value: formatCurrency(allocatedBudget),
                subtitle: "of \(formatCurrency(totalBudget)) allocated",
                color: Color(hex: "FFF4E6")
            )
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: animateIn)
        }
    }

    // MARK: - Next Milestone Section
    private var nextMilestoneSection: some View {
        VStack(spacing: 0) {
            if let milestone = nextMilestone, let dueDate = milestone.dueDate {
                HStack {
                    // Timeline indicator
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "D4A76A"))
                            .frame(width: 12, height: 12)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "D4A76A").opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2, height: 30)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next Milestone")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "9B9B9B"))

                        Text(milestone.title)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Text("in \(daysUntil(dueDate)) days")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(Color(hex: "B89B91"))
                    }

                    Spacer()

                    // Calendar icon with date
                    VStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color(hex: "D4A76A"))

                        Text(formatDate(dueDate))
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFF9F5"),
                                    Color.white
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 2)
                )
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateIn)
    }

    // MARK: - Emotional Touch Section
    private var emotionalTouchSection: some View {
        VStack(spacing: 20) {
            // Decorative element
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color(hex: "E8DDD8").opacity(0.3))
                    .frame(height: 0.5)

                Image(systemName: "heart")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(Color(hex: "D4A76A"))

                Rectangle()
                    .fill(Color(hex: "E8DDD8").opacity(0.3))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 40)

            // Affirmation card
            VStack(spacing: 16) {
                Text(getWeeklyAffirmation())
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text("— Your wedding journey —")
                    .font(.system(size: 11, weight: .thin, design: .serif))
                    .foregroundColor(Color(hex: "B89B91"))
                    .tracking(2)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFF9F5").opacity(0.5),
                                Color(hex: "FBF8F4").opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 1.0).delay(1.0), value: animateIn)
    }

    // MARK: - Helper Functions
    private func getMotivationalMessage() -> String {
        let progress = planningProgress * 100
        if progress < 25 {
            return "One step closer to your perfect day"
        } else if progress < 50 {
            return "Your love story is unfolding beautifully"
        } else if progress < 75 {
            return "Every detail is coming together perfectly"
        } else {
            return "Almost there – your dream day awaits"
        }
    }

    private func getWeeklyAffirmation() -> String {
        let affirmations = [
            "Breathe. You're creating something unforgettable.",
            "Trust the journey. Every decision leads to your perfect day.",
            "Your love is the foundation. Everything else is decoration.",
            "This moment of planning is part of your beautiful story.",
            "Perfection lies in the love you share, not the details.",
            "Let joy guide your choices. Your happiness is the priority.",
            "Every step forward is a celebration of your commitment."
        ]

        // Use day of week to rotate affirmations
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        return affirmations[dayOfWeek % affirmations.count]
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "€0"
    }
}

// MARK: - Snapshot Card Component
struct SnapshotCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(hex: "7A7A7A"))

                Spacer()

                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text(subtitle)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color(hex: "B8B8B8"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.05))
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
        )
    }
}

// Preview
struct LuxuryDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        LuxuryDashboardView()
            .environmentObject(DataManager())
            .modelContainer(for: [Wedding.self, Vendor.self, Guest.self, WeddingTask.self, BudgetItem.self])
    }
}