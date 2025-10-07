import SwiftUI

struct VendorsView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Booked", "Pending", "Contacted"]
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                ScrollView {
                    VStack(spacing: 16) {
                        VendorCard(
                            vendor: VendorItem(
                                name: "Enchanted Lens Photography",
                                category: "Photographer",
                                price: "$3,500",
                                rating: 4.9,
                                status: .booked,
                                image: "camera.fill"
                            )
                        )
                        
                        VendorCard(
                            vendor: VendorItem(
                                name: "The Grand Ballroom",
                                category: "Venue",
                                price: "$8,000",
                                rating: 4.8,
                                status: .booked,
                                image: "building.columns.fill"
                            )
                        )
                        
                        VendorCard(
                            vendor: VendorItem(
                                name: "Bloom & Blossom Florals",
                                category: "Florist",
                                price: "$2,200",
                                rating: 4.7,
                                status: .pending,
                                image: "leaf.fill"
                            )
                        )
                        
                        VendorCard(
                            vendor: VendorItem(
                                name: "Sweet Dreams Bakery",
                                category: "Cake",
                                price: "$800",
                                rating: 5.0,
                                status: .pending,
                                image: "birthday.cake.fill"
                            )
                        )
                        
                        VendorCard(
                            vendor: VendorItem(
                                name: "DJ Groovy",
                                category: "Music",
                                price: "$1,500",
                                rating: 4.6,
                                status: .pending,
                                image: "music.note"
                            )
                        )
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Vendors")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search vendors...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.pink : Color(.systemGray5))
                )
        }
    }
}

struct VendorItem {
    let id = UUID()
    let name: String
    let category: String
    let price: String
    let rating: Double
    let status: VendorStatus
    let image: String
}


struct VendorCard: View {
    let vendor: VendorItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: vendor.image)
                    .font(.title2)
                    .foregroundColor(.pink)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(vendor.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    StatusBadge(status: vendor.status)
                }
                
                Text(vendor.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(vendor.price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text(String(format: "%.1f", vendor.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
        .onTapGesture {
            
        }
    }
}

struct StatusBadge: View {
    let status: VendorStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: status.color))
            )
    }
}

struct VendorsView_Previews: PreviewProvider {
    static var previews: some View {
        VendorsView()
    }
}