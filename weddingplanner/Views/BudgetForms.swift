import SwiftUI
import SwiftData
import Charts

// MARK: - Budget Item Detail View
struct ProductionBudgetItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let budgetItem: BudgetItem

    @State private var showingEditView = false
    @State private var showingAddTransaction = false
    @State private var showingDeleteConfirmation = false
    @State private var animateIn = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    headerCard
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Payment status
                    paymentStatusSection
                        .padding(.horizontal, 24)

                    // Transactions history
                    transactionsSection
                        .padding(.horizontal, 24)

                    // Notes section
                    if let notes = budgetItem.notes, !notes.isEmpty {
                        notesSection
                            .padding(.horizontal, 24)
                    }

                    // Delete button
                    deleteButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "FDFBF7"),
                        Color(hex: "FBF8F4")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() }
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
            EditBudgetItemView(budgetItem: budgetItem)
        }
        .sheet(isPresented: $showingAddTransaction) {
            ProductionAddTransactionView(budgetItem: budgetItem)
        }
        .confirmationDialog("Delete Budget Item", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteBudgetItem()
            }
        } message: {
            Text("Are you sure you want to delete \(budgetItem.name)? This action cannot be undone.")
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: budgetItem.category.icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color(hex: "B89B91"))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color(hex: "B89B91").opacity(0.1))
                    )

                Spacer()

                PaymentStatusBadge(status: budgetItem.paymentStatus)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(budgetItem.name)
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(budgetItem.category.rawValue)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "7A7A7A"))
            }

            // Budget vs Spent
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                        Text(formatCurrency(budgetItem.estimatedAmount))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        Text("Spent")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                        Text(formatCurrency(budgetItem.amountSpent))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(budgetItem.isOverBudget ? Color(hex: "FFA726") : Color(hex: "66BB6A"))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                        Text(formatCurrency(budgetItem.remainingAmount))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(budgetItem.remainingAmount >= 0 ? Color(hex: "2C2C2C") : Color(hex: "EF5350"))
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E8E8E8"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(budgetItem.isOverBudget ? Color(hex: "FFA726") : Color(hex: "66BB6A"))
                            .frame(width: min(geometry.size.width * (budgetItem.percentageSpent / 100), geometry.size.width), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
        )
    }

    private var paymentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Details")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(spacing: 8) {
                if budgetItem.depositAmount > 0 {
                    HStack {
                        Text("Deposit")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                        Spacer()
                        Text(formatCurrency(budgetItem.depositAmount))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "2C2C2C"))
                        if budgetItem.depositPaid {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "66BB6A"))
                        }
                    }
                }

                if let dueDate = budgetItem.paymentDueDate {
                    HStack {
                        Text("Due Date")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                        Spacer()
                        Text(formatDate(dueDate))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(budgetItem.isOverdue ? Color(hex: "EF5350") : Color(hex: "2C2C2C"))
                    }
                }

                if budgetItem.vendor != nil {
                    HStack {
                        Text("Linked Vendor")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                        Spacer()
                        Text(budgetItem.vendor?.name ?? "")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "B89B91"))
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

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transactions")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Button(action: {
                    showingAddTransaction = true
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "B89B91"))
                }
            }

            if let transactions = budgetItem.transactions, !transactions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(transactions.sorted { $0.date > $1.date }, id: \.id) { transaction in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.transactionDescription ?? transaction.transactionType.rawValue)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text(formatDate(transaction.date))
                                    .font(.system(size: 11, weight: .thin))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                            }

                            Spacer()

                            Text(formatCurrency(transaction.amount))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "2C2C2C"))
                        }
                        .padding(.vertical, 6)
                    }
                }
            } else {
                Text("No transactions recorded")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            Text(budgetItem.notes ?? "")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "5A5A5A"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "F8F8F8"))
                )
        }
    }

    private var deleteButton: some View {
        Button(action: {
            showingDeleteConfirmation = true
            impactFeedback.impactOccurred()
        }) {
            Text("Delete Item")
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func deleteBudgetItem() {
        modelContext.delete(budgetItem)

        do {
            try modelContext.save()
            dismiss()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error deleting budget item: \(error)")
        }
    }
}

// MARK: - Add Budget Item View
struct ProductionAddBudgetItemView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (BudgetItem) -> Void

    @State private var name = ""
    @State private var category: BudgetCategory = .venue
    @State private var estimatedAmount = ""
    @State private var depositAmount = ""
    @State private var paymentDueDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var priority: BudgetPriority = .normal
    @State private var notes = ""
    @State private var linkToVendor = false
    @State private var selectedVendor: Vendor? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(BudgetPriority.allCases, id: \.self) { pri in
                            Text(pri.rawValue).tag(pri)
                        }
                    }
                }

                Section("Budget") {
                    TextField("Total Budget", text: $estimatedAmount)
                        .keyboardType(.decimalPad)

                    TextField("Deposit Amount (optional)", text: $depositAmount)
                        .keyboardType(.decimalPad)

                    DatePicker("Payment Due Date", selection: $paymentDueDate, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Budget Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveBudgetItem()
                }
                .disabled(name.isEmpty || estimatedAmount.isEmpty)
            )
        }
    }

    private func saveBudgetItem() {
        let item = BudgetItem(
            name: name,
            category: category,
            estimatedAmount: Double(estimatedAmount) ?? 0
        )

        item.depositAmount = Double(depositAmount) ?? 0
        item.paymentDueDate = paymentDueDate
        item.priority = priority
        item.notes = notes.isEmpty ? nil : notes

        onSave(item)
        dismiss()
    }
}

// MARK: - Edit Budget Item View
struct EditBudgetItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let budgetItem: BudgetItem

    @State private var name = ""
    @State private var category: BudgetCategory = .venue
    @State private var estimatedAmount = ""
    @State private var depositAmount = ""
    @State private var paymentDueDate = Date()
    @State private var priority: BudgetPriority = .normal
    @State private var notes = ""
    @State private var paymentStatus: PaymentStatusType = .pending

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(BudgetPriority.allCases, id: \.self) { pri in
                            Text(pri.rawValue).tag(pri)
                        }
                    }
                }

                Section("Budget & Payment") {
                    TextField("Total Budget", text: $estimatedAmount)
                        .keyboardType(.decimalPad)

                    TextField("Deposit Amount", text: $depositAmount)
                        .keyboardType(.decimalPad)

                    DatePicker("Payment Due Date", selection: $paymentDueDate, displayedComponents: .date)

                    Picker("Payment Status", selection: $paymentStatus) {
                        ForEach(PaymentStatusType.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Current Status") {
                    HStack {
                        Text("Amount Spent")
                        Spacer()
                        Text(formatCurrency(budgetItem.amountSpent))
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text(formatCurrency(budgetItem.remainingAmount))
                            .foregroundColor(budgetItem.remainingAmount >= 0 ? .green : .red)
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Budget Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty || estimatedAmount.isEmpty)
            )
        }
        .onAppear {
            loadBudgetData()
        }
    }

    private func loadBudgetData() {
        name = budgetItem.name
        category = budgetItem.category
        estimatedAmount = String(format: "%.0f", budgetItem.estimatedAmount)
        depositAmount = String(format: "%.0f", budgetItem.depositAmount)
        paymentDueDate = budgetItem.paymentDueDate ?? Date()
        priority = budgetItem.priority
        notes = budgetItem.notes ?? ""
        paymentStatus = budgetItem.paymentStatus
    }

    private func saveChanges() {
        budgetItem.name = name
        budgetItem.category = category
        budgetItem.estimatedAmount = Double(estimatedAmount) ?? 0
        budgetItem.depositAmount = Double(depositAmount) ?? 0
        budgetItem.paymentDueDate = paymentDueDate
        budgetItem.priority = priority
        budgetItem.notes = notes.isEmpty ? nil : notes
        budgetItem.paymentStatus = paymentStatus
        budgetItem.updatedAt = Date()

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving budget item: \(error)")
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Add Transaction View
struct ProductionAddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let budgetItem: BudgetItem

    @State private var amount = ""
    @State private var transactionType: TransactionType = .payment
    @State private var paymentMethod: PaymentMethod = .creditCard
    @State private var description = ""
    @State private var date = Date()
    @State private var referenceNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Payment Method") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }

                    TextField("Reference Number (optional)", text: $referenceNumber)
                }

                Section("Description") {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveTransaction()
                }
                .disabled(amount.isEmpty)
            )
        }
    }

    private func saveTransaction() {
        let transaction = Transaction(
            amount: Double(amount) ?? 0,
            type: transactionType,
            date: date,
            description: description.isEmpty ? nil : description
        )

        transaction.paymentMethod = paymentMethod
        transaction.referenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
        transaction.budgetItem = budgetItem

        // Update budget item spent amount
        budgetItem.amountSpent += transaction.amount

        if transactionType == .deposit {
            budgetItem.depositPaid = true
        } else if transactionType == .finalPayment {
            budgetItem.isPaid = true
            budgetItem.paymentStatus = .fullyPaid
        }

        modelContext.insert(transaction)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving transaction: \(error)")
        }
    }
}

// MARK: - Budget Insights View
struct ProductionBudgetInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    let budgetItems: [BudgetItem]
    let totalBudget: Double
    let totalSpent: Double

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall stats
                    overallStatsSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Category breakdown chart
                    categoryChartSection
                        .padding(.horizontal, 24)

                    // Top expenses
                    topExpensesSection
                        .padding(.horizontal, 24)

                    // Payment timeline
                    paymentTimelineSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "FDFBF7"),
                        Color(hex: "FBF8F4")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Budget Insights")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() }
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "B89B91"))
            )
        }
    }

    private var overallStatsSection: some View {
        VStack(spacing: 16) {
            Text("Financial Overview")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            HStack(spacing: 16) {
                InsightCard(
                    title: "Budget Used",
                    value: "\(Int((totalSpent / max(totalBudget, 1)) * 100))%",
                    subtitle: formatCurrency(totalSpent),
                    color: Color(hex: "B89B91")
                )

                InsightCard(
                    title: "Remaining",
                    value: formatCurrency(totalBudget - totalSpent),
                    subtitle: "\(Int(((totalBudget - totalSpent) / max(totalBudget, 1)) * 100))%",
                    color: Color(hex: "66BB6A")
                )
            }
        }
    }

    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            let categoryData = getCategoryBreakdown()

            VStack(spacing: 12) {
                ForEach(categoryData, id: \.category) { data in
                    CategoryInsightRow(data: data, maxValue: categoryData.first?.spent ?? 1)
                }
            }
        }
    }

    private var topExpensesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Expenses")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            let topItems = budgetItems
                .sorted { $0.estimatedAmount > $1.estimatedAmount }
                .prefix(5)

            VStack(spacing: 8) {
                ForEach(Array(topItems), id: \.id) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Spacer()

                        Text(formatCurrency(item.estimatedAmount))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))
                    }
                    .padding(.vertical, 6)
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

    private var paymentTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Payments")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            let upcomingPayments = budgetItems
                .compactMap { item -> (item: BudgetItem, date: Date)? in
                    guard let date = item.paymentDueDate, !item.isPaid else { return nil }
                    return (item, date)
                }
                .sorted { $0.date < $1.date }
                .prefix(5)

            if upcomingPayments.isEmpty {
                Text("No upcoming payments")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(upcomingPayments), id: \.item.id) { payment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(payment.item.name)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                Text(formatDate(payment.date))
                                    .font(.system(size: 11, weight: .thin))
                                    .foregroundColor(Color(hex: "9B9B9B"))
                            }

                            Spacer()

                            Text(formatCurrency(payment.item.outstandingAmount))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "2C2C2C"))
                        }
                        .padding(.vertical, 6)
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
    }

    private func getCategoryBreakdown() -> [(category: BudgetCategory, spent: Double, budget: Double)] {
        let grouped = Dictionary(grouping: budgetItems, by: { $0.category })
        return grouped.map { (category, items) in
            let spent = items.reduce(0) { $0 + $1.amountSpent }
            let budget = items.reduce(0) { $0 + $1.estimatedAmount }
            return (category: category, spent: spent, budget: budget)
        }
        .sorted { $0.spent > $1.spent }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components

struct PaymentStatusBadge: View {
    let status: PaymentStatusType

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

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "9B9B9B"))

            Text(value)
                .font(.system(size: 24, weight: .light, design: .rounded))
                .foregroundColor(color)

            Text(subtitle)
                .font(.system(size: 11, weight: .thin))
                .foregroundColor(Color(hex: "7A7A7A"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

struct CategoryInsightRow: View {
    let data: (category: BudgetCategory, spent: Double, budget: Double)
    let maxValue: Double

    private var percentage: Double {
        guard data.budget > 0 else { return 0 }
        return (data.spent / data.budget) * 100
    }

    private var barWidth: Double {
        guard maxValue > 0 else { return 0 }
        return data.spent / maxValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: data.category.icon)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "B89B91"))

                Text(data.category.rawValue)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Text(formatCurrency(data.spent))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "7A7A7A"))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "E8E8E8"))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "B89B91"))
                        .frame(width: geometry.size.width * barWidth, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}