import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

// MARK: - Production Wedding Day Schedule View
struct ProductionWeddingDayScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var dataManager: DataManager

    @State private var scheduleEvents: [DayScheduleEvent] = []
    @State private var editingEvent: DayScheduleEvent? = nil
    @State private var showingAddEvent = false
    @State private var draggedEvent: DayScheduleEvent? = nil
    @State private var showingShareSheet = false
    @State private var pdfData: Data? = nil
    @State private var animateIn = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "FDFBF7"),
                        Color(hex: "FAF8F3")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "heart.circle")
                                .font(.system(size: 40, weight: .ultraLight))
                                .foregroundColor(Color(hex: "E8C4B8"))
                                .scaleEffect(animateIn ? 1 : 0.5)
                                .opacity(animateIn ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateIn)

                            Text("Your Perfect Day")
                                .font(.system(size: 28, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .opacity(animateIn ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)

                            Text("Every moment planned with love")
                                .font(.system(size: 14, weight: .thin))
                                .foregroundColor(Color(hex: "9B9B9B"))
                                .opacity(animateIn ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)

                            // Timeline summary
                            if !scheduleEvents.isEmpty {
                                TimelineSummary(events: scheduleEvents)
                                    .padding(.top, 12)
                                    .opacity(animateIn ? 1 : 0)
                                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

                        // Timeline
                        if scheduleEvents.isEmpty {
                            EmptyScheduleState {
                                loadDefaultSchedule()
                                impactFeedback.impactOccurred()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(scheduleEvents.enumerated()), id: \.element.id) { index, event in
                                    DraggableEventRow(
                                        event: event,
                                        index: index,
                                        totalEvents: scheduleEvents.count,
                                        onEdit: { editingEvent = event },
                                        onDelete: { deleteEvent(event) },
                                        onDrag: { draggedEvent = event },
                                        onDrop: { targetEvent in
                                            moveEvent(draggedEvent, to: targetEvent)
                                        }
                                    )
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05 + 0.5), value: animateIn)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Add event button
                        Button(action: {
                            showingAddEvent = true
                            impactFeedback.impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .light))
                                Text("Add Event")
                                    .font(.system(size: 14, weight: .regular, design: .serif))
                            }
                            .foregroundColor(Color(hex: "B89B91"))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                Capsule()
                                    .stroke(Color(hex: "B89B91"), lineWidth: 1)
                                    .background(Capsule().fill(Color(hex: "B89B91").opacity(0.05)))
                            )
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Wedding Day Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91")),
                trailing: Menu {
                    Button(action: exportPDF) {
                        Label("Export PDF", systemImage: "doc.fill")
                    }

                    Button(action: shareSchedule) {
                        Label("Share Schedule", systemImage: "square.and.arrow.up")
                    }

                    Button(action: shareWithVendors) {
                        Label("Send to Vendors", systemImage: "paperplane")
                    }

                    Divider()

                    Button(action: loadDefaultSchedule) {
                        Label("Reset to Default", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "B89B91"))
                }
            )
        }
        .sheet(item: $editingEvent) { event in
            EditScheduleEventView(event: event, onSave: { _ in updateEvent(event) })
        }
        .sheet(isPresented: $showingAddEvent) {
            AddScheduleEventView(onSave: { newEvent in
                addEvent(newEvent)
            })
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(items: [pdfData])
            }
        }
        .onAppear {
            loadScheduleEvents()
            withAnimation {
                animateIn = true
            }
            impactFeedback.prepare()
            notificationFeedback.prepare()
        }
    }

    // MARK: - Data Management
    private func loadScheduleEvents() {
        if let events = dataManager.wedding?.scheduleEvents {
            scheduleEvents = events.sorted { $0.sortOrder < $1.sortOrder }
        } else {
            // Create default schedule if none exists
            loadDefaultSchedule()
        }
    }

    private func loadDefaultSchedule() {
        guard let wedding = dataManager.wedding else { return }

        // Remove existing events
        if let existingEvents = wedding.scheduleEvents {
            for event in existingEvents {
                modelContext.delete(event)
            }
        }

        // Add default events
        let calendar = Calendar.current
        let weddingDate = wedding.date
        var sortOrder = 0

        func timeOn(hour: Int, minute: Int) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: weddingDate)
            components.hour = hour
            components.minute = minute
            return calendar.date(from: components) ?? Date()
        }

        let defaultEvents = [
            (title: "Hair & Makeup Begins", hour: 8, minute: 0, duration: 120, category: EventCategory.preparation, location: "Bridal Suite", notes: "Bride and bridesmaids"),
            (title: "Photographer Arrives", hour: 9, minute: 30, duration: 30, category: EventCategory.photography, location: "Bridal Suite", notes: "Getting ready photos"),
            (title: "Getting Dressed", hour: 10, minute: 0, duration: 60, category: EventCategory.preparation, location: "Bridal Suite", notes: "Final touches"),
            (title: "First Look & Couple Photos", hour: 11, minute: 30, duration: 45, category: EventCategory.photography, location: "Garden", notes: "Private moment"),
            (title: "Wedding Party Photos", hour: 12, minute: 15, duration: 45, category: EventCategory.photography, location: "Various Locations", notes: nil),
            (title: "Guest Arrival", hour: 13, minute: 0, duration: 30, category: EventCategory.ceremony, location: "Ceremony Space", notes: "Welcome drinks available"),
            (title: "Ceremony Begins", hour: 13, minute: 30, duration: 30, category: EventCategory.ceremony, location: "Main Hall", notes: nil),
            (title: "Cocktail Hour", hour: 14, minute: 0, duration: 90, category: EventCategory.food, location: "Terrace", notes: "Canapés and drinks"),
            (title: "Reception Entrance", hour: 15, minute: 30, duration: 15, category: EventCategory.reception, location: "Ballroom", notes: "Grand entrance"),
            (title: "Dinner Service", hour: 16, minute: 0, duration: 90, category: EventCategory.food, location: "Ballroom", notes: "3-course meal"),
            (title: "Speeches & Toasts", hour: 17, minute: 30, duration: 30, category: EventCategory.reception, location: "Ballroom", notes: nil),
            (title: "First Dance", hour: 18, minute: 0, duration: 10, category: EventCategory.entertainment, location: "Dance Floor", notes: "Special song"),
            (title: "Parent Dances", hour: 18, minute: 10, duration: 10, category: EventCategory.entertainment, location: "Dance Floor", notes: nil),
            (title: "Party & Dancing", hour: 18, minute: 30, duration: 150, category: EventCategory.entertainment, location: "Dance Floor", notes: "DJ/Band plays"),
            (title: "Cake Cutting", hour: 21, minute: 0, duration: 15, category: EventCategory.reception, location: "Ballroom", notes: nil),
            (title: "Last Dance & Send-off", hour: 22, minute: 0, duration: 15, category: EventCategory.ceremony, location: "Main Entrance", notes: "Sparkler exit")
        ]

        for eventData in defaultEvents {
            let event = DayScheduleEvent(
                title: eventData.title,
                startTime: timeOn(hour: eventData.hour, minute: eventData.minute),
                duration: eventData.duration,
                category: eventData.category,
                sortOrder: sortOrder
            )
            event.location = eventData.location
            event.notes = eventData.notes
            event.wedding = wedding
            modelContext.insert(event)
            sortOrder += 1
        }

        do {
            try modelContext.save()
            loadScheduleEvents()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error saving default schedule: \(error)")
        }
    }

    private func addEvent(_ event: DayScheduleEvent) {
        event.wedding = dataManager.wedding
        event.sortOrder = scheduleEvents.count
        modelContext.insert(event)

        do {
            try modelContext.save()
            loadScheduleEvents()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error adding event: \(error)")
        }
    }

    private func updateEvent(_ event: DayScheduleEvent) {
        event.updatedAt = Date()

        do {
            try modelContext.save()
            loadScheduleEvents()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error updating event: \(error)")
        }
    }

    private func deleteEvent(_ event: DayScheduleEvent) {
        modelContext.delete(event)

        do {
            try modelContext.save()
            loadScheduleEvents()
            notificationFeedback.notificationOccurred(.warning)
        } catch {
            print("Error deleting event: \(error)")
        }
    }

    private func moveEvent(_ source: DayScheduleEvent?, to target: DayScheduleEvent) {
        guard let source = source, source.id != target.id else { return }

        let sourceIndex = scheduleEvents.firstIndex(where: { $0.id == source.id }) ?? 0
        let targetIndex = scheduleEvents.firstIndex(where: { $0.id == target.id }) ?? 0

        // Reorder in array
        scheduleEvents.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex)

        // Update sort orders
        for (index, event) in scheduleEvents.enumerated() {
            event.sortOrder = index
        }

        do {
            try modelContext.save()
            impactFeedback.impactOccurred()
        } catch {
            print("Error reordering events: \(error)")
        }
    }

    // MARK: - Export Functions
    private func exportPDF() {
        // Create PDF from schedule
        let pdfMetaData = [
            kCGPDFContextCreator: "Wedding Planner",
            kCGPDFContextAuthor: dataManager.wedding?.coupleNames ?? "Wedding",
            kCGPDFContextTitle: "Wedding Day Schedule"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .light),
                .foregroundColor: UIColor(hex: "2C2C2C")
            ]
            let title = "Wedding Day Schedule"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)

            // Couple names and date
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor(hex: "7A7A7A")
            ]
            let subtitle = "\(dataManager.wedding?.coupleNames ?? "") • \(formatDate(dataManager.wedding?.date ?? Date()))"
            subtitle.draw(at: CGPoint(x: 50, y: 85), withAttributes: subtitleAttributes)

            // Events
            var yPosition: CGFloat = 140

            let eventAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor(hex: "2C2C2C")
            ]

            for event in scheduleEvents {
                let timeText = event.timeRange
                let eventText = "\(timeText) - \(event.title)"
                eventText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: eventAttributes)

                if let location = event.location {
                    let locationAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .light),
                        .foregroundColor: UIColor(hex: "9B9B9B")
                    ]
                    location.draw(at: CGPoint(x: 200, y: yPosition + 2), withAttributes: locationAttributes)
                }

                yPosition += 25

                // Start new page if needed
                if yPosition > 700 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }

        self.pdfData = data
        showingShareSheet = true
    }

    private func shareSchedule() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long

        var scheduleText = "Wedding Day Schedule\n"
        scheduleText += "\(dataManager.wedding?.coupleNames ?? "")\n"
        scheduleText += "\(formatter.string(from: dataManager.wedding?.date ?? Date()))\n\n"

        for event in scheduleEvents {
            scheduleText += "\(event.timeRange)\n"
            scheduleText += "\(event.title)\n"
            if let location = event.location {
                scheduleText += "📍 \(location)\n"
            }
            if let notes = event.notes {
                scheduleText += "Notes: \(notes)\n"
            }
            scheduleText += "\n"
        }

        pdfData = scheduleText.data(using: .utf8)
        showingShareSheet = true
    }

    private func shareWithVendors() {
        // Create a formatted message for vendors
        var message = "Hi! Here's our wedding day schedule:\n\n"
        message += "Date: \(formatDate(dataManager.wedding?.date ?? Date()))\n\n"

        for event in scheduleEvents {
            message += "⏰ \(event.timeRange): \(event.title)"
            if let location = event.location {
                message += " - \(location)"
            }
            message += "\n"
        }

        message += "\nPlease let us know if you have any questions!"

        pdfData = message.data(using: .utf8)
        showingShareSheet = true
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct TimelineSummary: View {
    let events: [DayScheduleEvent]

    private var startTime: String {
        guard let first = events.first else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: first.startTime)
    }

    private var endTime: String {
        guard let last = events.last else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: last.endTime)
    }

    private var totalDuration: String {
        guard let first = events.first, let last = events.last else { return "" }
        let duration = last.endTime.timeIntervalSince(first.startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(startTime)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "2C2C2C"))
                Text("Start")
                    .font(.system(size: 10, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            VStack(spacing: 4) {
                Text(totalDuration)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "B89B91"))
                Text("Duration")
                    .font(.system(size: 10, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            VStack(spacing: 4) {
                Text(endTime)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "2C2C2C"))
                Text("End")
                    .font(.system(size: 10, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
        )
    }
}

struct DraggableEventRow: View {
    let event: DayScheduleEvent
    let index: Int
    let totalEvents: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDrag: () -> Void
    let onDrop: (DayScheduleEvent) -> Void

    @State private var isExpanded = false
    @State private var isDragging = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.startTime)
    }

    private var endTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.endTime)
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

                Text("\(event.duration)m")
                    .font(.system(size: 10, weight: .thin))
                    .foregroundColor(Color(hex: "C4C4C4"))
            }
            .frame(width: 60)

            // Timeline line with continuous connection
            ZStack {
                // Continuous line
                Rectangle()
                    .fill(Color(hex: event.category.color).opacity(0.3))
                    .frame(width: 2)

                // Event dot
                Circle()
                    .fill(Color(hex: event.category.color))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                    )
            }
            .frame(width: 12)

            // Event details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        HStack(spacing: 12) {
                            if let location = event.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                        .font(.system(size: 10, weight: .light))
                                    Text(location)
                                        .font(.system(size: 12, weight: .thin))
                                }
                                .foregroundColor(Color(hex: "9B9B9B"))
                            }

                            HStack(spacing: 4) {
                                Image(systemName: event.category.icon)
                                    .font(.system(size: 10, weight: .light))
                                Text(event.category.rawValue)
                                    .font(.system(size: 11, weight: .thin))
                            }
                            .foregroundColor(Color(hex: event.category.color))
                        }
                    }

                    Spacer()

                    // Drag handle
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "D0D0D0"))
                        .scaleEffect(isDragging ? 1.2 : 1)
                        .animation(.spring(response: 0.3), value: isDragging)
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        if let notes = event.notes {
                            Text(notes)
                                .font(.system(size: 12, weight: .thin))
                                .foregroundColor(Color(hex: "7A7A7A"))
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            Button(action: {
                                onEdit()
                                impactFeedback.impactOccurred()
                            }) {
                                Label("Edit", systemImage: "pencil")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "B89B91"))
                            }

                            Button(action: {
                                onDelete()
                                impactFeedback.impactOccurred()
                            }) {
                                Label("Delete", systemImage: "trash")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "F44336"))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.bottom, index == totalEvents - 1 ? 20 : 30)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
                impactFeedback.impactOccurred()
            }
        }
        .onDrag {
            isDragging = true
            onDrag()
            return NSItemProvider(object: event.id.uuidString as NSString)
        }
        .onDrop(of: [UTType.text], delegate: EventDropDelegate(
            event: event,
            onDrop: onDrop,
            isDragging: $isDragging
        ))
    }
}

struct EventDropDelegate: DropDelegate {
    let event: DayScheduleEvent
    let onDrop: (DayScheduleEvent) -> Void
    @Binding var isDragging: Bool

    func performDrop(info: DropInfo) -> Bool {
        isDragging = false
        return true
    }

    func dropEntered(info: DropInfo) {
        onDrop(event)
    }

    func dropExited(info: DropInfo) {
        isDragging = false
    }
}

struct EmptyScheduleState: View {
    let onLoadDefault: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.day.timeline.left")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4B5A9"))

            Text("No schedule created yet")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            Text("Start with our suggested timeline")
                .font(.system(size: 13, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))

            Button(action: onLoadDefault) {
                Text("Load Suggested Schedule")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
        )
    }
}

// MARK: - Add/Edit Event Views

struct AddScheduleEventView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (DayScheduleEvent) -> Void

    @State private var title = ""
    @State private var startTime = Date()
    @State private var duration = 60
    @State private var location = ""
    @State private var notes = ""
    @State private var category: EventCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)

                    Picker("Duration", selection: $duration) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                        Text("4 hours").tag(240)
                    }
                }

                Section("Location & Notes") {
                    TextField("Location", text: $location)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let event = DayScheduleEvent(
                        title: title,
                        startTime: startTime,
                        duration: duration,
                        category: category
                    )
                    event.location = location.isEmpty ? nil : location
                    event.notes = notes.isEmpty ? nil : notes
                    onSave(event)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

struct EditScheduleEventView: View {
    @Environment(\.dismiss) private var dismiss
    let event: DayScheduleEvent
    let onSave: (DayScheduleEvent) -> Void

    @State private var title = ""
    @State private var startTime = Date()
    @State private var duration = 60
    @State private var location = ""
    @State private var notes = ""
    @State private var category: EventCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)

                    Picker("Duration", selection: $duration) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                        Text("4 hours").tag(240)
                    }
                }

                Section("Location & Notes") {
                    TextField("Location", text: $location)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    event.title = title
                    event.startTime = startTime
                    event.duration = duration
                    event.location = location.isEmpty ? nil : location
                    event.notes = notes.isEmpty ? nil : notes
                    event.category = category
                    onSave(event)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
        .onAppear {
            title = event.title
            startTime = event.startTime
            duration = event.duration
            location = event.location ?? ""
            notes = event.notes ?? ""
            category = event.category
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}