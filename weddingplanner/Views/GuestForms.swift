import SwiftUI
import SwiftData
import Charts

// MARK: - Add Guest View
struct ProductionAddGuestView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Guest) -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var group: GuestGroup = .friends
    @State private var mealChoice: MealChoice? = nil
    @State private var dietaryRestrictions = ""
    @State private var allergies = ""
    @State private var notes = ""
    @State private var isVIP = false
    @State private var needsTransportation = false
    @State private var needsAccommodation = false
    @State private var tableNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)

                    Picker("Group", selection: $group) {
                        ForEach(GuestGroup.allCases, id: \.self) { grp in
                            Label(grp.rawValue, systemImage: grp.icon)
                                .tag(grp)
                        }
                    }

                    Toggle("VIP Guest", isOn: $isVIP)
                }

                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Address (optional)", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Meal Preferences") {
                    Picker("Meal Choice", selection: $mealChoice) {
                        Text("Not Selected").tag(nil as MealChoice?)
                        ForEach(MealChoice.allCases, id: \.self) { meal in
                            Label(meal.rawValue, systemImage: meal.icon)
                                .tag(meal as MealChoice?)
                        }
                    }

                    TextField("Dietary Restrictions", text: $dietaryRestrictions)

                    TextField("Allergies (Important!)", text: $allergies)
                        .foregroundColor(allergies.isEmpty ? .primary : .red)
                }

                Section("Special Needs") {
                    Toggle("Needs Transportation", isOn: $needsTransportation)
                    Toggle("Needs Accommodation", isOn: $needsAccommodation)

                    TextField("Table Number (optional)", text: $tableNumber)
                        .keyboardType(.numberPad)
                }

                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Guest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveGuest()
                }
                .disabled(firstName.isEmpty || lastName.isEmpty)
            )
        }
    }

    private func saveGuest() {
        let guest = Guest(
            firstName: firstName,
            lastName: lastName,
            group: group
        )

        guest.email = email.isEmpty ? nil : email
        guest.phone = phone.isEmpty ? nil : phone
        guest.address = address.isEmpty ? nil : address
        guest.mealChoice = mealChoice
        guest.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
        guest.allergies = allergies.isEmpty ? nil : allergies
        guest.notes = notes.isEmpty ? nil : notes
        guest.isVIP = isVIP
        guest.needsTransportation = needsTransportation
        guest.needsAccommodation = needsAccommodation
        guest.tableNumber = tableNumber.isEmpty ? nil : Int(tableNumber)

        onSave(guest)
        dismiss()
    }
}

// MARK: - Edit Guest View
struct ProductionEditGuestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let guest: Guest

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var group: GuestGroup = .friends
    @State private var mealChoice: MealChoice? = nil
    @State private var dietaryRestrictions = ""
    @State private var allergies = ""
    @State private var notes = ""
    @State private var rsvpStatus: RSVPStatus = .pending
    @State private var isVIP = false
    @State private var needsTransportation = false
    @State private var needsAccommodation = false
    @State private var tableNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)

                    Picker("Group", selection: $group) {
                        ForEach(GuestGroup.allCases, id: \.self) { grp in
                            Label(grp.rawValue, systemImage: grp.icon)
                                .tag(grp)
                        }
                    }

                    Toggle("VIP Guest", isOn: $isVIP)
                }

                Section("RSVP Status") {
                    Picker("Status", selection: $rsvpStatus) {
                        ForEach(RSVPStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Address (optional)", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Meal Preferences") {
                    Picker("Meal Choice", selection: $mealChoice) {
                        Text("Not Selected").tag(nil as MealChoice?)
                        ForEach(MealChoice.allCases, id: \.self) { meal in
                            Label(meal.rawValue, systemImage: meal.icon)
                                .tag(meal as MealChoice?)
                        }
                    }

                    TextField("Dietary Restrictions", text: $dietaryRestrictions)

                    TextField("Allergies (Important!)", text: $allergies)
                        .foregroundColor(allergies.isEmpty ? .primary : .red)
                }

                Section("Special Needs") {
                    Toggle("Needs Transportation", isOn: $needsTransportation)
                    Toggle("Needs Accommodation", isOn: $needsAccommodation)

                    TextField("Table Number (optional)", text: $tableNumber)
                        .keyboardType(.numberPad)
                }

                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Guest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(firstName.isEmpty || lastName.isEmpty)
            )
        }
        .onAppear {
            loadGuestData()
        }
    }

    private func loadGuestData() {
        firstName = guest.firstName
        lastName = guest.lastName
        email = guest.email ?? ""
        phone = guest.phone ?? ""
        address = guest.address ?? ""
        group = guest.group
        mealChoice = guest.mealChoice
        dietaryRestrictions = guest.dietaryRestrictions ?? ""
        allergies = guest.allergies ?? ""
        notes = guest.notes ?? ""
        rsvpStatus = guest.rsvpStatus
        isVIP = guest.isVIP
        needsTransportation = guest.needsTransportation
        needsAccommodation = guest.needsAccommodation
        tableNumber = guest.tableNumber != nil ? String(guest.tableNumber!) : ""
    }

    private func saveChanges() {
        guest.firstName = firstName
        guest.lastName = lastName
        guest.email = email.isEmpty ? nil : email
        guest.phone = phone.isEmpty ? nil : phone
        guest.address = address.isEmpty ? nil : address
        guest.group = group
        guest.mealChoice = mealChoice
        guest.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
        guest.allergies = allergies.isEmpty ? nil : allergies
        guest.notes = notes.isEmpty ? nil : notes
        guest.rsvpStatus = rsvpStatus
        guest.isVIP = isVIP
        guest.needsTransportation = needsTransportation
        guest.needsAccommodation = needsAccommodation
        guest.tableNumber = tableNumber.isEmpty ? nil : Int(tableNumber)
        guest.updatedAt = Date()

        if rsvpStatus != .pending && guest.rsvpDate == nil {
            guest.rsvpDate = Date()
        }

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving guest: \(error)")
        }
    }
}

// MARK: - Add Plus One View
struct ProductionAddPlusOneView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let guest: Guest

    @State private var name = ""
    @State private var isChild = false
    @State private var age = ""
    @State private var mealChoice: MealChoice? = nil
    @State private var dietaryRestrictions = ""
    @State private var allergies = ""
    @State private var isAttending = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Plus One Details") {
                    TextField("Name", text: $name)

                    Toggle("Is Child", isOn: $isChild)

                    if isChild {
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                    }

                    Toggle("Will Attend", isOn: $isAttending)
                }

                if isAttending {
                    Section("Meal Preferences") {
                        Picker("Meal Choice", selection: $mealChoice) {
                            Text("Not Selected").tag(nil as MealChoice?)
                            ForEach(MealChoice.allCases, id: \.self) { meal in
                                Label(meal.rawValue, systemImage: meal.icon)
                                    .tag(meal as MealChoice?)
                            }
                        }

                        TextField("Dietary Restrictions", text: $dietaryRestrictions)

                        TextField("Allergies", text: $allergies)
                            .foregroundColor(allergies.isEmpty ? .primary : .red)
                    }
                }
            }
            .navigationTitle("Add Plus One")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    savePlusOne()
                }
                .disabled(name.isEmpty)
            )
        }
    }

    private func savePlusOne() {
        let plusOne = PlusOne(name: name, isChild: isChild, isAttending: isAttending)
        plusOne.age = age.isEmpty ? nil : Int(age)
        plusOne.mealChoice = mealChoice
        plusOne.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
        plusOne.allergies = allergies.isEmpty ? nil : allergies
        plusOne.guest = guest

        modelContext.insert(plusOne)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving plus one: \(error)")
        }
    }
}

// MARK: - Guest Analytics View
struct ProductionGuestAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    let stats: GuestStatistics
    let mealStats: [MealChoice: Int]
    let guests: [Guest]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // RSVP Overview
                    rsvpOverviewSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Guest Breakdown
                    guestBreakdownSection
                        .padding(.horizontal, 24)

                    // Meal Choices Chart
                    if !mealStats.isEmpty {
                        mealChoicesSection
                            .padding(.horizontal, 24)
                    }

                    // Group Distribution
                    groupDistributionSection
                        .padding(.horizontal, 24)

                    // Special Needs Summary
                    specialNeedsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "FDFBF7"),
                        Color(hex: "FBF9F5")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Guest Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() }
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "B89B91"))
            )
        }
    }

    private var rsvpOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RSVP Overview")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            HStack(spacing: 12) {
                StatCard(
                    value: "\(stats.confirmed)",
                    label: "Confirmed",
                    color: Color(hex: "66BB6A")
                )

                StatCard(
                    value: "\(stats.pending)",
                    label: "Pending",
                    color: Color(hex: "FFA726")
                )

                StatCard(
                    value: "\(stats.declined)",
                    label: "Declined",
                    color: Color(hex: "EF5350")
                )

                StatCard(
                    value: "\(stats.maybe)",
                    label: "Maybe",
                    color: Color(hex: "42A5F5")
                )
            }

            // Response rate progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Response Rate")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))

                    Spacer()

                    Text("\(Int((Double(stats.confirmed + stats.declined) / Double(max(stats.totalInvited, 1))) * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2C2C2C"))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E0E0E0"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "66BB6A"))
                            .frame(
                                width: geometry.size.width * (Double(stats.confirmed + stats.declined) / Double(max(stats.totalInvited, 1))),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 8)
        }
    }

    private var guestBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Guest Breakdown")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(stats.totalAttending)")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "B89B91"))

                    Text("Total Attending")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 50)

                VStack(spacing: 8) {
                    Text("\(stats.adults)")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "7A7A7A"))

                    Text("Adults")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    Text("\(stats.children)")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "7A7A7A"))

                    Text("Children")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            )
        }
    }

    private var mealChoicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Choices")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(spacing: 8) {
                ForEach(Array(mealStats.sorted { $0.value > $1.value }), id: \.key) { meal, count in
                    HStack {
                        Image(systemName: meal.icon)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "B89B91"))

                        Text(meal.rawValue)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Spacer()

                        Text("\(count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))
                    }
                    .padding(.vertical, 8)

                    if meal != mealStats.sorted(by: { $0.value > $1.value }).last?.key {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            )
        }
    }

    private var groupDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Group Distribution")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            let groupCounts = Dictionary(grouping: guests, by: { $0.group })
                .mapValues { $0.count }

            VStack(spacing: 12) {
                ForEach(Array(groupCounts.sorted { $0.value > $1.value }), id: \.key) { group, count in
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: group.icon)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: group.color))

                            Text(group.rawValue)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "2C2C2C"))
                        }

                        Spacer()

                        Text("\(count) guests")
                            .font(.system(size: 13, weight: .thin))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            )
        }
    }

    private var specialNeedsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Needs")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            let needsTransport = guests.filter { $0.needsTransportation }.count
            let needsAccommodation = guests.filter { $0.needsAccommodation }.count
            let hasAllergies = guests.filter { $0.allergies != nil && !$0.allergies!.isEmpty }.count

            HStack(spacing: 12) {
                SpecialNeedStat(
                    icon: "car.fill",
                    label: "Transportation",
                    count: needsTransport
                )

                SpecialNeedStat(
                    icon: "bed.double.fill",
                    label: "Accommodation",
                    count: needsAccommodation
                )

                SpecialNeedStat(
                    icon: "exclamationmark.triangle.fill",
                    label: "Allergies",
                    count: hasAllergies
                )
            }
        }
    }
}

// MARK: - Guest Export View
struct ProductionGuestExportView: View {
    @Environment(\.dismiss) private var dismiss
    let guests: [Guest]

    @State private var showingShareSheet = false
    @State private var exportData: Data? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Export Options") {
                    Button(action: exportAsCSV) {
                        Label("Export as CSV", systemImage: "doc.text")
                    }

                    Button(action: exportGuestList) {
                        Label("Export Guest List", systemImage: "list.bullet")
                    }

                    Button(action: exportMealChoices) {
                        Label("Export Meal Choices", systemImage: "fork.knife")
                    }

                    Button(action: exportSeatingPlan) {
                        Label("Export for Seating Plan", systemImage: "tablecells")
                    }
                }

                Section("Summary") {
                    HStack {
                        Text("Total Guests")
                        Spacer()
                        Text("\(guests.count)")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Confirmed")
                        Spacer()
                        Text("\(guests.filter { $0.rsvpStatus == .confirmed }.count)")
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Pending RSVPs")
                        Spacer()
                        Text("\(guests.filter { $0.rsvpStatus == .pending }.count)")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Export Guests")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                GuestShareSheet(items: [data])
            }
        }
    }

    private func exportAsCSV() {
        var csv = "First Name,Last Name,Email,Phone,RSVP Status,Group,Meal Choice,Plus Ones,Table\n"

        for guest in guests {
            csv += "\"\(guest.firstName)\","
            csv += "\"\(guest.lastName)\","
            csv += "\"\(guest.email ?? "")\","
            csv += "\"\(guest.phone ?? "")\","
            csv += "\"\(guest.rsvpStatus.rawValue)\","
            csv += "\"\(guest.group.rawValue)\","
            csv += "\"\(guest.mealChoice?.rawValue ?? "")\","
            csv += "\(guest.totalAttending - 1),"
            csv += "\(guest.tableNumber ?? 0)\n"
        }

        exportData = csv.data(using: .utf8)
        showingShareSheet = true
    }

    private func exportGuestList() {
        var text = "Wedding Guest List\n\n"

        let grouped = Dictionary(grouping: guests, by: { $0.group })

        for (group, groupGuests) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            text += "\(group.rawValue)\n"
            text += String(repeating: "-", count: group.rawValue.count) + "\n"

            for guest in groupGuests.sorted(by: { $0.lastName < $1.lastName }) {
                text += "• \(guest.fullName)"
                if guest.totalAttending > 1 {
                    text += " (+\(guest.totalAttending - 1))"
                }
                text += " - \(guest.rsvpStatus.rawValue)\n"
            }
            text += "\n"
        }

        exportData = text.data(using: .utf8)
        showingShareSheet = true
    }

    private func exportMealChoices() {
        var text = "Meal Choices Summary\n\n"

        let confirmedGuests = guests.filter { $0.rsvpStatus == .confirmed }
        var mealCounts = [MealChoice: Int]()

        for guest in confirmedGuests {
            if let meal = guest.mealChoice {
                mealCounts[meal, default: 0] += 1
            }

            if let plusOnes = guest.plusOnes {
                for plusOne in plusOnes where plusOne.isAttending {
                    if let meal = plusOne.mealChoice {
                        mealCounts[meal, default: 0] += 1
                    }
                }
            }
        }

        for (meal, count) in mealCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            text += "\(meal.rawValue): \(count)\n"
        }

        text += "\n\nDetailed List:\n\n"

        for guest in confirmedGuests {
            text += "\(guest.fullName): \(guest.mealChoice?.rawValue ?? "Not selected")\n"

            if let plusOnes = guest.plusOnes {
                for plusOne in plusOnes where plusOne.isAttending {
                    text += "  - \(plusOne.name): \(plusOne.mealChoice?.rawValue ?? "Not selected")\n"
                }
            }
        }

        exportData = text.data(using: .utf8)
        showingShareSheet = true
    }

    private func exportSeatingPlan() {
        var text = "Seating Plan Export\n\n"

        let guestsWithTables = guests.filter { $0.tableNumber != nil }
            .sorted { ($0.tableNumber ?? 0) < ($1.tableNumber ?? 0) }

        var currentTable = -1

        for guest in guestsWithTables {
            if let table = guest.tableNumber, table != currentTable {
                text += "\nTable \(table)\n"
                text += String(repeating: "-", count: 10) + "\n"
                currentTable = table
            }

            text += "• \(guest.fullName)"
            if let meal = guest.mealChoice {
                text += " (\(meal.rawValue))"
            }
            text += "\n"
        }

        text += "\n\nUnseated Guests:\n"
        for guest in guests.filter({ $0.tableNumber == nil && $0.rsvpStatus == .confirmed }) {
            text += "• \(guest.fullName)\n"
        }

        exportData = text.data(using: .utf8)
        showingShareSheet = true
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct SpecialNeedStat: View {
    let icon: String
    let label: String
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(count > 0 ? Color(hex: "B89B91") : Color(hex: "D0D0D0"))

            Text("\(count)")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(count > 0 ? Color(hex: "2C2C2C") : Color(hex: "D0D0D0"))

            Text(label)
                .font(.system(size: 11, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(count > 0 ? Color(hex: "B89B91").opacity(0.08) : Color(hex: "F8F8F8"))
        )
    }
}

// Share sheet wrapper
struct GuestShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}