import SwiftUI

struct ModernTimelineView: View {
    @State private var selectedPhase = 0
    
    let phases = [
        TimelinePhase(
            title: "6 Months Out",
            color: Color.purple,
            tasks: [
                ModernTimelineTask(title: "Book venue", isComplete: true),
                ModernTimelineTask(title: "Hire photographer", isComplete: true),
                ModernTimelineTask(title: "Choose wedding party", isComplete: false),
                ModernTimelineTask(title: "Set budget", isComplete: true)
            ]
        ),
        TimelinePhase(
            title: "3 Months Out",
            color: Color.pink,
            tasks: [
                ModernTimelineTask(title: "Send invitations", isComplete: false),
                ModernTimelineTask(title: "Order wedding cake", isComplete: false),
                ModernTimelineTask(title: "Book honeymoon", isComplete: false),
                ModernTimelineTask(title: "Hair & makeup trial", isComplete: false)
            ]
        ),
        TimelinePhase(
            title: "1 Month Out",
            color: Color.orange,
            tasks: [
                ModernTimelineTask(title: "Final dress fitting", isComplete: false),
                ModernTimelineTask(title: "Confirm guest count", isComplete: false),
                ModernTimelineTask(title: "Rehearsal dinner", isComplete: false),
                ModernTimelineTask(title: "Pack for honeymoon", isComplete: false)
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Phase selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<phases.count, id: \.self) { index in
                        PhaseButton(
                            phase: phases[index],
                            isSelected: selectedPhase == index,
                            action: { selectedPhase = index }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            // Timeline content
            ScrollView {
                VStack(spacing: 16) {
                    // Progress card
                    PhaseProgressCard(phase: phases[selectedPhase])
                        .padding(.horizontal)
                    
                    // Tasks list
                    VStack(spacing: 12) {
                        ForEach(phases[selectedPhase].tasks) { task in
                            ModernTaskRow(task: task)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct TimelinePhase {
    let title: String
    let color: Color
    let tasks: [ModernTimelineTask]
    
    var completionRate: Double {
        let completed = tasks.filter { $0.isComplete }.count
        return Double(completed) / Double(tasks.count)
    }
}

struct ModernTimelineTask: Identifiable {
    let id = UUID()
    let title: String
    let isComplete: Bool
}

struct PhaseButton: View {
    let phase: TimelinePhase
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(phase.color, lineWidth: isSelected ? 3 : 2)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: phase.completionRate)
                        .stroke(phase.color, lineWidth: isSelected ? 3 : 2)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(phase.completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Text(phase.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct PhaseProgressCard: View {
    let phase: TimelinePhase
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(phase.tasks.filter { $0.isComplete }.count) of \(phase.tasks.count) tasks completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: phase.completionRate,
                    color: phase.color,
                    lineWidth: 8
                )
                .frame(width: 80, height: 80)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatPill(
                    icon: "checkmark.circle",
                    value: "\(phase.tasks.filter { $0.isComplete }.count)",
                    label: "Done",
                    color: Color.green
                )
                
                StatPill(
                    icon: "clock",
                    value: "\(phase.tasks.filter { !$0.isComplete }.count)",
                    label: "Pending",
                    color: Color.orange
                )
                
                if phase.tasks.filter({ !$0.isComplete }).count > 0 {
                    StatPill(
                        icon: "calendar.badge.exclamationmark",
                        value: "2",
                        label: "Urgent",
                        color: Color.red
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
            
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct ModernTaskRow: View {
    let task: ModernTimelineTask
    @State private var isChecked = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { withAnimation { isChecked.toggle() } }) {
                    Image(systemName: isChecked || task.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isChecked || task.isComplete ? Color.green : Color.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(isChecked || task.isComplete)
                    
                    HStack(spacing: 12) {
                        Label("Due in 5 days", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("High priority", systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(Color.orange)
                    }
                }
                
                Spacer()
                
                Button(action: { withAnimation { showDetails.toggle() } }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showDetails ? 90 : 0))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact vendor by end of week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button("Add Note") {
                            
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.blue.opacity(0.1)))
                        
                        Button("Set Reminder") {
                            
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.orange.opacity(0.1)))
                    }
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct ModernTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        ModernTimelineView()
    }
}