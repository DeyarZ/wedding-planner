import SwiftUI

struct FlowingTimelineView: View {
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var pageProgress: CGFloat = 0
    
    let timelinePages = [
        TimelinePage(title: "6 Months Before", subtitle: "Foundation", tasks: [
            TimelineItem(title: "Book your venue", isComplete: true, urgency: .normal),
            TimelineItem(title: "Hire photographer", isComplete: true, urgency: .normal),
            TimelineItem(title: "Choose wedding party", isComplete: false, urgency: .high),
            TimelineItem(title: "Set budget", isComplete: true, urgency: .normal)
        ]),
        TimelinePage(title: "3 Months Before", subtitle: "Details", tasks: [
            TimelineItem(title: "Send invitations", isComplete: false, urgency: .high),
            TimelineItem(title: "Order wedding cake", isComplete: false, urgency: .medium),
            TimelineItem(title: "Book honeymoon", isComplete: false, urgency: .normal),
            TimelineItem(title: "Schedule hair & makeup trial", isComplete: false, urgency: .medium)
        ]),
        TimelinePage(title: "1 Month Before", subtitle: "Final Touches", tasks: [
            TimelineItem(title: "Final dress fitting", isComplete: false, urgency: .normal),
            TimelineItem(title: "Confirm guest count", isComplete: false, urgency: .high),
            TimelineItem(title: "Rehearsal dinner", isComplete: false, urgency: .medium),
            TimelineItem(title: "Pack for honeymoon", isComplete: false, urgency: .low)
        ]),
        TimelinePage(title: "Wedding Week", subtitle: "The Finale", tasks: [
            TimelineItem(title: "Final venue walkthrough", isComplete: false, urgency: .high),
            TimelineItem(title: "Deliver tips & payments", isComplete: false, urgency: .high),
            TimelineItem(title: "Rehearsal", isComplete: false, urgency: .high),
            TimelineItem(title: "Relax & breathe", isComplete: false, urgency: .low)
        ])
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background pages effect
                ForEach(0..<timelinePages.count, id: \.self) { index in
                    if index >= currentPage - 1 && index <= currentPage + 1 {
                        TimelinePageView(
                            page: timelinePages[index],
                            pageIndex: index,
                            currentPage: currentPage,
                            dragOffset: dragOffset,
                            geometry: geometry
                        )
                    }
                }
                
                // Page indicators
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ForEach(0..<timelinePages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.pink : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 40 : 20, height: 6)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            if value.translation.width > 100 && currentPage > 0 {
                                currentPage -= 1
                            } else if value.translation.width < -100 && currentPage < timelinePages.count - 1 {
                                currentPage += 1
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
    }
}

struct TimelinePage {
    let title: String
    let subtitle: String
    let tasks: [TimelineItem]
}

struct TimelineItem {
    let title: String
    let isComplete: Bool
    let urgency: Urgency
    
    enum Urgency {
        case low, normal, medium, high
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .normal: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct TimelinePageView: View {
    let page: TimelinePage
    let pageIndex: Int
    let currentPage: Int
    let dragOffset: CGFloat
    let geometry: GeometryProxy
    
    @State private var taskAnimations: [Bool] = Array(repeating: false, count: 10)
    
    var offset: CGFloat {
        let pageOffset = CGFloat(pageIndex - currentPage) * geometry.size.width
        return pageOffset + dragOffset
    }
    
    var scale: CGFloat {
        let distance = abs(offset) / geometry.size.width
        return 1 - min(distance * 0.2, 0.2)
    }
    
    var opacity: Double {
        let distance = abs(offset) / geometry.size.width
        return 1 - min(distance, 0.5)
    }
    
    var rotation: Double {
        let normalizedOffset = offset / geometry.size.width
        return Double(normalizedOffset * 10)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(page.subtitle.uppercased())
                    .font(.caption)
                    .tracking(2)
                    .foregroundColor(.secondary)
                
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progressPercentage, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            
            // Tasks
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(page.tasks.enumerated()), id: \.offset) { index, task in
                        TimelineTaskCard(
                            task: task,
                            isAnimated: $taskAnimations[index]
                        )
                        .offset(x: taskAnimations[index] ? 0 : 50)
                        .opacity(taskAnimations[index] ? 1 : 0)
                        .animation(
                            .spring(response: 0.5)
                                .delay(Double(index) * 0.1),
                            value: taskAnimations[index]
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(.ultraThinMaterial)
                .shadow(radius: 20)
        )
        .offset(x: offset)
        .scaleEffect(scale)
        .opacity(opacity)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .onAppear {
            if pageIndex == currentPage {
                animateTasks()
            }
        }
        .onChange(of: currentPage) { oldValue, newValue in
            if newValue == pageIndex {
                animateTasks()
            } else {
                resetAnimations()
            }
        }
    }
    
    var progressPercentage: CGFloat {
        let completed = page.tasks.filter { $0.isComplete }.count
        return CGFloat(completed) / CGFloat(page.tasks.count)
    }
    
    func animateTasks() {
        for index in page.tasks.indices {
            taskAnimations[index] = true
        }
    }
    
    func resetAnimations() {
        taskAnimations = Array(repeating: false, count: 10)
    }
}

struct TimelineTaskCard: View {
    let task: TimelineItem
    @Binding var isAnimated: Bool
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Completion circle
            ZStack {
                Circle()
                    .stroke(task.isComplete ? Color.green : task.urgency.color, lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                if task.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .scaleEffect(isPressed ? 0.8 : 1.0)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isComplete, color: .gray)
                
                if !task.isComplete && task.urgency != .normal {
                    Label(urgencyText, systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundColor(task.urgency.color)
                }
            }
            
            Spacer()
            
            // Action button
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(radius: isPressed ? 2 : 8)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }
    }
    
    var urgencyText: String {
        switch task.urgency {
        case .low: return "When you can"
        case .normal: return "On schedule"
        case .medium: return "Soon"
        case .high: return "Urgent"
        }
    }
}

struct FlowingTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        FlowingTimelineView()
            .background(Color.black)
    }
}