import SwiftUI
import SwiftData
import UIKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Main Production Team View
struct ProductionTeamView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vendor.name) private var vendors: [Vendor]

    @State private var selectedVendor: Vendor? = nil
    @State private var showingAddVendor = false
    @State private var searchText = ""
    @State private var selectedCategory: VendorCategory? = nil
    @State private var animateIn = false
    @State private var showingExportOptions = false
    @State private var activeGate: PremiumGate? = nil

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // Filtered vendors based on search and category
    var filteredVendors: [Vendor] {
        vendors.filter { vendor in
            let matchesSearch = searchText.isEmpty ||
                vendor.name.localizedCaseInsensitiveContains(searchText) ||
                (vendor.contactName ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || vendor.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    // Vendor statistics
    var bookedCount: Int {
        vendors.filter { $0.status == .booked || $0.status == .confirmed }.count
    }

    var totalVendors: Int {
        vendors.count
    }

    var totalSpent: Double {
        vendors.reduce(0) { $0 + $1.totalPaid }
    }

    var totalBudget: Double {
        vendors.reduce(0) { $0 + $1.contractAmount }
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
                // Header
                teamHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
                    )

                // Search and filters
                searchAndFilters
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)

                // Everlens — the guests' side of photography
                if selectedCategory == .photography, EverlensPromo.isAvailable {
                    EverlensBanner(
                        surface: .vendors,
                        subtitle: "Your photographer gets the couple. Your guests get everything else."
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                if vendors.isEmpty {
                    // Empty state
                    EmptyTeamState {
                        addVendorTapped()
                    }
                    .padding(24)
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateIn)
                } else if filteredVendors.isEmpty {
                    // No results state
                    NoResultsState(searchText: searchText)
                        .padding(24)
                } else {
                    // Vendor grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(Array(filteredVendors.enumerated()), id: \.element.id) { index, vendor in
                                ProductionVendorCard(vendor: vendor) {
                                    selectedVendor = vendor
                                    selectionFeedback.selectionChanged()
                                }
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.05), value: animateIn)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .sheet(item: $selectedVendor) { vendor in
            ProductionVendorDetailView(vendor: vendor)
        }
        .sheet(isPresented: $showingAddVendor) {
            ProductionAddVendorView { newVendor in
                addVendor(newVendor)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(vendors: vendors)
        }
        .premiumUpsell($activeGate)
        .onAppear {
            withAnimation {
                animateIn = true
            }
            impactFeedback.prepare()
            selectionFeedback.prepare()
        }
    }

    // MARK: - Components

    private var teamHeader: some View {
        VStack(spacing: 16) {
            // Title and stats
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Dream Team")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(getMotivationalMessage())
                        .font(.system(size: 14, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Add vendor button
                Button(action: { addVendorTapped() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "D4B5A9"))
                }
            }

            // Free users see the ceiling before they hit it.
            if !dataManager.hasPremiumAccess {
                HStack {
                    FreeLimitPill(used: vendors.count, limit: DataManager.FreeLimit.vendors)
                    Spacer()
                }
            }

            // Progress overview
            if !vendors.isEmpty {
                HStack(spacing: 20) {
                    TeamStat(
                        value: "\(bookedCount)/\(totalVendors)",
                        label: "Booked",
                        color: Color(hex: "66BB6A")
                    )

                    TeamStat(
                        value: formatBudget(totalSpent),
                        label: "Paid",
                        color: Color(hex: "D4B5A9")
                    )

                    TeamStat(
                        value: "\(Int(totalSpent/max(totalBudget, 1) * 100))%",
                        label: "Progress",
                        color: Color(hex: "B89B91")
                    )
                }
                .padding(.top, 8)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
        .animation(.easeOut(duration: 0.6), value: animateIn)
    }

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "9B9B9B"))

                TextField("Search vendors...", text: $searchText)
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

            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterChip(
                        category: nil,
                        isSelected: selectedCategory == nil,
                        label: String(localized: "All")
                    ) {
                        selectedCategory = nil
                        selectionFeedback.selectionChanged()
                    }

                    ForEach(VendorCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                            selectionFeedback.selectionChanged()
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }

    // MARK: - Helper Methods

    /// Single entry point for "add a vendor" — the empty state and the header
    /// button both go through it, so the limit can only be enforced in one place.
    private func addVendorTapped() {
        if dataManager.canAddVendor() {
            showingAddVendor = true
            impactFeedback.impactOccurred()
        } else {
            activeGate = .vendorsLimit
        }
    }

    private func getMotivationalMessage() -> String {
        let messages = [
            String(localized: "Your dream team is ready"),
            String(localized: "Another piece of the puzzle, complete"),
            String(localized: "Vendors confirmed = one less thing to worry about"),
            String(localized: "Building your perfect day, one vendor at a time"),
            String(localized: "Your team is coming together beautifully")
        ]
        return messages.randomElement() ?? messages[0]
    }

    private func addVendor(_ vendor: Vendor) {
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

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error adding vendor: \(error)")
        }
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

// MARK: - Vendor Card Component
struct ProductionVendorCard: View {
    let vendor: Vendor
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and status
                HStack {
                    // Category icon
                    Image(systemName: vendor.category.icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color(hex: "D4B5A9"))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(hex: "D4B5A9").opacity(0.1))
                        )

                    Spacer()

                    // Status badge
                    ProductionStatusBadge(status: vendor.status)
                }

                // Vendor name
                Text(vendor.name)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .lineLimit(1)

                // Category
                Text(vendor.category.localizedName)
                    .font(.system(size: 12, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))

                // Payment progress
                if vendor.contractAmount > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(vendor.paymentStatus.localizedName)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(hex: vendor.paymentStatus.color))

                            Spacer()

                            Text(formatBudget(vendor.totalPaid))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "2C2C2C"))
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "E0E0E0"))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: vendor.paymentStatus.color))
                                    .frame(width: geometry.size.width * vendor.paymentProgress, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.top, 4)
                }

                // Contact buttons
                HStack(spacing: 12) {
                    if vendor.phone != nil {
                        ContactButton(icon: "phone", action: { callVendor(vendor) })
                    }

                    if vendor.email != nil {
                        ContactButton(icon: "envelope", action: { emailVendor(vendor) })
                    }

                    if vendor.phone != nil {
                        ContactButton(icon: "message", action: { messageVendor(vendor) })
                    }
                }
                .padding(.top, 4)
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

    private func callVendor(_ vendor: Vendor) {
        guard let phone = vendor.phone,
              let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") else { return }
        UIApplication.shared.open(url)
    }

    private func emailVendor(_ vendor: Vendor) {
        guard let email = vendor.email,
              let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }

    private func messageVendor(_ vendor: Vendor) {
        guard let phone = vendor.phone,
              let url = URL(string: "sms://\(phone.replacingOccurrences(of: " ", with: ""))") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Supporting Components

struct TeamStat: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Three stats share the row, so a longer translated label wraps to
            // a second line and scales down rather than truncating.
            Text(label)
                .font(.system(size: 11, weight: .thin))
                .foregroundColor(Color(hex: "9B9B9B"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
    }
}

struct ProductionStatusBadge: View {
    let status: VendorStatus

    var body: some View {
        Text(status.localizedName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: status.color))
            )
    }
}

struct ContactButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "B89B91"))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(hex: "B89B91").opacity(0.1))
                )
        }
    }
}

struct CategoryFilterChip: View {
    let category: VendorCategory?
    var isSelected: Bool
    /// Already-localized label. Callers pass `String(localized:)`; when it is
    /// nil the chip falls back to the category's catalog-resolved name.
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.system(size: 12, weight: .light))
                }

                Text(label ?? category?.localizedNameString ?? "")
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? .white : Color(hex: "7A7A7A"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "D4B5A9") : Color(hex: "F0F0F0"))
            )
        }
    }
}

struct EmptyTeamState: View {
    let onAddVendor: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4B5A9"))

            VStack(spacing: 8) {
                Text("No vendors yet")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("Start building your dream team")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            Button(action: onAddVendor) {
                Text("Add First Vendor")
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

struct NoResultsState: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color(hex: "C4C4C4"))

            Text("No vendors found")
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

