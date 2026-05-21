import SwiftUI
import SwiftData
import UIKit
import MessageUI
import Charts
import Singular
import FacebookCore

// MARK: - Main Production Guests View
struct ProductionGuestsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Guest.lastName), SortDescriptor(\Guest.firstName)]) private var guests: [Guest]

    @State private var selectedGuest: Guest? = nil
    @State private var showingAddGuest = false
    @State private var searchText = ""
    @State private var selectedGroup: GuestGroup? = nil
    @State private var selectedRSVPFilter: RSVPStatus? = nil
    @State private var showingAnalytics = false
    @State private var showingExportOptions = false
    @State private var animateIn = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Filtered guests
    var filteredGuests: [Guest] {
        guests.filter { guest in
            let matchesSearch = searchText.isEmpty ||
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                (guest.email ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedGroup == nil || guest.group == selectedGroup
            let matchesRSVP = selectedRSVPFilter == nil || guest.rsvpStatus == selectedRSVPFilter
            return matchesSearch && matchesGroup && matchesRSVP
        }
    }

    // Guest statistics
    var guestStats: GuestStatistics {
        GuestStatistics(
            totalInvited: guests.count,
            totalAttending: guests.filter { $0.rsvpStatus == .confirmed }.reduce(0) { $0 + $1.totalAttending },
            confirmed: guests.filter { $0.rsvpStatus == .confirmed }.count,
            declined: guests.filter { $0.rsvpStatus == .declined }.count,
            pending: guests.filter { $0.rsvpStatus == .pending }.count,
            maybe: guests.filter { $0.rsvpStatus == .maybe }.count,
            adults: guests.reduce(0) { total, guest in
                total + 1 + (guest.plusOnes?.filter { !$0.isChild && $0.isAttending }.count ?? 0)
            },
            children: guests.reduce(0) { total, guest in
                total + (guest.plusOnes?.filter { $0.isChild && $0.isAttending }.count ?? 0)
            }
        )
    }

    // Meal statistics
    var mealStats: [MealChoice: Int] {
        var stats = [MealChoice: Int]()
        for guest in guests where guest.rsvpStatus == .confirmed {
            if let meal = guest.mealChoice {
                stats[meal, default: 0] += 1
            }
            if let plusOnes = guest.plusOnes {
                for plusOne in plusOnes where plusOne.isAttending {
                    if let meal = plusOne.mealChoice {
                        stats[meal, default: 0] += 1
                    }
                }
            }
        }
        return stats
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
                // Header with stats
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
                    )

                // Search and filters
                searchAndFiltersSection
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)

                if guests.isEmpty {
                    EmptyGuestsState {
                        showingAddGuest = true
                        impactFeedback.impactOccurred()
                    }
                    .padding(24)
                } else if filteredGuests.isEmpty {
                    NoGuestResultsState(searchText: searchText)
                        .padding(24)
                } else {
                    // Guest list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(filteredGuests.enumerated()), id: \.element.id) { index, guest in
                                ProductionGuestRow(guest: guest) {
                                    selectedGuest = guest
                                    selectionFeedback.selectionChanged()
                                }
                                .padding(.horizontal, 24)
                                .opacity(animateIn ? 1 : 0)
                                .offset(x: animateIn ? 0 : -20)
                                .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.03), value: animateIn)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }

                // Bottom stats bar
                if !guests.isEmpty {
                    bottomStatsBar
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Color.white
                                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: -6)
                        )
                }
            }
        }
        .sheet(item: $selectedGuest) { guest in
            ProductionGuestDetailView(guest: guest)
        }
        .sheet(isPresented: $showingAddGuest) {
            ProductionAddGuestView { newGuest in
                addGuest(newGuest)
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            ProductionGuestAnalyticsView(stats: guestStats, mealStats: mealStats, guests: guests)
        }
        .sheet(isPresented: $showingExportOptions) {
            ProductionGuestExportView(guests: guests)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            impactFeedback.prepare()
            selectionFeedback.prepare()
            notificationFeedback.prepare()
        }
    }

    // MARK: - Components

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Guest List")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    Text(getMotivationalMessage())
                        .font(.system(size: 14, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        showingAnalytics = true
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "B89B91"))
                    }

                    Button(action: {
                        if dataManager.canAddGuest() {
                            showingAddGuest = true
                            impactFeedback.impactOccurred()
                        } else {
                            dataManager.showPaywallIfNeeded(for: "guest")
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "D4B5A9"))
                    }
                }
            }

            // Quick stats
            HStack(spacing: 16) {
                QuickStat(
                    value: "\(guestStats.totalAttending)",
                    label: "Attending",
                    color: Color(hex: "66BB6A")
                )

                QuickStat(
                    value: "\(guestStats.pending)",
                    label: "Pending",
                    color: Color(hex: "FFA726")
                )

                QuickStat(
                    value: "\(guestStats.declined)",
                    label: "Declined",
                    color: Color(hex: "EF5350")
                )

                QuickStat(
                    value: "\(Int((Double(guestStats.confirmed) / Double(max(guestStats.totalInvited, 1))) * 100))%",
                    label: "Response",
                    color: Color(hex: "42A5F5")
                )
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
        .animation(.easeOut(duration: 0.6), value: animateIn)
    }

    private var searchAndFiltersSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))

                TextField("Search guests...", text: $searchText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "2C2C2C"))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "C4C4C4"))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // RSVP filters
                    GuestFilterChip(
                        label: "All RSVPs",
                        isSelected: selectedRSVPFilter == nil,
                        color: Color(hex: "B89B91")
                    ) {
                        selectedRSVPFilter = nil
                        selectionFeedback.selectionChanged()
                    }

                    ForEach(RSVPStatus.allCases, id: \.self) { status in
                        GuestFilterChip(
                            label: status.rawValue,
                            isSelected: selectedRSVPFilter == status,
                            color: Color(hex: status.color)
                        ) {
                            selectedRSVPFilter = selectedRSVPFilter == status ? nil : status
                            selectionFeedback.selectionChanged()
                        }
                    }

                    Divider()
                        .frame(height: 20)

                    // Group filters
                    GuestFilterChip(
                        label: "All Groups",
                        isSelected: selectedGroup == nil,
                        color: Color(hex: "D4B5A9")
                    ) {
                        selectedGroup = nil
                        selectionFeedback.selectionChanged()
                    }

                    ForEach(GuestGroup.allCases, id: \.self) { group in
                        GuestFilterChip(
                            label: group.rawValue,
                            icon: group.icon,
                            isSelected: selectedGroup == group,
                            color: Color(hex: group.color)
                        ) {
                            selectedGroup = selectedGroup == group ? nil : group
                            selectionFeedback.selectionChanged()
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }

    private var bottomStatsBar: some View {
        HStack(spacing: 20) {
            Button(action: sendReminders) {
                HStack(spacing: 6) {
                    Image(systemName: "bell")
                        .font(.system(size: 12))
                    Text("Send Reminders")
                        .font(.system(size: 12, weight: .regular))
                }
                .foregroundColor(Color(hex: "B89B91"))
            }

            Spacer()

            Text("\(guestStats.totalInvited) invited • \(guestStats.totalAttending) attending")
                .font(.system(size: 12, weight: .thin))
                .foregroundColor(Color(hex: "7A7A7A"))

            Spacer()

            Button(action: {
                showingExportOptions = true
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                    Text("Export")
                        .font(.system(size: 12, weight: .regular))
                }
                .foregroundColor(Color(hex: "B89B91"))
            }
        }
    }

    // MARK: - Helper Methods

    private func getMotivationalMessage() -> String {
        let messages = [
            String(localized: "Every guest is where they belong"),
            String(localized: "One step closer to a perfect day"),
            String(localized: "RSVPs flowing in – your wedding is filling with love"),
            String(localized: "Your people are taken care of"),
            String(localized: "Every name, every detail, in perfect order")
        ]
        return messages.randomElement() ?? messages[0]
    }

    private func addGuest(_ guest: Guest) {
        guest.wedding = dataManager.wedding
        modelContext.insert(guest)

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)

            if !UserDefaults.standard.bool(forKey: "didFireActivationEvent") {
                UserDefaults.standard.set(true, forKey: "didFireActivationEvent")
                Singular.event("sng_activation")
                AppEvents.shared.logEvent(AppEvents.Name("Activation"))
            }
        } catch {
            print("Error adding guest: \(error)")
        }
    }

    private func sendReminders() {
        let pendingGuests = guests.filter { $0.rsvpStatus == .pending && !$0.reminderSent }

        for guest in pendingGuests {
            guest.reminderSent = true
            guest.reminderSentDate = Date()
        }

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error sending reminders: \(error)")
        }
    }
}

// MARK: - Guest Row Component
struct ProductionGuestRow: View {
    let guest: Guest
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Guest initial circle
                ZStack {
                    Circle()
                        .fill(Color(hex: guest.group.color).opacity(0.2))
                        .frame(width: 48, height: 48)

                    Text(getInitials())
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: guest.group.color))
                }

                // Guest info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(guest.fullName)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        if guest.isVIP {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                    }

                    HStack(spacing: 12) {
                        // Group
                        HStack(spacing: 4) {
                            Image(systemName: guest.group.icon)
                                .font(.system(size: 10, weight: .light))
                            Text(guest.group.rawValue)
                                .font(.system(size: 11, weight: .thin))
                        }
                        .foregroundColor(Color(hex: "7A7A7A"))

                        // Party size
                        if guest.totalAttending > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10, weight: .light))
                                Text("+\(guest.totalAttending - 1)")
                                    .font(.system(size: 11, weight: .regular))
                            }
                            .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        // Meal choice
                        if let meal = guest.mealChoice {
                            HStack(spacing: 4) {
                                Image(systemName: meal.icon)
                                    .font(.system(size: 10, weight: .light))
                                Text(meal.rawValue)
                                    .font(.system(size: 11, weight: .thin))
                            }
                            .foregroundColor(Color(hex: "B89B91"))
                        }
                    }
                }

                Spacer()

                // RSVP status
                RSVPBadge(status: guest.rsvpStatus)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
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

    private func getInitials() -> String {
        let firstInitial = guest.firstName.prefix(1).uppercased()
        let lastInitial = guest.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - Supporting Components

struct QuickStat: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .frame(maxWidth: .infinity)
    }
}

struct RSVPBadge: View {
    let status: RSVPStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(hex: status.color))
            )
    }
}

struct GuestFilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .light))
                }
                Text(LocalizedStringKey(label))
                    .font(.system(size: 12, weight: .regular))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "7A7A7A"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(hex: "F0F0F0"))
            )
        }
    }
}

struct EmptyGuestsState: View {
    let onAddGuest: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4B5A9"))

            VStack(spacing: 8) {
                Text("No guests yet")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("Start building your guest list")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            Button(action: onAddGuest) {
                Text("Add First Guest")
                    .font(.system(size: 14, weight: .medium))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoGuestResultsState: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(hex: "C4C4C4"))

            Text("No guests found")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "7A7A7A"))

            if !searchText.isEmpty {
                Text("for \"\(searchText)\"")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Guest Statistics Model
struct GuestStatistics {
    let totalInvited: Int
    let totalAttending: Int
    let confirmed: Int
    let declined: Int
    let pending: Int
    let maybe: Int
    let adults: Int
    let children: Int
}

