import SwiftUI
import SwiftData
import UIKit
import MessageUI

// MARK: - Guest Detail View
struct ProductionGuestDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let guest: Guest

    @State private var showingEditView = false
    @State private var showingAddPlusOne = false
    @State private var showingDeleteConfirmation = false
    @State private var animateIn = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "FDFBF7"),
                        Color(hex: "FBF9F5")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Guest header card
                        guestHeaderCard
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                        // Contact actions
                        if guest.email != nil || guest.phone != nil {
                            contactActionsSection
                                .padding(.horizontal, 24)
                        }

                        // RSVP section
                        rsvpSection
                            .padding(.horizontal, 24)

                        // Meal & dietary section
                        mealSection
                            .padding(.horizontal, 24)

                        // Plus ones section
                        plusOnesSection
                            .padding(.horizontal, 24)

                        // Special needs section
                        specialNeedsSection
                            .padding(.horizontal, 24)

                        // Notes section
                        if let notes = guest.notes, !notes.isEmpty {
                            notesSection
                                .padding(.horizontal, 24)
                        }

                        // Invitation history
                        invitationHistorySection
                            .padding(.horizontal, 24)

                        // Delete button
                        deleteButton
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91")),
                trailing: Button("Edit") {
                    showingEditView = true
                    impactFeedback.impactOccurred()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91"))
            )
        }
        .sheet(isPresented: $showingEditView) {
            ProductionEditGuestView(guest: guest)
        }
        .sheet(isPresented: $showingAddPlusOne) {
            ProductionAddPlusOneView(guest: guest)
        }
        .confirmationDialog("Delete Guest", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteGuest()
            }
        } message: {
            Text("Are you sure you want to delete \(guest.fullName)? This action cannot be undone.")
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            impactFeedback.prepare()
            notificationFeedback.prepare()
        }
    }

    // MARK: - Components

    private var guestHeaderCard: some View {
        VStack(spacing: 16) {
            // Guest avatar and group
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: guest.group.color).opacity(0.2))
                        .frame(width: 80, height: 80)

                    Text(getInitials())
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: guest.group.color))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    RSVPBadge(status: guest.rsvpStatus)

                    if guest.isVIP {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("VIP")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FFD700"))
                    }
                }
            }

            // Name and details
            VStack(alignment: .leading, spacing: 8) {
                Text(guest.fullName)
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: guest.group.icon)
                            .font(.system(size: 12, weight: .light))
                        Text(guest.group.rawValue)
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundColor(Color(hex: "7A7A7A"))

                    if guest.totalAttending > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12, weight: .light))
                            Text("\(guest.totalAttending) attending")
                                .font(.system(size: 13, weight: .regular))
                        }
                        .foregroundColor(Color(hex: "7A7A7A"))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.6), value: animateIn)
    }

    private var contactActionsSection: some View {
        HStack(spacing: 12) {
            if let phone = guest.phone {
                GuestContactActionCard(
                    icon: "phone.fill",
                    label: "Call",
                    color: Color(hex: "66BB6A")
                ) {
                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let email = guest.email {
                GuestContactActionCard(
                    icon: "envelope.fill",
                    label: "Email",
                    color: Color(hex: "42A5F5")
                ) {
                    if let url = URL(string: "mailto:\(email)") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let phone = guest.phone {
                GuestContactActionCard(
                    icon: "message.fill",
                    label: "Message",
                    color: Color(hex: "B89B91")
                ) {
                    if let url = URL(string: "sms://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            GuestContactActionCard(
                icon: "bell.fill",
                label: "Remind",
                color: Color(hex: "FFA726")
            ) {
                sendReminder()
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }

    private var rsvpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RSVP Status")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(spacing: 8) {
                HStack {
                    Text("Status")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))
                    Spacer()
                    RSVPBadge(status: guest.rsvpStatus)
                }

                if let rsvpDate = guest.rsvpDate {
                    HStack {
                        Text("Response Date")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                        Spacer()
                        Text(formatDate(rsvpDate))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                }

                if let deadline = guest.rsvpDeadline {
                    HStack {
                        Text("Deadline")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                        Spacer()
                        Text(formatDate(deadline))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(isOverdue(deadline) ? Color(hex: "EF5350") : Color(hex: "2C2C2C"))
                    }
                }

                // Quick RSVP update buttons
                if guest.rsvpStatus == .pending {
                    HStack(spacing: 8) {
                        Button(action: { updateRSVP(.confirmed) }) {
                            Text("Confirm")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "66BB6A"))
                                )
                        }

                        Button(action: { updateRSVP(.maybe) }) {
                            Text("Maybe")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "FFA726"))
                                )
                        }

                        Button(action: { updateRSVP(.declined) }) {
                            Text("Decline")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "EF5350"))
                                )
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            )
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
    }

    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal & Dietary Preferences")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(alignment: .leading, spacing: 8) {
                if let meal = guest.mealChoice {
                    HStack {
                        Image(systemName: meal.icon)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "B89B91"))
                        Text(meal.rawValue)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                        Spacer()
                    }
                } else {
                    Text("No meal choice selected")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }

                if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dietary Restrictions")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))
                        Text(dietary)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                }

                if let allergies = guest.allergies, !allergies.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "EF5350"))
                            Text("Allergies")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "EF5350"))
                        }
                        Text(allergies)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "FFEBEE"))
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            )
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
    }

    private var plusOnesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Plus Ones (\(guest.plusOnes?.count ?? 0))")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Button(action: {
                    showingAddPlusOne = true
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "D4B5A9"))
                }
            }

            if let plusOnes = guest.plusOnes, !plusOnes.isEmpty {
                VStack(spacing: 8) {
                    ForEach(plusOnes, id: \.id) { plusOne in
                        GuestPlusOneRow(plusOne: plusOne, onDelete: {
                            deletePlusOne(plusOne)
                        })
                    }
                }
            } else {
                Text("No plus ones added")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
    }

    private var specialNeedsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Needs")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            HStack(spacing: 20) {
                GuestSpecialNeedCard(
                    icon: "car.fill",
                    label: "Transportation",
                    isActive: guest.needsTransportation
                )

                GuestSpecialNeedCard(
                    icon: "bed.double.fill",
                    label: "Accommodation",
                    isActive: guest.needsAccommodation
                )

                if let table = guest.tableNumber {
                    GuestSpecialNeedCard(
                        icon: "tablecells.fill",
                        label: "Table \(table)",
                        isActive: true
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            Text(guest.notes ?? "")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "5A5A5A"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "F8F8F8"))
                )
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateIn)
    }

    private var invitationHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invitation History")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(alignment: .leading, spacing: 8) {
                if guest.invitationSent {
                    HStack {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "66BB6A"))

                        Text("Invitation sent")
                            .font(.system(size: 13, weight: .regular))

                        if let date = guest.invitationSentDate {
                            Text("• \(formatDate(date))")
                                .font(.system(size: 12, weight: .thin))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        Spacer()
                    }
                }

                if guest.invitationViewed {
                    HStack {
                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "42A5F5"))

                        Text("Invitation viewed")
                            .font(.system(size: 13, weight: .regular))

                        if let date = guest.invitationViewedDate {
                            Text("• \(formatDate(date))")
                                .font(.system(size: 12, weight: .thin))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        Spacer()
                    }
                }

                if guest.reminderSent {
                    HStack {
                        Image(systemName: "bell.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "FFA726"))

                        Text("Reminder sent")
                            .font(.system(size: 13, weight: .regular))

                        if let date = guest.reminderSentDate {
                            Text("• \(formatDate(date))")
                                .font(.system(size: 12, weight: .thin))
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        Spacer()
                    }
                }

                if !guest.invitationSent {
                    Button(action: sendInvitation) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12))
                            Text("Send Invitation")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "B89B91"))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .stroke(Color(hex: "B89B91"), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.7), value: animateIn)
    }

    private var deleteButton: some View {
        Button(action: {
            showingDeleteConfirmation = true
            impactFeedback.impactOccurred()
        }) {
            Text("Delete Guest")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "EF5350"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "EF5350"), lineWidth: 1)
                )
        }
    }

    // MARK: - Helper Methods

    private func getInitials() -> String {
        let firstInitial = guest.firstName.prefix(1).uppercased()
        let lastInitial = guest.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && guest.rsvpStatus == .pending
    }

    private func updateRSVP(_ status: RSVPStatus) {
        guest.rsvpStatus = status
        guest.rsvpDate = Date()
        guest.updatedAt = Date()

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error updating RSVP: \(error)")
        }
    }

    private func sendInvitation() {
        guest.invitationSent = true
        guest.invitationSentDate = Date()
        guest.rsvpDeadline = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error sending invitation: \(error)")
        }
    }

    private func sendReminder() {
        guest.reminderSent = true
        guest.reminderSentDate = Date()

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error sending reminder: \(error)")
        }
    }

    private func deletePlusOne(_ plusOne: PlusOne) {
        modelContext.delete(plusOne)

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.warning)
        } catch {
            print("Error deleting plus one: \(error)")
        }
    }

    private func deleteGuest() {
        modelContext.delete(guest)

        do {
            try modelContext.save()
            dismiss()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error deleting guest: \(error)")
        }
    }
}

// MARK: - Supporting Components

struct GuestContactActionCard: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(color)
                    )

                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "7A7A7A"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct GuestPlusOneRow: View {
    let plusOne: PlusOne
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: plusOne.isChild ? "person.fill" : "person.2.fill")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91"))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(plusOne.name)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    if plusOne.isChild {
                        Text("(Child)")
                            .font(.system(size: 11, weight: .thin))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }

                if let meal = plusOne.mealChoice {
                    Text(meal.rawValue)
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "7A7A7A"))
                }
            }

            Spacer()

            if plusOne.isAttending {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "66BB6A"))
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "EF5350"))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
        )
    }
}

struct GuestSpecialNeedCard: View {
    let icon: String
    let label: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(isActive ? Color(hex: "B89B91") : Color(hex: "D0D0D0"))

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(isActive ? Color(hex: "7A7A7A") : Color(hex: "D0D0D0"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color(hex: "B89B91").opacity(0.1) : Color(hex: "F8F8F8"))
        )
    }
}