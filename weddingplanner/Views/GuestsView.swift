import SwiftUI

struct GuestsView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var showingAddGuest = false
    
    let filters = ["All", "Attending", "Pending", "Declined"]
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 16) {
                    RSVPSummaryCard()
                    
                    SearchBar(text: $searchText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterChip(
                                    title: filter,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        GuestGroupSection(
                            title: "Family",
                            guests: [
                                GuestItem(name: "John & Mary Smith", party: 2, status: .confirmed, table: "1"),
                                GuestItem(name: "Robert Johnson", party: 1, status: .pending, table: nil),
                                GuestItem(name: "The Williams Family", party: 4, status: .confirmed, table: "2")
                            ]
                        )
                        
                        GuestGroupSection(
                            title: "Friends",
                            guests: [
                                GuestItem(name: "Sarah Davis", party: 2, status: .confirmed, table: "3"),
                                GuestItem(name: "Mike & Lisa Brown", party: 2, status: .declined, table: nil),
                                GuestItem(name: "Emma Wilson", party: 1, status: .pending, table: nil)
                            ]
                        )
                        
                        GuestGroupSection(
                            title: "Work Colleagues",
                            guests: [
                                GuestItem(name: "The Anderson Team", party: 3, status: .confirmed, table: "4"),
                                GuestItem(name: "Jennifer Lee", party: 1, status: .pending, table: nil)
                            ]
                        )
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Guests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGuest = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
        }
    }
}

struct RSVPSummaryCard: View {
    var body: some View {
        HStack(spacing: 20) {
            RSVPStatView(number: 85, label: "Attending", color: .green)
            RSVPStatView(number: 23, label: "Pending", color: .orange)
            RSVPStatView(number: 12, label: "Declined", color: .red)
            RSVPStatView(number: 120, label: "Total", color: .pink)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

struct RSVPStatView: View {
    let number: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GuestGroupSection: View {
    let title: String
    let guests: [GuestItem]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    Text("(\(guests.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
            }
            
            if isExpanded {
                ForEach(guests) { guest in
                    GuestRow(guest: guest)
                    
                    if guest.id != guests.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
}

struct GuestItem: Identifiable {
    let id = UUID()
    let name: String
    let party: Int
    let status: RSVPStatusType
    let table: String?
}

enum RSVPStatusType {
    case confirmed, pending, declined
    
    var color: Color {
        switch self {
        case .confirmed: return .green
        case .pending: return .orange
        case .declined: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .confirmed: return "checkmark.circle.fill"
        case .pending: return "questionmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        }
    }
    
    var text: String {
        switch self {
        case .confirmed: return "Attending"
        case .pending: return "Pending"
        case .declined: return "Declined"
        }
    }
}

struct GuestRow: View {
    let guest: GuestItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: guest.status.icon)
                .font(.title3)
                .foregroundColor(guest.status.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Label("\(guest.party)", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let table = guest.table {
                        Label("Table \(table)", systemImage: "chair.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button("Send Message", action: {})
                Button("Edit Guest", action: {})
                Button("Change RSVP", action: {})
                Button("Remove", role: .destructive, action: {})
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

struct GuestsView_Previews: PreviewProvider {
    static var previews: some View {
        GuestsView()
    }
}