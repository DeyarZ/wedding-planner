import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter = "All"
    @State private var showingAddTask = false
    
    let filters = ["All", "Today", "This Week", "Overdue"]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterChip(
                                title: filter,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        TimelineSectionView(
                            title: "6 Months Before",
                            tasks: [
                                TimelineTask(title: "Book venue", isCompleted: true, dueDate: "Completed"),
                                TimelineTask(title: "Hire photographer", isCompleted: true, dueDate: "Completed"),
                                TimelineTask(title: "Choose wedding party", isCompleted: false, dueDate: "Due in 2 days", isOverdue: true)
                            ]
                        )
                        
                        TimelineSectionView(
                            title: "3 Months Before",
                            tasks: [
                                TimelineTask(title: "Send invitations", isCompleted: false, dueDate: "Due in 15 days"),
                                TimelineTask(title: "Order wedding cake", isCompleted: false, dueDate: "Due in 20 days"),
                                TimelineTask(title: "Book honeymoon", isCompleted: false, dueDate: "Due in 30 days")
                            ]
                        )
                        
                        TimelineSectionView(
                            title: "1 Month Before",
                            tasks: [
                                TimelineTask(title: "Final dress fitting", isCompleted: false, dueDate: "Upcoming"),
                                TimelineTask(title: "Confirm guest count", isCompleted: false, dueDate: "Upcoming"),
                                TimelineTask(title: "Rehearsal dinner planning", isCompleted: false, dueDate: "Upcoming")
                            ]
                        )
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if dataManager.canAddTask() {
                            showingAddTask = true
                        } else {
                            dataManager.showPaywallIfNeeded(for: "task")
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.pink : Color(.systemGray5))
                )
        }
    }
}

struct TimelineSectionView: View {
    let title: String
    let tasks: [TimelineTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TimelineTaskRow(task: task)
                    
                    if task.id != tasks.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
        }
    }
}

struct TimelineTask: Identifiable {
    let id = UUID()
    let title: String
    let isCompleted: Bool
    let dueDate: String
    var isOverdue: Bool = false
}

struct TimelineTaskRow: View {
    let task: TimelineTask
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(task.isCompleted ? Color.green : (task.isOverdue ? Color.red : Color.gray), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted, color: .gray)
                
                HStack(spacing: 8) {
                    Text(task.dueDate)
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                    
                    if task.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button("Mark as Complete", action: {})
                Button("Edit", action: {})
                Button("Delete", role: .destructive, action: {})
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}