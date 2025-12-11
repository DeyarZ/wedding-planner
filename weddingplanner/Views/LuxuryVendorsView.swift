import SwiftUI
import SwiftData

struct LuxuryVendorsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: VendorCategory? = nil
    @State private var showingAddVendor = false
    @State private var selectedVendor: Vendor? = nil
    @State private var animateIn = false

    private var filteredVendors: [Vendor] {
        guard let vendors = dataManager.wedding?.vendors else { return [] }

        let filtered = selectedCategory == nil
            ? vendors
            : vendors.filter { $0.category == selectedCategory }

        return filtered.sorted { v1, v2 in
            if v1.isBooked != v2.isBooked {
                return v1.isBooked
            }
            return v1.name < v2.name
        }
    }

    private var totalVendorsAmount: Double {
        filteredVendors.reduce(0) { $0 + $1.contractAmount }
    }

    private var totalPaidAmount: Double {
        filteredVendors.reduce(0) { $0 + $1.totalPaid }
    }

    var body: some View {
        ZStack {
            Color(hex: "FAFAFA")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                vendorsHeader
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : -20)
                    .animation(.easeOut(duration: 0.6), value: animateIn)

                // Summary cards
                summarySection
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)

                // Category filter
                categoryFilter
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)

                // Vendors list
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        if filteredVendors.isEmpty {
                            emptyStateView
                                .padding(.top, 60)
                        } else {
                            ForEach(Array(filteredVendors.enumerated()), id: \.element.id) { index, vendor in
                                LuxuryVendorCard(vendor: vendor)
                                    .onTapGesture {
                                        selectedVendor = vendor
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
        .sheet(isPresented: $showingAddVendor) {
            AddVendorView(dataManager: dataManager)
        }
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailView(vendor: vendor, dataManager: dataManager)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }

    private var vendorsHeader: some View {
        HStack {
            Circle()
                .fill(Color(hex: "FFDAB9").opacity(0.3))
                .frame(width: 6, height: 6)

            Text("VENDORS")
                .font(.system(size: 11, weight: .thin, design: .serif))
                .tracking(4)
                .foregroundColor(Color(hex: "7A7A7A"))

            Spacer()

            Text("\(filteredVendors.count) VENDORS")
                .font(.system(size: 10, weight: .thin))
                .tracking(1)
                .foregroundColor(Color(hex: "B8B8B8"))
        }
    }

    private var summarySection: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "TOTAL",
                value: formatCurrency(totalVendorsAmount),
                accent: Color(hex: "E8E8F2")
            )

            SummaryCard(
                title: "PAID",
                value: formatCurrency(totalPaidAmount),
                accent: Color(hex: "E8F2E8")
            )

            SummaryCard(
                title: "REMAINING",
                value: formatCurrency(totalVendorsAmount - totalPaidAmount),
                accent: Color(hex: "F2E8E8")
            )
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                VendorCategoryChip(
                    title: "ALL",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(VendorCategory.allCases, id: \.self) { category in
                    VendorCategoryChip(
                        title: category.rawValue.uppercased(),
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
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

            Text("No vendors yet")
                .font(.system(size: 16, weight: .thin, design: .serif))
                .foregroundColor(Color(hex: "9B9B9B"))

            Text("Tap + to add your first vendor")
                .font(.system(size: 13, weight: .thin))
                .foregroundColor(Color(hex: "C4C4C4"))
        }
    }

    private var addButton: some View {
        Button(action: { showingAddVendor = true }) {
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct LuxuryVendorCard: View {
    let vendor: Vendor
    @State private var isPressed = false

    private var statusColor: Color {
        if vendor.isBooked {
            return Color(hex: "4CAF50")
        } else {
            return Color(hex: "FF9800")
        }
    }

    private var paymentProgress: Double {
        guard vendor.contractAmount > 0 else { return 0 }
        return vendor.totalPaid / vendor.contractAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    HStack(spacing: 8) {
                        Image(systemName: vendor.category.icon)
                            .font(.system(size: 11, weight: .light))
                        Text(vendor.category.rawValue)
                            .font(.system(size: 12, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                Spacer()

                // Status indicator
                Text(vendor.isBooked ? "BOOKED" : "PENDING")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.1))
                    )
            }

            // Payment progress
            if vendor.contractAmount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Payment Progress")
                            .font(.system(size: 11, weight: .thin))
                            .foregroundColor(Color(hex: "B8B8B8"))

                        Spacer()

                        Text("\(Int(paymentProgress * 100))%")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "F0F0F0"))
                                .frame(height: 2)

                            Rectangle()
                                .fill(Color(hex: "4CAF50"))
                                .frame(width: geometry.size.width * paymentProgress, height: 2)
                        }
                    }
                    .frame(height: 2)

                    HStack {
                        Text(formatCurrency(vendor.totalPaid))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "4CAF50"))

                        Text("of")
                            .font(.system(size: 11, weight: .thin))
                            .foregroundColor(Color(hex: "B8B8B8"))

                        Text(formatCurrency(vendor.contractAmount))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }
                }
            }

            // Contact info
            if vendor.email != nil, vendor.phone != nil {
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope")
                            .font(.system(size: 10, weight: .light))
                        Text("Email")
                            .font(.system(size: 11, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "9B9B9B"))

                    HStack(spacing: 6) {
                        Image(systemName: "phone")
                            .font(.system(size: 10, weight: .light))
                        Text("Call")
                            .font(.system(size: 11, weight: .thin))
                    }
                    .foregroundColor(Color(hex: "9B9B9B"))
                }
            }
        }
        .padding(20)
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .regular))
                .tracking(1.5)
                .foregroundColor(Color(hex: "9B9B9B"))

            Text(value)
                .font(.system(size: 18, weight: .light, design: .rounded))
                .foregroundColor(Color(hex: "2C2C2C"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(accent.opacity(0.3))
        )
    }
}

struct VendorCategoryChip: View {
    let title: String
    let isSelected: Bool
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
                        .fill(isSelected ? Color(hex: "2C2C2C") : Color(hex: "F0F0F0"))
                )
        }
    }
}

// Add Vendor View
struct AddVendorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var dataManager: DataManager

    @State private var name = ""
    @State private var category: VendorCategory = .venue
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var website = ""
    @State private var contractAmount = ""
    @State private var notes = ""
    @State private var isBooked = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAFA")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Vendor Name
                        FormField(title: "VENDOR NAME", text: $name)

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(VendorCategory.allCases, id: \.self) { cat in
                                        VendorCategoryOption(
                                            category: cat,
                                            isSelected: category == cat,
                                            action: { category = cat }
                                        )
                                    }
                                }
                            }
                        }

                        // Contact Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CONTACT INFORMATION")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            FormField(title: "Contact Name", text: $contactName, isSubfield: true)
                            FormField(title: "Email", text: $email, isSubfield: true, keyboardType: .emailAddress)
                            FormField(title: "Phone", text: $phone, isSubfield: true, keyboardType: .phonePad)
                            FormField(title: "Website", text: $website, isSubfield: true, keyboardType: .URL)
                        }

                        // Contract Amount
                        FormField(title: "CONTRACT AMOUNT", text: $contractAmount, keyboardType: .decimalPad)

                        // Status
                        HStack {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            Spacer()

                            Toggle("", isOn: $isBooked)
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "2C2C2C")))
                                .scaleEffect(0.8)

                            Text(isBooked ? "BOOKED" : "PENDING")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(isBooked ? Color(hex: "4CAF50") : Color(hex: "FF9800"))
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            TextEditor(text: $notes)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .scrollContentBackground(.hidden)
                                .background(Color(hex: "F8F8F8"))
                                .frame(height: 100)
                                .cornerRadius(4)
                        }
                    }
                    .padding(32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVendor()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveVendor() {
        let amount = Double(contractAmount) ?? 0
        let vendor = Vendor(name: name, category: category, contractAmount: amount)
        vendor.contactName = contactName.isEmpty ? nil : contactName
        vendor.email = email.isEmpty ? nil : email
        vendor.phone = phone.isEmpty ? nil : phone
        vendor.website = website.isEmpty ? nil : website
        vendor.notes = notes.isEmpty ? nil : notes
        vendor.isBooked = isBooked
        vendor.wedding = dataManager.wedding

        modelContext.insert(vendor)

        // Create corresponding BudgetItem for this vendor
        let budgetItem = BudgetItem(
            name: vendor.name,
            category: mapVendorCategoryToBudgetCategory(vendor.category),
            estimatedAmount: vendor.contractAmount
        )
        budgetItem.vendor = vendor
        budgetItem.amountSpent = vendor.totalPaid
        budgetItem.wedding = dataManager.wedding
        modelContext.insert(budgetItem)

        dataManager.updateWedding()
        dismiss()
    }

    private func mapVendorCategoryToBudgetCategory(_ vendorCategory: VendorCategory) -> BudgetCategory {
        switch vendorCategory {
        case .venue:
            return .venue
        case .catering:
            return .venue
        case .photography:
            return .photography
        case .videography:
            return .photography
        case .florist:
            return .flowers
        case .music:
            return .entertainment
        case .planner:
            return .other
        case .officiant:
            return .other
        case .transportation:
            return .transportation
        case .cake:
            return .venue
        case .attire:
            return .attire
        case .beauty:
            return .attire
        case .decor:
            return .flowers
        case .other:
            return .other
        }
    }
}

// Vendor Detail View
struct VendorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let vendor: Vendor
    @ObservedObject var dataManager: DataManager

    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingAddPayment = false
    @State private var newPaymentAmount = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAFA")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: vendor.category.icon)
                                .font(.system(size: 40, weight: .ultraLight))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text(vendor.name)
                                .font(.system(size: 24, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Text(vendor.category.rawValue)
                                .font(.system(size: 12, weight: .thin))
                                .tracking(2)
                                .foregroundColor(Color(hex: "9B9B9B"))
                        }

                        // Status
                        HStack {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            Spacer()

                            Text(vendor.isBooked ? "BOOKED" : "PENDING")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1)
                                .foregroundColor(vendor.isBooked ? Color(hex: "4CAF50") : Color(hex: "FF9800"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill((vendor.isBooked ? Color(hex: "4CAF50") : Color(hex: "FF9800")).opacity(0.1))
                                )
                        }

                        // Contact Information
                        if vendor.contactName != nil || vendor.email != nil || vendor.phone != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("CONTACT")
                                    .font(.system(size: 10, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundColor(Color(hex: "9B9B9B"))

                                if let contactName = vendor.contactName {
                                    DetailRow(icon: "person", label: "Contact", value: contactName)
                                }

                                if let email = vendor.email {
                                    DetailRow(icon: "envelope", label: "Email", value: email)
                                }

                                if let phone = vendor.phone {
                                    DetailRow(icon: "phone", label: "Phone", value: phone)
                                }

                                if let website = vendor.website {
                                    DetailRow(icon: "globe", label: "Website", value: website)
                                }
                            }
                        }

                        // Payment Information
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("PAYMENTS")
                                    .font(.system(size: 10, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundColor(Color(hex: "9B9B9B"))

                                Spacer()

                                Button(action: { showingAddPayment = true }) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundColor(Color(hex: "2C2C2C"))
                                }
                            }

                            PaymentProgressView(vendor: vendor)

                            if let payments = vendor.payments, !payments.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(payments.sorted(by: { $0.date > $1.date }), id: \.id) { payment in
                                        PaymentRow(payment: payment)
                                    }
                                }
                            }
                        }

                        // Notes
                        if let notes = vendor.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("NOTES")
                                    .font(.system(size: 10, weight: .regular))
                                    .tracking(1.5)
                                    .foregroundColor(Color(hex: "9B9B9B"))

                                Text(notes)
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Color(hex: "2C2C2C"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Delete button
                        Button(action: { showingDeleteAlert = true }) {
                            Text("Delete Vendor")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "F44336"))
                        }
                        .padding(.top, 20)
                    }
                    .padding(32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2C2C2C"))
                }
            }
        }
        .alert("Delete Vendor", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteVendor()
            }
        } message: {
            Text("Are you sure you want to delete this vendor? This action cannot be undone.")
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(vendor: vendor, dataManager: dataManager)
        }
    }

    private func deleteVendor() {
        modelContext.delete(vendor)
        dataManager.updateWedding()
        dismiss()
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(hex: "9B9B9B"))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(hex: "B8B8B8"))

                Text(value)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "2C2C2C"))
            }

            Spacer()
        }
    }
}

struct PaymentProgressView: View {
    let vendor: Vendor

    private var progress: Double {
        guard vendor.contractAmount > 0 else { return 0 }
        return vendor.totalPaid / vendor.contractAmount
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Paid")
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "B8B8B8"))

                    Text(formatCurrency(vendor.totalPaid))
                        .font(.system(size: 20, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "4CAF50"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "B8B8B8"))

                    Text(formatCurrency(vendor.remainingBalance))
                        .font(.system(size: 20, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "2C2C2C"))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "F0F0F0"))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Color(hex: "4CAF50"))
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)

            Text("\(Int(progress * 100))% of \(formatCurrency(vendor.contractAmount))")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "F8F8F8"))
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct PaymentRow: View {
    let payment: VendorPayment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.date, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "2C2C2C"))

                if let notes = payment.notes {
                    Text(notes)
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }
            }

            Spacer()

            Text(formatCurrency(payment.amount))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4CAF50"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: "F0F0F0"), lineWidth: 0.5)
                )
        )
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// Add Payment View
struct AddPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let vendor: Vendor
    @ObservedObject var dataManager: DataManager

    @State private var amount = ""
    @State private var notes = ""
    @State private var paymentDate = Date()

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFAFA")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        FormField(title: "AMOUNT", text: $amount, keyboardType: .decimalPad)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("PAYMENT DATE")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            DatePicker("", selection: $paymentDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .accentColor(Color(hex: "2C2C2C"))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .regular))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "9B9B9B"))

                            TextEditor(text: $notes)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "2C2C2C"))
                                .scrollContentBackground(.hidden)
                                .background(Color(hex: "F8F8F8"))
                                .frame(height: 100)
                                .cornerRadius(4)
                        }
                    }
                    .padding(32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePayment()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .disabled(amount.isEmpty)
                }
            }
        }
    }

    private func savePayment() {
        guard let paymentAmount = Double(amount) else { return }

        let payment = VendorPayment(amount: paymentAmount, date: paymentDate)
        payment.notes = notes.isEmpty ? nil : notes
        payment.vendor = vendor

        vendor.totalPaid += paymentAmount
        vendor.updatedAt = Date()

        // Sync with BudgetItem if there's a linked one
        if let budgetItems = vendor.wedding?.budgetItems {
            for budgetItem in budgetItems {
                if budgetItem.vendor?.id == vendor.id {
                    budgetItem.amountSpent = vendor.totalPaid
                    budgetItem.isPaid = vendor.totalPaid >= vendor.contractAmount
                    budgetItem.paymentStatus = vendor.totalPaid >= vendor.contractAmount ? .fullyPaid :
                                              vendor.totalPaid > 0 ? .partiallyPaid : .pending
                }
            }
        }

        modelContext.insert(payment)
        dataManager.updateWedding()
        dismiss()
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    var isSubfield: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: isSubfield ? 11 : 10, weight: .regular))
                .tracking(isSubfield ? 0.5 : 1.5)
                .foregroundColor(Color(hex: isSubfield ? "B8B8B8" : "9B9B9B"))

            TextField("", text: $text)
                .font(.system(size: isSubfield ? 14 : 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))
                .keyboardType(keyboardType)
                .padding(.bottom, 8)
                .overlay(
                    Rectangle()
                        .fill(Color(hex: "E0E0E0"))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
        }
    }
}

struct VendorCategoryOption: View {
    let category: VendorCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(isSelected ? Color(hex: "2C2C2C") : Color(hex: "B8B8B8"))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "E8E8E8") : Color(hex: "F8F8F8"))
                    )

                Text(category.rawValue)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isSelected ? Color(hex: "2C2C2C") : Color(hex: "9B9B9B"))
                    .lineLimit(1)
            }
        }
    }
}