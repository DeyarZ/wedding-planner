import SwiftUI
import SwiftData

struct LuxuryGuestsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRSVP: RSVPStatus? = nil
    @State private var showingAddGuest = false
    @State private var selectedGuest: Guest? = nil
    @State private var animateIn = false

    private var filteredGuests: [Guest] {
        guard let guests = dataManager.wedding?.guests else { return [] }

        let filtered = selectedRSVP == nil
            ? guests
            : guests.filter { $0.rsvpStatus == selectedRSVP }

        return filtered.sorted { $0.fullName < $1.fullName }
    }

    private var rsvpSummary: (confirmed: Int, declined: Int, pending: Int, maybe: Int) {
        guard let guests = dataManager.wedding?.guests else {
            return (0, 0, 0, 0)
        }

        return (
            confirmed: guests.filter { $0.rsvpStatus == .confirmed }.count,
            declined: guests.filter { $0.rsvpStatus == .declined }.count,
            pending: guests.filter { $0.rsvpStatus == .pending }.count,
            maybe: guests.filter { $0.rsvpStatus == .maybe }.count
        )
    }

    var body: some View {
        ZStack {
            Color(hex: "FAFAFA")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                guestsHeader
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : -20)
                    .animation(.easeOut(duration: 0.6), value: animateIn)

                // RSVP Summary
                rsvpSummaryView
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)

                // Filter
                rsvpFilter
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)

                // Guest list
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        if filteredGuests.isEmpty {
                            emptyStateView
                                .padding(.top, 60)
                        } else {
                            ForEach(Array(filteredGuests.enumerated()), id: \.element.id) { index, guest in
                                GuestCard(guest: guest)
                                    .onTapGesture {
                                        selectedGuest = guest
                                    }
                                    .opacity(animateIn ? 1 : 0)
                                    .offset(y: animateIn ? 0 : 20)
                                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05 + 0.3), value: animateIn)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 100)
                }
            }

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                        .padding(.trailing, 32)
                        .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showingAddGuest) {
            AddGuestView(dataManager: dataManager)
        }
        .sheet(item: $selectedGuest) { guest in
            GuestDetailView(guest: guest, dataManager: dataManager)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }

    private var guestsHeader: some View {
        HStack {
            Circle()
                .fill(Color(hex: "FFE4E1").opacity(0.3))
                .frame(width: 6, height: 6)

            Text("GUESTS")
                .font(.system(size: 11, weight: .thin, design: .serif))
                .tracking(4)
                .foregroundColor(Color(hex: "7A7A7A"))

            Spacer()

            Text("\(dataManager.wedding?.guests?.count ?? 0) GUESTS")
                .font(.system(size: 10, weight: .thin))
                .tracking(1)
                .foregroundColor(Color(hex: "B8B8B8"))
        }
    }

    private var rsvpSummaryView: some View {
        let summary = rsvpSummary
        return HStack(spacing: 12) {
            LuxuryRSVPSummaryCard(
                count: summary.confirmed,
                label: "CONFIRMED",
                color: Color(hex: "4CAF50")
            )

            LuxuryRSVPSummaryCard(
                count: summary.maybe,
                label: "MAYBE",
                color: Color(hex: "FF9800")
            )

            LuxuryRSVPSummaryCard(
                count: summary.pending,
                label: "PENDING",
                color: Color(hex: "9B9B9B")
            )

            LuxuryRSVPSummaryCard(
                count: summary.declined,
                label: "DECLINED",
                color: Color(hex: "F44336")
            )
        }
    }

    private var rsvpFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                RSVPFilterChip(
                    title: "ALL",
                    isSelected: selectedRSVP == nil,
                    action: { selectedRSVP = nil }
                )

                ForEach(RSVPStatus.allCases, id: \.self) { status in
                    RSVPFilterChip(
                        title: status.rawValue.uppercased(),
                        isSelected: selectedRSVP == status,
                        color: Color(hex: status.color),
                        action: { selectedRSVP = status }
                    )
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(hex: "E0E0E0"))

            Text("No guests yet")
                .font(.system(size: 16, weight: .thin, design: .serif))
                .foregroundColor(Color(hex: "9B9B9B"))

            Text("Tap + to add your first guest")
                .font(.system(size: 13, weight: .thin))
                .foregroundColor(Color(hex: "C4C4C4"))
        }
    }

    private var addButton: some View {
        Button(action: { showingAddGuest = true }) {
            ZStack {
                Circle()
                    .fill(Color(hex: "2C2C2C"))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white)
            }
        }
    }
}

struct GuestCard: View {
    let guest: Guest
    @State private var isPressed = false

    private var statusColor: Color {
        Color(hex: guest.rsvpStatus.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(guest.fullName)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    if let email = guest.email {
                        Text(email)
                            .font(.system(size: 12, weight: .thin))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(guest.rsvpStatus.text)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.1))
                        )

                    if guest.partySize > 1 {
                        Text("+\(guest.partySize - 1)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                }
            }

            if guest.invitationSent {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 10, weight: .light))
                        Text("Invitation Sent")
                            .font(.system(size: 11, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "4CAF50"))

                    if let deadline = guest.rsvpDeadline {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .light))
                            Text("RSVP by \(deadline, format: .dateTime.month(.abbreviated).day())")
                                .font(.system(size: 11, weight: .thin))
                        }
                        .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, y: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct LuxuryRSVPSummaryCard: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 24, weight: .light, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 9, weight: .regular))
                .tracking(1)
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.05))
        )
    }
}

struct RSVPFilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = Color(hex: "2C2C2C")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .regular))
                .tracking(1.5)
                .foregroundColor(isSelected ? .white : Color(hex: "9B9B9B"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color(hex: "F0F0F0"))
                )
        }
    }
}

// Add Guest View - Simplified for brevity
struct AddGuestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var dataManager: DataManager

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var partySize = 1

    var body: some View {
        NavigationView {
            Form {
                Section("Guest Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                    Stepper("Party Size: \(partySize)", value: $partySize, in: 1...10)
                }
            }
            .navigationTitle("Add Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGuest()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }

    private func saveGuest() {
        let guest = Guest(firstName: firstName, lastName: lastName, partySize: partySize)
        guest.email = email.isEmpty ? nil : email
        guest.phone = phone.isEmpty ? nil : phone
        guest.wedding = dataManager.wedding

        modelContext.insert(guest)
        dataManager.updateWedding()
        dismiss()
    }
}

// Guest Detail View - Simplified
struct GuestDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let guest: Guest
    @ObservedObject var dataManager: DataManager

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(guest.fullName)
                    .font(.title2)

                Text("RSVP: \(guest.rsvpStatus.rawValue)")

                if let email = guest.email {
                    Text(email)
                }

                if let phone = guest.phone {
                    Text(phone)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Guest Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}