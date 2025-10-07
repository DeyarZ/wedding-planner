import SwiftUI
import SwiftData
import Charts
import UIKit

// MARK: - Main Production Funds View
struct ProductionFundsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetItem.name) private var budgetItems: [BudgetItem]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var selectedCategory: BudgetCategory? = nil
    @State private var showingAddExpense = false
    @State private var showingAddTransaction = false
    @State private var selectedBudgetItem: BudgetItem? = nil
    @State private var showingInsights = false
    @State private var animateIn = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Budget calculations
    var totalBudget: Double {
        dataManager.wedding?.totalBudget ?? 0
    }

    var totalSpent: Double {
        budgetItems.reduce(0) { $0 + $1.amountSpent }
    }

    var remaining: Double {
        totalBudget - totalSpent
    }

    var percentageSpent: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }

    var upcomingPayments: [BudgetItem] {
        budgetItems.filter { item in
            if let dueDate = item.paymentDueDate {
                return !item.isPaid && dueDate >= Date() && dueDate <= Date().addingTimeInterval(30 * 24 * 60 * 60)
            }
            return false
        }.sorted { ($0.paymentDueDate ?? Date.distantFuture) < ($1.paymentDueDate ?? Date.distantFuture) }
    }

    var overduePayments: [BudgetItem] {
        budgetItems.filter { $0.isOverdue }
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

            ScrollView {
                VStack(spacing: 24) {
                    // Budget overview hero section
                    budgetOverviewSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // Payment alerts
                    if !overduePayments.isEmpty || !upcomingPayments.isEmpty {
                        paymentAlertsSection
                            .padding(.horizontal, 24)
                    }

                    // Category breakdown
                    categoryBreakdownSection
                        .padding(.horizontal, 24)

                    // Recent transactions
                    recentTransactionsSection
                        .padding(.horizontal, 24)

                    // Quick actions
                    quickActionsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            ProductionAddBudgetItemView { newItem in
                addBudgetItem(newItem)
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            if let item = selectedBudgetItem {
                ProductionAddTransactionView(budgetItem: item)
            }
        }
        .sheet(item: $selectedBudgetItem) { item in
            ProductionBudgetItemDetailView(budgetItem: item)
        }
        .sheet(isPresented: $showingInsights) {
            ProductionBudgetInsightsView(
                budgetItems: budgetItems,
                totalBudget: totalBudget,
                totalSpent: totalSpent
            )
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

    private var budgetOverviewSection: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Budget Overview")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text(getReassurance())
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : -20)
            .animation(.easeOut(duration: 0.6), value: animateIn)

            // Main budget card
            VStack(spacing: 24) {
                // Total budget and spent
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Budget")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))

                        Text(formatCurrency(totalBudget))
                            .font(.system(size: 28, weight: .light, design: .rounded))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Remaining")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))

                        Text(formatCurrency(remaining))
                            .font(.system(size: 28, weight: .light, design: .rounded))
                            .foregroundColor(remaining >= 0 ? Color(hex: "66BB6A") : Color(hex: "FFA726"))
                    }
                }

                // Progress visualization
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Spent")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))

                        Spacer()

                        Text("\(formatCurrency(totalSpent)) (\(Int(percentageSpent))%)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "2C2C2C"))
                    }

                    // Beautiful progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "E8E8E8"))
                                .frame(height: 12)

                            // Progress
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: getProgressGradient(),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: min(geometry.size.width * (percentageSpent / 100), geometry.size.width), height: 12)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentageSpent)
                        }
                    }
                    .frame(height: 12)
                }

                // Quick stats
                HStack(spacing: 16) {
                    BudgetStatCard(
                        icon: "checkmark.circle.fill",
                        value: "\(budgetItems.filter { $0.isPaid }.count)",
                        label: "Paid",
                        color: Color(hex: "66BB6A")
                    )

                    BudgetStatCard(
                        icon: "clock.fill",
                        value: "\(upcomingPayments.count)",
                        label: "Upcoming",
                        color: Color(hex: "FFA726")
                    )

                    BudgetStatCard(
                        icon: "exclamationmark.circle.fill",
                        value: "\(overduePayments.count)",
                        label: "Overdue",
                        color: Color(hex: "EF5350")
                    )

                    BudgetStatCard(
                        icon: "chart.pie.fill",
                        value: "\(budgetItems.count)",
                        label: "Items",
                        color: Color(hex: "42A5F5")
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
            )
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
        }
    }

    private var paymentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Alerts")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            VStack(spacing: 8) {
                // Overdue payments
                ForEach(overduePayments.prefix(2), id: \.id) { item in
                    PaymentAlertRow(
                        item: item,
                        isOverdue: true,
                        onTap: {
                            selectedBudgetItem = item
                            selectionFeedback.selectionChanged()
                        }
                    )
                }

                // Upcoming payments
                ForEach(upcomingPayments.prefix(3), id: \.id) { item in
                    PaymentAlertRow(
                        item: item,
                        isOverdue: false,
                        onTap: {
                            selectedBudgetItem = item
                            selectionFeedback.selectionChanged()
                        }
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category Breakdown")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Button(action: {
                    showingInsights = true
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "B89B91"))
                }
            }

            // Category cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(getCategoryBreakdown(), id: \.category) { breakdown in
                    CategoryCard(
                        breakdown: breakdown,
                        onTap: {
                            selectedCategory = breakdown.category
                            selectionFeedback.selectionChanged()
                        }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(breakdown.index) * 0.05 + 0.3), value: animateIn)
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .light, design: .serif))
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

            if transactions.isEmpty {
                EmptyTransactionsState()
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions.prefix(5), id: \.id) { transaction in
                        BudgetTransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
    }

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            BudgetQuickActionButton(
                icon: "plus.circle.fill",
                label: "Add Expense",
                color: Color(hex: "B89B91")
            ) {
                showingAddExpense = true
                impactFeedback.impactOccurred()
            }

            BudgetQuickActionButton(
                icon: "doc.text.fill",
                label: "Export Report",
                color: Color(hex: "66BB6A")
            ) {
                exportBudgetReport()
            }

            BudgetQuickActionButton(
                icon: "chart.bar.fill",
                label: "View Insights",
                color: Color(hex: "42A5F5")
            ) {
                showingInsights = true
                impactFeedback.impactOccurred()
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
    }

    // MARK: - Helper Methods

    private func getReassurance() -> String {
        if percentageSpent < 50 {
            return "You're well within budget – smooth sailing ahead"
        } else if percentageSpent < 80 {
            return "Your budget is on track – every euro has its place"
        } else if percentageSpent < 100 {
            return "Almost there – you've managed beautifully"
        } else {
            return "Let's review and adjust – we've got this together"
        }
    }

    private func getProgressGradient() -> [Color] {
        if percentageSpent < 60 {
            return [Color(hex: "66BB6A"), Color(hex: "4CAF50")]
        } else if percentageSpent < 85 {
            return [Color(hex: "FFA726"), Color(hex: "FF9800")]
        } else if percentageSpent < 100 {
            return [Color(hex: "FF7043"), Color(hex: "FF5722")]
        } else {
            return [Color(hex: "EF5350"), Color(hex: "F44336")]
        }
    }

    private func getCategoryBreakdown() -> [(category: BudgetCategory, spent: Double, budget: Double, index: Int)] {
        let grouped = Dictionary(grouping: budgetItems, by: { $0.category })
        return grouped.map { (category, items) in
            let spent = items.reduce(0) { $0 + $1.amountSpent }
            let budget = items.reduce(0) { $0 + $1.estimatedAmount }
            return (category: category, spent: spent, budget: budget, index: 0)
        }
        .sorted { $0.budget > $1.budget }
        .enumerated()
        .map { index, item in
            (category: item.category, spent: item.spent, budget: item.budget, index: index)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func addBudgetItem(_ item: BudgetItem) {
        item.wedding = dataManager.wedding
        modelContext.insert(item)

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error adding budget item: \(error)")
        }
    }

    private func exportBudgetReport() {
        // Create budget report export
        notificationFeedback.notificationOccurred(.success)
    }
}

// MARK: - Supporting Components

struct BudgetStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "2C2C2C"))

            Text(label)
                .font(.system(size: 10, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
    }
}

struct PaymentAlertRow: View {
    let item: BudgetItem
    let isOverdue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isOverdue ? Color(hex: "EF5350") : Color(hex: "FFA726"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    if let days = item.daysUntilDue {
                        Text(days < 0 ? "\(abs(days)) days overdue" : "Due in \(days) days")
                            .font(.system(size: 11, weight: .thin))
                            .foregroundColor(isOverdue ? Color(hex: "EF5350") : Color(hex: "7A7A7A"))
                    }
                }

                Spacer()

                Text(formatCurrency(item.outstandingAmount))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "2C2C2C"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOverdue ? Color(hex: "FFEBEE") : Color(hex: "FFF8E1"))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct CategoryCard: View {
    let breakdown: (category: BudgetCategory, spent: Double, budget: Double, index: Int)
    let onTap: () -> Void

    private var percentage: Double {
        guard breakdown.budget > 0 else { return 0 }
        return (breakdown.spent / breakdown.budget) * 100
    }

    private var isOverBudget: Bool {
        breakdown.spent > breakdown.budget
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: breakdown.category.icon)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "B89B91"))

                    Spacer()

                    if isOverBudget {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FFA726"))
                    }
                }

                Text(breakdown.category.rawValue)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(formatCurrency(breakdown.spent))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "2C2C2C"))

                        Spacer()

                        Text("\(Int(percentage))%")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "7A7A7A"))
                    }

                    // Mini progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "E8E8E8"))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(isOverBudget ? Color(hex: "FFA726") : Color(hex: "66BB6A"))
                                .frame(width: min(geometry.size.width * (percentage / 100), geometry.size.width), height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("of \(formatCurrency(breakdown.budget))")
                        .font(.system(size: 10, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct BudgetTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionDescription ?? "Payment")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "2C2C2C"))

                HStack(spacing: 8) {
                    Text(transaction.transactionType.rawValue)
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "7A7A7A"))

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "C4C4C4"))

                    Text(formatDate(transaction.date))
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "7A7A7A"))
                }
            }

            Spacer()

            Text(formatCurrency(transaction.amount))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(transaction.transactionType == .refund ? Color(hex: "66BB6A") : Color(hex: "2C2C2C"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct BudgetQuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 11, weight: .regular))
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
}

struct EmptyTransactionsState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4D4D4"))

            Text("No transactions yet")
                .font(.system(size: 12, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

