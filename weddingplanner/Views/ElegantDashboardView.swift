import SwiftUI

struct ElegantDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Refined countdown card
                DelicateCountdownCard()
                
                // Today's agenda
                AgendaCard()
                
                // Progress indicators
                HStack(spacing: 16) {
                    ProgressCard(
                        title: "Planning",
                        value: dataManager.taskProgress,
                        color: PastelColors.lavender
                    )
                    
                    ProgressCard(
                        title: "Budget",
                        value: (dataManager.totalBudget - dataManager.spentBudget) / dataManager.totalBudget,
                        color: PastelColors.mint
                    )
                }
                
                // Quick actions
                QuickActionsSection()
                
                // Vendor reminders
                VendorRemindersCard()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
        }
    }
}

struct DelicateCountdownCard: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Date display
            HStack(spacing: 16) {
                Image(systemName: "heart")
                    .font(.system(size: 16))
                    .foregroundColor(PastelColors.rose)
                
                Text(dataManager.weddingDate, style: .date)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "4A4A4A"))
                
                Image(systemName: "heart")
                    .font(.system(size: 16))
                    .foregroundColor(PastelColors.rose)
            }
            
            // Elegant countdown
            HStack(alignment: .bottom, spacing: 24) {
                CountdownUnit(value: dataManager.daysUntilWedding / 30, unit: "months")
                
                Text("·")
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundColor(Color(hex: "E4B4B4"))
                
                CountdownUnit(value: dataManager.daysUntilWedding % 30, unit: "days")
            }
            
            // Progress line
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "F5F5F5"))
                        .frame(height: 1)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [PastelColors.rose, PastelColors.peach],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressValue, height: 1)
                }
            }
            .frame(height: 1)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color(hex: "E4B4B4").opacity(0.08), radius: 20, y: 10)
        )
    }
    
    var progressValue: Double {
        let totalDays = 365.0
        let daysElapsed = totalDays - Double(dataManager.daysUntilWedding)
        return min(daysElapsed / totalDays, 1.0)
    }
}

struct CountdownUnit: View {
    let value: Int
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 48, weight: .ultraLight, design: .serif))
                .foregroundColor(Color(hex: "4A4A4A"))
            
            Text(unit.uppercased())
                .font(.system(size: 10, weight: .regular, design: .serif))
                .tracking(1.5)
                .foregroundColor(Color(hex: "8B7E74"))
        }
    }
}

struct AgendaCard: View {
    let tasks = [
        AgendaItem(time: "10:00", title: "Florist Meeting", icon: "leaf", color: PastelColors.sage),
        AgendaItem(time: "14:00", title: "Cake Tasting", icon: "birthday.cake", color: PastelColors.peach),
        AgendaItem(time: "16:30", title: "Venue Walkthrough", icon: "building.columns", color: PastelColors.lavender)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today's Agenda")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "4A4A4A"))
            
            VStack(spacing: 16) {
                ForEach(tasks, id: \.title) { task in
                    HStack(spacing: 16) {
                        // Time
                        Text(task.time)
                            .font(.system(size: 14, weight: .light, design: .rounded))
                            .foregroundColor(Color(hex: "8B7E74"))
                            .frame(width: 50, alignment: .leading)
                        
                        // Icon
                        Circle()
                            .fill(task.color.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: task.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(task.color)
                            )
                        
                        // Title
                        Text(task.title)
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "4A4A4A"))
                        
                        Spacer()
                        
                        // Arrow
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "C4C4C4"))
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color(hex: "E4B4B4").opacity(0.08), radius: 20, y: 10)
        )
    }
}

struct AgendaItem {
    let time: String
    let title: String
    let icon: String
    let color: Color
}

struct ProgressCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "8B7E74"))
            
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: value)
                
                Text("\(Int(value * 100))%")
                    .font(.system(size: 20, weight: .ultraLight, design: .rounded))
                    .foregroundColor(Color(hex: "4A4A4A"))
            }
            .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .shadow(color: color.opacity(0.1), radius: 15, y: 8)
        )
    }
}

struct QuickActionsSection: View {
    let actions = [
        ElegantQuickAction(icon: "envelope", title: "Invitations", color: PastelColors.rose),
        ElegantQuickAction(icon: "camera", title: "Photos", color: PastelColors.lavender),
        ElegantQuickAction(icon: "music.note", title: "Music", color: PastelColors.peach),
        ElegantQuickAction(icon: "flower", title: "Flowers", color: PastelColors.sage)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "4A4A4A"))
            
            HStack(spacing: 16) {
                ForEach(actions, id: \.title) { action in
                    ElegantQuickActionButton(action: action)
                }
            }
        }
    }
}

struct ElegantQuickAction {
    let icon: String
    let title: String
    let color: Color
}

struct ElegantQuickActionButton: View {
    let action: ElegantQuickAction
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(action.color.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: action.icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(action.color)
            }
            
            Text(action.title)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundColor(Color(hex: "8B7E74"))
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

struct VendorRemindersCard: View {
    let reminders = [
        VendorReminder(vendor: "Photographer", message: "Contract review needed", urgency: .medium),
        VendorReminder(vendor: "Caterer", message: "Final menu approval", urgency: .high)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vendor Reminders")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "4A4A4A"))
                
                Spacer()
                
                Circle()
                    .fill(PastelColors.rose)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("\(reminders.count)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(spacing: 12) {
                ForEach(reminders, id: \.vendor) { reminder in
                    HStack {
                        Circle()
                            .fill(reminder.urgency.color.opacity(0.2))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reminder.vendor)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(Color(hex: "4A4A4A"))
                            
                            Text(reminder.message)
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(Color(hex: "8B7E74"))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color(hex: "E4B4B4").opacity(0.08), radius: 20, y: 10)
        )
    }
}

struct VendorReminder {
    let vendor: String
    let message: String
    let urgency: Urgency
    
    enum Urgency {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return PastelColors.mint
            case .medium: return PastelColors.peach
            case .high: return PastelColors.rose
            }
        }
    }
}

struct ElegantDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ElegantDashboardView()
            .environmentObject(DataManager())
    }
}