import SwiftUI

// DashboardCard model for ModernDashboardView
struct DashboardCard: Identifiable {
    let id: String
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct ModernDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedCard: DashboardCard? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero countdown card
                CountdownHeroCard()
                    .padding(.horizontal)
                
                // Quick actions grid
                QuickActionsGrid()
                    .padding(.horizontal)
                
                // Today's priorities
                TodaysPrioritiesCard()
                    .padding(.horizontal)
                
                // Progress overview
                ProgressOverviewCard()
                    .padding(.horizontal)
                
                // Recent activity
                RecentActivityCard()
                    .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
    }
}

struct CountdownHeroCard: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Visual countdown
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progressValue)
                
                VStack(spacing: 8) {
                    Text("\(dataManager.daysUntilWedding)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    Text("DAYS TO GO")
                        .font(.caption)
                        .tracking(2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            
            // Wedding date
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text(dataManager.weddingDate, style: .date)
                    .font(.headline)
            }
            
            // Quick stats
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(Int(dataManager.taskProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Tasks Done")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("$\(Int(dataManager.totalBudget - dataManager.spentBudget))")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Budget Left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("85")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Guests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
    }
    
    var progressValue: Double {
        let totalDays = 365.0
        let daysElapsed = totalDays - Double(dataManager.daysUntilWedding)
        return daysElapsed / totalDays
    }
}

struct QuickActionsGrid: View {
    let actions = [
        QuickAction(icon: "checklist", title: "Tasks", color: .blue, badge: "3"),
        QuickAction(icon: "envelope", title: "Invites", color: .green, badge: nil),
        QuickAction(icon: "camera.fill", title: "Photos", color: .purple, badge: nil),
        QuickAction(icon: "music.note", title: "Music", color: .orange, badge: "!")
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
            ForEach(actions) { action in
                QuickActionButton(action: action)
            }
        }
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let badge: String?
}

struct QuickActionButton: View {
    let action: QuickAction
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [action.color.opacity(0.3), action.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: action.icon)
                            .font(.title2)
                            .foregroundColor(action.color)
                    )
                
                if let badge = action.badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
            
            Text(action.title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct TodaysPrioritiesCard: View {
    let priorities = [
        Priority(title: "Call florist about centerpieces", time: "10:00 AM", isUrgent: true),
        Priority(title: "Finalize catering headcount", time: "2:00 PM", isUrgent: false),
        Priority(title: "Review photographer contract", time: "4:00 PM", isUrgent: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Today's Priorities", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("View All")
                    .font(.caption)
                    .foregroundColor(.pink)
            }
            
            VStack(spacing: 12) {
                ForEach(priorities) { priority in
                    PriorityRow(priority: priority)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

struct Priority: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let isUrgent: Bool
}

struct PriorityRow: View {
    let priority: Priority
    @State private var isCompleted = false
    
    var body: some View {
        HStack {
            Button(action: { withAnimation { isCompleted.toggle() } }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(priority.title)
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(priority.time)
                        .font(.caption)
                    
                    if priority.isUrgent {
                        Label("Urgent", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ProgressOverviewCard: View {
    @EnvironmentObject var dataManager: DataManager
    
    let categories = [
        ("Venue", 0.9, Color.indigo),
        ("Vendors", 0.7, Color.purple),
        ("Guests", 0.6, Color.blue),
        ("Details", 0.4, Color.pink)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(categories, id: \.0) { category, progress, color in
                    HStack {
                        Text(category)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(color.opacity(0.2))
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(color)
                                    .frame(width: geometry.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

struct RecentActivityCard: View {
    let activities = [
        ("Venue payment confirmed", "2 hours ago", "building.columns"),
        ("Guest RSVP received", "5 hours ago", "person.2"),
        ("Photographer booked", "Yesterday", "camera")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(activities, id: \.0) { activity, time, icon in
                    HStack {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundColor(.pink)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity)
                                .font(.subheadline)
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ModernDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ModernDashboardView()
            .environmentObject(DataManager())
    }
}